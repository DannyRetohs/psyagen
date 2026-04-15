import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../models/patient_document.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';
import '../widgets/document_picker_widget.dart';
import 'patient_form_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final patient = provider.getPatientById(patientId);
    final Color darkTeal = const Color(0xFF1D3038);
    
    if (patient == null) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Detalle de Paciente')),
          body: Center(child: Text('El paciente no existe o fue eliminado.', style: TextStyle(color: darkTeal))),
        ),
      );
    }

    final allPatientAppts = provider.appointments.where((a) => a.patientId == patientId).toList();
    allPatientAppts.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate)); // Más recientes primero

    final totalAppts = allPatientAppts.length;
    final attended = allPatientAppts.where((a) => a.status.contains('Llegó')).length;
    final retards = allPatientAppts.where((a) => a.status == 'Llegó con retardo').length;
    final missed = allPatientAppts.where((a) => a.status == 'No llegó').length;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by outer/global or explicitly we can wrap if not wrapped
        appBar: AppBar(
          title: Text('Expediente', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: darkTeal),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientFormScreen(patientId: patientId)));
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: patient.isActive 
                      ? const Color(0xFF315A68).withOpacity(0.3)
                      : Colors.white.withOpacity(0.5),
                    child: Text(patient.name.substring(0, 1).toUpperCase(), 
                      style: TextStyle(
                        color: patient.isActive ? const Color(0xFF315A68) : darkTeal.withOpacity(0.5), 
                        fontWeight: FontWeight.bold, fontSize: 32)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(patient.name, 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: patient.isActive ? null : TextDecoration.lineThrough,
                      color: patient.isActive ? darkTeal : darkTeal.withOpacity(0.5)
                    )
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('${patient.age} años • ${patient.gender} • ${patient.generalReason}', 
                    style: TextStyle(color: darkTeal.withOpacity(0.7), fontSize: 16)
                  ),
                ),
                const SizedBox(height: 16),

                if (!patient.isActive)
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Paciente de Baja Definitiva', 
                                style: TextStyle(color: Colors.redAccent.shade100, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Este paciente se dio de baja automáticamente por haber acumulado 3 retardos.', style: TextStyle(color: darkTeal.withOpacity(0.7))),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.8), 
                            foregroundColor: Colors.white
                          ),
                          onPressed: () {
                            showDialog(
                              context: context, 
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                title: Text('¿Reactivar paciente?', style: TextStyle(color: darkTeal)),
                                content: Text('Esto volverá a activar al paciente, pero su historial de retardos permanecerá.', style: TextStyle(color: darkTeal.withOpacity(0.7))),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: darkTeal.withOpacity(0.5)))),
                                  TextButton(
                                    onPressed: () {
                                      provider.togglePatientStatus(patientId, true);
                                      Navigator.pop(ctx);
                                    }, 
                                    child: const Text('Sí, Reactivar', style: TextStyle(color: Color(0xFF315A68)))),
                                ],
                              )
                            );
                          },
                          child: const Text('Reactivar Paciente', style: TextStyle(fontWeight: FontWeight.bold))
                        )
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),

                Text('Estadísticas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard('Citas Totales', totalAppts.toString(), Colors.blueAccent, Icons.numbers, darkTeal)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Asistencias', attended.toString(), const Color(0xFF315A68), Icons.check, darkTeal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _statCard('Retardos', retards.toString(), Colors.orangeAccent, Icons.timer_outlined, darkTeal)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Faltas', missed.toString(), const Color(0xFFE8BD8A), Icons.close, darkTeal)),
                  ],
                ),
                
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: DocumentPickerWidget(
                    documents: List.from(patient.documents),
                    onChanged: (newDocs) {
                      patient.documents = newDocs;
                      provider.updatePatient(patient);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Text('Historial de Citas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
                const SizedBox(height: 12),

                if (allPatientAppts.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('El paciente no tiene citas registradas.', style: TextStyle(color: darkTeal.withOpacity(0.5))),
                  ))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allPatientAppts.length,
                    itemBuilder: (context, index) {
                      final appt = allPatientAppts[index];
                      final dateStr = DateFormat('dd MMM yyyy, h:mm a').format(appt.scheduledDate);
                      
                      Color statusColor;
                      switch (appt.status) {
                        case 'Llegó':
                          statusColor = const Color(0xFF315A68);
                          break;
                        case 'No llegó':
                          statusColor = const Color(0xFFE8BD8A);
                          break;
                        case 'Llegó con retardo':
                          statusColor = Colors.orangeAccent;
                          break;
                        case 'Programada':
                        default:
                          statusColor = Colors.black38;
                      }

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.zero,
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          iconColor: darkTeal,
                          collapsedIconColor: darkTeal.withOpacity(0.5),
                          leading: CircleAvatar(backgroundColor: statusColor, radius: 8),
                          title: Text(dateStr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: darkTeal)),
                          subtitle: Text(appt.status, style: TextStyle(color: darkTeal.withOpacity(0.7), fontSize: 13)),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Notas de la sesión:', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal.withOpacity(0.5))),
                                  const SizedBox(height: 4),
                                  Text(appt.notes.isEmpty ? 'Sin notas.' : appt.notes, style: TextStyle(color: darkTeal)),
                                  const SizedBox(height: 12),
                                  Text('Incidencias:', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal.withOpacity(0.5))),
                                  const SizedBox(height: 4),
                                  Text(appt.incidents.isEmpty ? 'Ninguna registrada.' : appt.incidents, style: TextStyle(color: darkTeal)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String count, Color color, IconData icon, Color textDeepPurple) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textDeepPurple)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: textDeepPurple.withOpacity(0.7), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
