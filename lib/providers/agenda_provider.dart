import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/professional_event.dart';
import '../models/psychoeducation.dart';
import '../models/consultation_reason.dart';
import '../services/notification_service.dart';

class AgendaProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? _userId;
  StreamSubscription<User?>? _authSubscription;
  final List<StreamSubscription> _dbSubscriptions = [];

  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<ProfessionalEvent> _events = [];
  List<Psychoeducation> _psychoeducations = [];
  List<ConsultationReason> _reasons = [];

  static const List<String> _defaultReasonNames = [
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
    'Psicoeducación',
    'Sin herramientas sociales',
    'TDH/TDAH',
    'Trastornos alimenticios',
    'Violencia física',
    'Violencia psicológica',
    'Otro'
  ];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Patient> get patients => _patients;
  List<Appointment> get appointments => _appointments;
  List<ProfessionalEvent> get events => _events;
  List<Psychoeducation> get psychoeducations => _psychoeducations;
  List<ConsultationReason> get reasons => _reasons;

  // RUTAS PRIVADAS (SCOPED POR USUARIO)
  CollectionReference get _patientsRef => _db.collection('users').doc(_userId).collection('patients');
  CollectionReference get _appointmentsRef => _db.collection('users').doc(_userId).collection('appointments');
  CollectionReference get _eventsRef => _db.collection('users').doc(_userId).collection('events');
  CollectionReference get _psychoRef => _db.collection('users').doc(_userId).collection('psychoeducations');
  
  // RUTA GLOBAL (COMPARTIDA POR TODOS LOS USUARIOS)
  CollectionReference get _reasonsRef => _db.collection('reasons');

  AgendaProvider() {
    _initAuth();
  }

  void _initAuth() {
    try {
      _db.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      print('Firestore settings already set: $e');
    }
    
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _isLoading = true;
        notifyListeners();
        
        _initListeners();
        _migrateDataIfNeeded();
      } else {
        _cleanUp();
      }
    });
  }

  void _cleanUp() {
    for (var sub in _dbSubscriptions) {
      sub.cancel();
    }
    _dbSubscriptions.clear();
    
    _userId = null;
    _patients.clear();
    _appointments.clear();
    _events.clear();
    _psychoeducations.clear();
    _reasons.clear();
    
    _isLoading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cleanUp();
    super.dispose();
  }

  Future<void> _migrateDataIfNeeded() async {
    if (_userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool('migrated_to_firestore_$_userId') ?? false;
    
    if (!isMigrated) {
      // Migrate Patients
      final patientsJson = prefs.getStringList('patients');
      if (patientsJson != null) {
        for (var pStr in patientsJson) {
          final patient = Patient.fromJson(jsonDecode(pStr));
          await _patientsRef.doc(patient.id).set(patient.toJson());
        }
      }

      // Migrate Appointments
      final appointmentsJson = prefs.getStringList('appointments');
      if (appointmentsJson != null) {
        for (var aStr in appointmentsJson) {
          final appointment = Appointment.fromJson(jsonDecode(aStr));
          await _appointmentsRef.doc(appointment.id).set(appointment.toJson());
        }
      }

      // Migrate Events
      final eventsJson = prefs.getStringList('events');
      if (eventsJson != null) {
        for (var eStr in eventsJson) {
          final event = ProfessionalEvent.fromJson(jsonDecode(eStr));
          await _eventsRef.doc(event.id).set(event.toJson());
        }
      }

      await prefs.setBool('migrated_to_firestore_$_userId', true);
    }
  }

  bool _isPopulatingReasons = false;

  void _initListeners() {
    if (_userId == null) return;

    // Limpiar suscripciones previas para evitar llamadas duplicadas si authState changes dispara doble
    for (var sub in _dbSubscriptions) {
      sub.cancel();
    }
    _dbSubscriptions.clear();

    _dbSubscriptions.add(
      _patientsRef.snapshots().listen((snapshot) {
        _patients = snapshot.docs.map((doc) => Patient.fromJson(doc.data() as Map<String, dynamic>)).toList();
        notifyListeners();
      })
    );

    _dbSubscriptions.add(
      _appointmentsRef.snapshots().listen((snapshot) {
        _appointments = snapshot.docs.map((doc) => Appointment.fromJson(doc.data() as Map<String, dynamic>)).toList();
        NotificationService().syncDailySummaries(_appointments);
        
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners();
      })
    );

    _dbSubscriptions.add(
      _eventsRef.snapshots().listen((snapshot) {
        _events = snapshot.docs.map((doc) => ProfessionalEvent.fromJson(doc.data() as Map<String, dynamic>)).toList();
        notifyListeners();
      })
    );

    _dbSubscriptions.add(
      _psychoRef.snapshots().listen((snapshot) {
        _psychoeducations = snapshot.docs.map((doc) => Psychoeducation.fromJson(doc.data() as Map<String, dynamic>)).toList();
        notifyListeners();
      })
    );

    _dbSubscriptions.add(
      _reasonsRef.snapshots().listen((snapshot) async {
        if (snapshot.docs.isEmpty) {
          if (_isPopulatingReasons) return;
          _isPopulatingReasons = true;
          // Inicializar por primera vez para este usuario
          for (var name in _defaultReasonNames) {
            final id = const Uuid().v4();
            await _reasonsRef.doc(id).set({'id': id, 'name': name});
          }
          _isPopulatingReasons = false;
        } else {
          _reasons = snapshot.docs.map((doc) => ConsultationReason.fromJson(doc.data() as Map<String, dynamic>)).toList()
            ..sort((a, b) => a.name == 'Otro' ? 1 : b.name == 'Otro' ? -1 : a.name.compareTo(b.name));
          notifyListeners();
        }
      })
    );
  }

  // Métodos de motivos
  Future<String?> addReason(String name) async {
    if (_userId == null) return null;
    
    // Evitar duplicados
    try {
      final existing = _reasons.firstWhere((r) => r.name.toLowerCase().trim() == name.toLowerCase().trim());
      return existing.id;
    } catch (_) {
      final r = ConsultationReason(id: const Uuid().v4(), name: name);
      await _reasonsRef.doc(r.id).set(r.toJson());
      return r.id;
    }
  }

  String getReasonNameById(String id) {
    try {
      return _reasons.firstWhere((r) => r.id == id).name;
    } catch (_) {
      return id; // Si no lo encuentra, asume que es legacy text
    }
  }

  // Métodos de pacientes
  Future<void> addPatient(Patient patient) async {
    if (_userId == null) return;
    await _patientsRef.doc(patient.id).set(patient.toJson());
  }

  Future<void> updatePatient(Patient updatedPatient) async {
    if (_userId == null) return;
    await _patientsRef.doc(updatedPatient.id).update(updatedPatient.toJson());
  }

  Future<void> togglePatientStatus(String patientId, bool isActive) async {
    if (_userId == null) return;
    await _patientsRef.doc(patientId).update({'isActive': isActive});
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkPatientStatus(String patientId) async {
    if (_userId == null) return;
    final QuerySnapshot snapshot = await _appointmentsRef.where('patientId', isEqualTo: patientId).get();
    
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
    if (_userId == null) return;
    await _appointmentsRef.doc(appointment.id).set(appointment.toJson());
    await _checkPatientStatus(appointment.patientId);
    
    final patient = getPatientById(appointment.patientId);
    if (patient != null) {
      NotificationService().scheduleAppointmentReminder(appointment, patient.name);
    }
  }

  Future<void> updateAppointment(Appointment updatedAppt) async {
    if (_userId == null) return;
    await _appointmentsRef.doc(updatedAppt.id).update(updatedAppt.toJson());
    await _checkPatientStatus(updatedAppt.patientId);
    
    NotificationService().cancelAppointmentReminder(updatedAppt.id);
    final patient = getPatientById(updatedAppt.patientId);
    if (patient != null) {
      NotificationService().scheduleAppointmentReminder(updatedAppt, patient.name);
    }
  }

  Future<void> deleteAppointment(String id) async {
    if (_userId == null) return;
    await _appointmentsRef.doc(id).delete();
    NotificationService().cancelAppointmentReminder(id);
  }

  // Métodos de eventos
  Future<void> addEvent(ProfessionalEvent event) async {
    if (_userId == null) return;
    await _eventsRef.doc(event.id).set(event.toJson());
  }

  Future<void> updateEvent(ProfessionalEvent updatedEvent) async {
    if (_userId == null) return;
    await _eventsRef.doc(updatedEvent.id).update(updatedEvent.toJson());
  }

  Future<void> deleteEvent(String id) async {
    if (_userId == null) return;
    await _eventsRef.doc(id).delete();
  }

  // Métodos de psicoeducación
  Future<void> addPsychoeducation(Psychoeducation session) async {
    if (_userId == null) return;
    await _psychoRef.doc(session.id).set(session.toJson());
  }

  Future<void> deletePsychoeducation(String id) async {
    if (_userId == null) return;
    await _psychoRef.doc(id).delete();
  }

  List<Psychoeducation> getPsychoeducationsByPatient(String patientId) {
    return _psychoeducations.where((s) => s.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
