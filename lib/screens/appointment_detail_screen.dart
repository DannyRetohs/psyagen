import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';
import '../utils/document_exporter.dart';
import 'appointment_form_screen.dart';
import 'session_report_screen.dart';
import '../widgets/custom_alert_dialog.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _notesController = TextEditingController();
  final _incidentsController = TextEditingController();
  final Color darkTeal = const Color(0xFF1D3038);
  final Color sandPeach = const Color(0xFF315A68);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AgendaProvider>(context, listen: false);
      final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
      _notesController.text = appt.notes;
      _incidentsController.text = appt.incidents;
    });
  }

  void _updateStatus(BuildContext context, String newStatus, AgendaProvider provider) {
    if (newStatus == 'Auto (Retardo)') {
      final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
      final now = DateTime.now();
      final difference = now.difference(appt.scheduledDate).inMinutes;
      
      if (difference > 15) {
        newStatus = 'Llegó con retardo';
      } else {
        newStatus = 'Llegó';
      }
      
      showCustomAlert(
        context,
        'Estatus Actualizado',
        'Status calculado: $newStatus ($difference minutos de diferencia)',
        isError: false,
      );
    }

    final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
    appt.status = newStatus;
    provider.updateAppointment(appt);
  }

  void _saveInformation(AgendaProvider provider) {
    final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
    appt.notes = _notesController.text;
    appt.incidents = _incidentsController.text;
    provider.updateAppointment(appt);
    showCustomAlert(context, 'Guardado', 'Información guardada correctamente.', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId, orElse: () => throw Exception('Cita no encontrada'));
    final patient = provider.getPatientById(appt.patientId);
    
    final dateTimeStr = DateFormat('EEEE d MMMM, h:mm a', 'es_ES').format(appt.scheduledDate);

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Detalle de Cita', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: darkTeal),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AppointmentFormScreen(appointmentId: appt.id)
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                 provider.deleteAppointment(appt.id);
                 Navigator.pop(context);
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sandPeach.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: sandPeach),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient?.name ?? 'Desconocido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
                              const SizedBox(height: 4),
                              Text('${patient?.age} años • ${patient?.gender}', style: TextStyle(color: darkTeal.withOpacity(0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, color: darkTeal.withOpacity(0.2)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.psychology, size: 20, color: sandPeach),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Motivo', style: TextStyle(fontSize: 12, color: darkTeal.withOpacity(0.5))),
                              Text(patient != null ? provider.getReasonNameById(patient.generalReason) : 'No especificado', style: TextStyle(fontWeight: FontWeight.w600, color: darkTeal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: sandPeach),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha y Hora', style: TextStyle(fontSize: 12, color: darkTeal.withOpacity(0.5))),
                              Text(dateTimeStr, style: TextStyle(fontWeight: FontWeight.w600, color: darkTeal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Estatus de la Consulta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: appt.status,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: sandPeach),
                    style: TextStyle(color: darkTeal, fontSize: 16, fontWeight: FontWeight.w500),
                    items: ['Programada', 'Llegó', 'No llegó', 'Llegó con retardo', 'Auto (Retardo)'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _updateStatus(context, val, provider);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Reporte Clínico Formal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appt.report != null ? const Color(0xFF315A68) : Colors.white.withOpacity(0.8),
                          foregroundColor: appt.report != null ? Colors.white : darkTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SessionReportScreen(appointmentId: appt.id)));
                        },
                        icon: Icon(appt.report != null ? Icons.edit_document : Icons.note_add),
                        label: Text(appt.report != null ? 'Ver / Editar Reporte' : 'Redactar Reporte Clínico', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    if (appt.report != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30)
                        ),
                        child: IconButton(
                          icon: Icon(Icons.share, color: sandPeach),
                          onPressed: () {
                            DocumentExporter.exportReportToWord(context, patient!, appt, appt.report!);
                          },
                        ),
                      )
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Notas Sensibles / Observaciones Adicionales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(color: darkTeal),
                decoration: InputDecoration(
                  hintText: 'Escribe las observaciones de la sesión aquí...',
                  hintStyle: TextStyle(color: darkTeal.withOpacity(0.4)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Incidencias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
              const SizedBox(height: 10),
              TextField(
                controller: _incidentsController,
                maxLines: 4,
                style: TextStyle(color: darkTeal),
                decoration: InputDecoration(
                  hintText: 'Anota si hubo alguna incidencia, emergencia o evento inusual...',
                  hintStyle: TextStyle(color: darkTeal.withOpacity(0.4)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _saveInformation(provider),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Información'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
