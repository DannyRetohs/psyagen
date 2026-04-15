import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agenda_provider.dart';
import '../models/clinical_report.dart';
import '../models/clinical_report.dart';
import '../utils/document_exporter.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';
import '../widgets/custom_alert_dialog.dart';

class SessionReportScreen extends StatefulWidget {
  final String appointmentId;
  const SessionReportScreen({super.key, required this.appointmentId});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  final Color darkTeal = const Color(0xFF1D3038);
  final Color sandPeach = const Color(0xFF315A68);

  final _mentalStateCtrl = TextEditingController();
  final _cognitiveAreaCtrl = TextEditingController();
  final _emotionalAreaCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _developmentCtrl = TextEditingController();
  final _progressCtrl = TextEditingController();
  final _incidentsCtrl = TextEditingController();
  final _psychiatricCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _prognosisCtrl = TextEditingController();
  final _schedulingCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AgendaProvider>(context, listen: false);
      final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
      
      if (appt.report != null) {
        _mentalStateCtrl.text = appt.report!.mentalState;
        _cognitiveAreaCtrl.text = appt.report!.cognitiveArea;
        _emotionalAreaCtrl.text = appt.report!.emotionalArea;
        _reasonCtrl.text = appt.report!.reason;
        _goalCtrl.text = appt.report!.goal;
        _developmentCtrl.text = appt.report!.development;
        _progressCtrl.text = appt.report!.progress;
        _incidentsCtrl.text = appt.report!.incidents;
        _psychiatricCtrl.text = appt.report!.psychiatric;
        _planCtrl.text = appt.report!.plan;
        _prognosisCtrl.text = appt.report!.prognosis;
        _schedulingCtrl.text = appt.report!.scheduling;
      }
    });
  }

  void _saveReport() {
    final provider = Provider.of<AgendaProvider>(context, listen: false);
    final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);

    final report = ClinicalReport(
      mentalState: _mentalStateCtrl.text,
      cognitiveArea: _cognitiveAreaCtrl.text,
      emotionalArea: _emotionalAreaCtrl.text,
      reason: _reasonCtrl.text,
      goal: _goalCtrl.text,
      development: _developmentCtrl.text,
      progress: _progressCtrl.text,
      incidents: _incidentsCtrl.text,
      psychiatric: _psychiatricCtrl.text,
      plan: _planCtrl.text,
      prognosis: _prognosisCtrl.text,
      scheduling: _schedulingCtrl.text,
    );

    appt.report = report;
    provider.updateAppointment(appt);

    showCustomAlert(context, 'Guardado', 'Reporte Clínico Guardado Exitosamente', isError: false);
    Navigator.pop(context);
  }

  void _exportReport() {
    final provider = Provider.of<AgendaProvider>(context, listen: false);
    final appt = provider.appointments.firstWhere((a) => a.id == widget.appointmentId);
    final patient = provider.getPatientById(appt.patientId);
    
    if (patient == null) return;

    final report = ClinicalReport(
      mentalState: _mentalStateCtrl.text,
      cognitiveArea: _cognitiveAreaCtrl.text,
      emotionalArea: _emotionalAreaCtrl.text,
      reason: _reasonCtrl.text,
      goal: _goalCtrl.text,
      development: _developmentCtrl.text,
      progress: _progressCtrl.text,
      incidents: _incidentsCtrl.text,
      psychiatric: _psychiatricCtrl.text,
      plan: _planCtrl.text,
      prognosis: _prognosisCtrl.text,
      scheduling: _schedulingCtrl.text,
    );

    DocumentExporter.exportReportToWord(context, patient, appt, report);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 3,
          style: TextStyle(color: darkTeal),
          decoration: InputDecoration(
            hintText: 'Escribe aquí...',
            hintStyle: TextStyle(color: darkTeal.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Reporte de Sesión', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
          actions: [
            IconButton(
              icon: Icon(Icons.check, color: darkTeal),
              onPressed: _saveReport,
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evaluación Inicial', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
                    const SizedBox(height: 16),
                    _buildTextField('Estado mental y apariencia general:', _mentalStateCtrl),
                    _buildTextField('Área cognitiva:', _cognitiveAreaCtrl),
                    _buildTextField('Área emocional y conductual:', _emotionalAreaCtrl),
                    _buildTextField('Antecedentes psiquiátricos:', _psychiatricCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Desarrollo de la Sesión', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
                    const SizedBox(height: 16),
                    _buildTextField('Motivo de atención:', _reasonCtrl),
                    _buildTextField('Objetivo de intervención:', _goalCtrl),
                    _buildTextField('Desarrollo de la sesión:', _developmentCtrl),
                    _buildTextField('Avances y observaciones relevantes:', _progressCtrl),
                    _buildTextField('Incidencias:', _incidentsCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan y Pronóstico', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
                    const SizedBox(height: 16),
                    _buildTextField('Plan de intervención:', _planCtrl),
                    _buildTextField('Pronóstico y número aproximado de sesiones:', _prognosisCtrl),
                    _buildTextField('Programación de citas:', _schedulingCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveReport,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Reporte Clínico'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: darkTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    _saveReport(); // Auto-save antes de exportar
                    _exportReport();
                  },
                  icon: Icon(Icons.share, color: sandPeach),
                  label: const Text('Guardar y Exportar a Word', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
