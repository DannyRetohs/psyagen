import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/professional_event.dart';
import '../services/notification_service.dart';

class AgendaProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<ProfessionalEvent> _events = [];
  List<String> _reasons = [
    'Abuso sexual',
    'Ansiedad',
    'Autolesiones',
    'Conductas de riesgo',
    'Consumo de sustancias',
    'Depresión leve',
    'Depresión moderada',
    'Duelo',
    'Gestión de emociones',
    'Intentos de suicidio',
    'Negativista desafiante',
    'Negligencia por parte de padres',
    'Problemas escolares',
    'Sin herramientas sociales',
    'TDH/TDAH',
    'Trastornos alimenticios',
    'Violencia física',
    'Violencia psicológica',
    'Otro'
  ];

  List<Patient> get patients => _patients;
  List<Appointment> get appointments => _appointments;
  List<ProfessionalEvent> get events => _events;
  List<String> get reasons => _reasons;

  AgendaProvider() {
    _init();
  }

  Future<void> _init() async {
    // Activa persistencia offline
    _db.settings = const Settings(persistenceEnabled: true);
    
    await _migrateDataIfNeeded();
    _initListeners();
  }

  Future<void> _migrateDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool('migrated_to_firestore') ?? false;
    
    if (!isMigrated) {
      // Migrate metadata/reasons
      final savedReasons = prefs.getStringList('reasons');
      List<String> combinedReasons = List.from(_reasons);
      if (savedReasons != null) {
        combinedReasons = {..._reasons, ...savedReasons}.toList();
      }
      await _db.collection('metadata').doc('reasons').set({'list': combinedReasons}, SetOptions(merge: true));

      // Migrate Patients
      final patientsJson = prefs.getStringList('patients');
      if (patientsJson != null) {
        for (var pStr in patientsJson) {
          final patient = Patient.fromJson(jsonDecode(pStr));
          await _db.collection('patients').doc(patient.id).set(patient.toJson());
        }
      }

      // Migrate Appointments
      final appointmentsJson = prefs.getStringList('appointments');
      if (appointmentsJson != null) {
        for (var aStr in appointmentsJson) {
          final appointment = Appointment.fromJson(jsonDecode(aStr));
          await _db.collection('appointments').doc(appointment.id).set(appointment.toJson());
        }
      }

      // Migrate Events
      final eventsJson = prefs.getStringList('events');
      if (eventsJson != null) {
        for (var eStr in eventsJson) {
          final event = ProfessionalEvent.fromJson(jsonDecode(eStr));
          await _db.collection('events').doc(event.id).set(event.toJson());
        }
      }

      await prefs.setBool('migrated_to_firestore', true);
    }
  }

  void _initListeners() {
    _db.collection('patients').snapshots().listen((snapshot) {
      _patients = snapshot.docs.map((doc) => Patient.fromJson(doc.data())).toList();
      notifyListeners();
    });

    _db.collection('appointments').snapshots().listen((snapshot) {
      _appointments = snapshot.docs.map((doc) => Appointment.fromJson(doc.data())).toList();
      NotificationService().syncDailySummaries(_appointments);
      notifyListeners();
    });

    _db.collection('events').snapshots().listen((snapshot) {
      _events = snapshot.docs.map((doc) => ProfessionalEvent.fromJson(doc.data())).toList();
      notifyListeners();
    });

    _db.collection('metadata').doc('reasons').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('list')) {
        final List<dynamic> list = snapshot.data()!['list'];
        _reasons = list.map((e) => e.toString()).toList();
      } else {
        // En caso de que no exista el doc aún o no tenga lista, inicializamos.
        _db.collection('metadata').doc('reasons').set({'list': _reasons}, SetOptions(merge: true));
      }
      notifyListeners();
    });
  }

  // Métodos de motivos
  Future<void> addReason(String reason) async {
    if (!_reasons.contains(reason)) {
      final updatedReasons = List<String>.from(_reasons)..add(reason);
      await _db.collection('metadata').doc('reasons').set({'list': updatedReasons}, SetOptions(merge: true));
    }
  }

  // Métodos de pacientes
  Future<void> addPatient(Patient patient) async {
    await _db.collection('patients').doc(patient.id).set(patient.toJson());
  }

  Future<void> updatePatient(Patient updatedPatient) async {
    await _db.collection('patients').doc(updatedPatient.id).update(updatedPatient.toJson());
  }

  Future<void> togglePatientStatus(String patientId, bool isActive) async {
    await _db.collection('patients').doc(patientId).update({'isActive': isActive});
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkPatientStatus(String patientId) async {
    final QuerySnapshot snapshot = await _db.collection('appointments').where('patientId', isEqualTo: patientId).get();
    
    int retardoCount = 0;
    int faltaCount = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'Llegó con retardo') retardoCount++;
      if (data['status'] == 'No llegó') faltaCount++;
    }
    
    if ((retardoCount + faltaCount) >= 3) {
      await togglePatientStatus(patientId, false);
    }
  }

  // Métodos de citas
  Future<void> addAppointment(Appointment appointment) async {
    await _db.collection('appointments').doc(appointment.id).set(appointment.toJson());
    await _checkPatientStatus(appointment.patientId);
    
    final patient = getPatientById(appointment.patientId);
    if (patient != null) {
      NotificationService().scheduleAppointmentReminder(appointment, patient.name);
    }
  }

  Future<void> updateAppointment(Appointment updatedAppt) async {
    await _db.collection('appointments').doc(updatedAppt.id).update(updatedAppt.toJson());
    await _checkPatientStatus(updatedAppt.patientId);
    
    NotificationService().cancelAppointmentReminder(updatedAppt.id);
    final patient = getPatientById(updatedAppt.patientId);
    if (patient != null) {
      NotificationService().scheduleAppointmentReminder(updatedAppt, patient.name);
    }
  }

  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
    NotificationService().cancelAppointmentReminder(id);
  }

  // Métodos de eventos
  Future<void> addEvent(ProfessionalEvent event) async {
    await _db.collection('events').doc(event.id).set(event.toJson());
  }

  Future<void> updateEvent(ProfessionalEvent updatedEvent) async {
    await _db.collection('events').doc(updatedEvent.id).update(updatedEvent.toJson());
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }
}
