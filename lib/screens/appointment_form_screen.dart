import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';
import '../widgets/custom_alert_dialog.dart';

class AppointmentFormScreen extends StatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  Patient? _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isEditing = false;
  late AgendaProvider provider;
  final Color deepPurple = const Color(0xFF4A148C);
  final Color pastelPurple = const Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<AgendaProvider>(context, listen: false);
      
      if (widget.appointmentId != null) {
        final appointment = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
        _isEditing = true;
        _selectedPatient = provider.getPatientById(appointment.patientId);
        _selectedDate = appointment.scheduledDate;
        _selectedTime = TimeOfDay.fromDateTime(appointment.scheduledDate);
        setState(() {});
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    if (_selectedPatient == null) {
      showCustomAlert(context, 'Faltan datos', 'Por favor selecciona un paciente', isError: true);
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validación de horario laboral
    if (finalDateTime.hour < 10) {
      showCustomAlert(context, 'Horario inválido', 'La hora de entrada es a las 10:00 AM.', isError: true);
      return;
    }
    if (finalDateTime.hour == 15) {
      showCustomAlert(context, 'Horario inválido', 'Horario de comida (3:00 PM a 4:00 PM).', isError: true);
      return;
    }
    if (finalDateTime.hour >= 17) {
      showCustomAlert(context, 'Horario inválido', 'El horario laboral termina a las 5:00 PM.', isError: true);
      return;
    }

    // Validación contra eventos profesionales (Inasistencias y Salidas)
    for (var event in provider.events) {
      if (event.type == 'Inasistencia') {
        // Checar si es el mismo día
        if (event.date.year == finalDateTime.year && event.date.month == finalDateTime.month && event.date.day == finalDateTime.day) {
          showCustomAlert(context, 'Día Inhábil', 'Día bloqueado por Inasistencia del Profesional.', isError: true);
          return;
        }
      } else if (event.type == 'Salida a campo') {
        // Checar empalme de 60 minutos con la salida a campo
        final diff = finalDateTime.difference(event.date).inMinutes.abs();
        if (diff < 60) {
          showCustomAlert(context, 'Choque de Horario', 'Atención: Este horario choca con una Salida a Campo (margen de 1 hora).', isError: true);
          return;
        }
      }
    }

    // Validación de empalme de citas (60 minutos de separación)
    for (var appt in provider.appointments) {
      if (_isEditing && appt.id == widget.appointmentId) continue;
      if (appt.status == 'No llegó') continue;

      final differenceMinutes = finalDateTime.difference(appt.scheduledDate).inMinutes.abs();
      if (differenceMinutes < 60) {
        showCustomAlert(
          context,
          'Empalme de Citas',
          'Ya tienes una cita agendada en un margen menor a 1 hora. Por favor, selecciona otro horario.',
          isError: true,
        );
        return; 
      }
    }

    if (_isEditing) {
      final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
      appt.patientId = _selectedPatient!.id;
      appt.scheduledDate = finalDateTime;
      provider.updateAppointment(appt);
    } else {
      final newAppt = Appointment(
        id: const Uuid().v4(),
        patientId: _selectedPatient!.id,
        scheduledDate: finalDateTime,
      );
      provider.addAppointment(newAppt);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<AgendaProvider>();
    final patients = provider.patients;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Allow liquid form parent to show
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Cita' : 'Nueva Cita', style: TextStyle(fontWeight: FontWeight.bold, color: deepPurple)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalles de la Cita', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: pastelPurple)),
                const SizedBox(height: 24),
                DropdownButtonFormField<Patient>(
                  decoration: const InputDecoration(labelText: 'Paciente'),
                  value: _selectedPatient,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down, color: pastelPurple),
                  items: patients.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: TextStyle(color: deepPurple)))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPatient = val);
                  },
                  hint: Text('Seleccionar paciente', style: TextStyle(color: deepPurple.withOpacity(0.5))),
                ),
                if (_selectedPatient != null && !_selectedPatient!.isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Advertencia: Este paciente está dado de baja definitiva por retardos recurrentes.',
                            style: TextStyle(color: deepPurple, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('Fecha de la Cita', style: TextStyle(color: deepPurple.withOpacity(0.7), fontSize: 13)),
                    subtitle: Text(DateFormat('EEEE d MMMM y', 'es_ES').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: deepPurple)),
                    trailing: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: pastelPurple.withOpacity(0.3), shape: BoxShape.circle),
                      child: Icon(Icons.calendar_today, color: pastelPurple),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('Hora de la Cita', style: TextStyle(color: deepPurple.withOpacity(0.7), fontSize: 13)),
                    subtitle: Text(_selectedTime.format(context), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: deepPurple)),
                    trailing: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: pastelPurple.withOpacity(0.3), shape: BoxShape.circle),
                      child: Icon(Icons.access_time, color: pastelPurple),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onTap: _pickTime,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Guardar Cita'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
