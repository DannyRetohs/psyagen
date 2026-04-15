import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../models/psychoeducation.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';

class PsychoeducationFormScreen extends StatefulWidget {
  const PsychoeducationFormScreen({super.key});

  @override
  State<PsychoeducationFormScreen> createState() => _PsychoeducationFormScreenState();
}

class _PsychoeducationFormScreenState extends State<PsychoeducationFormScreen> {
  final Color darkTeal = const Color(0xFF1D3038);
  final Color teal = const Color(0xFF315A68);
  final Color sandPeach = const Color(0xFFE8BD8A);

  String? _selectedPatientId;
  DateTime _selectedDate = DateTime.now();

  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialController = TextEditingController();

  final List<String> _topicSuggestions = [
    'Técnicas de relajación',
    'Manejo de ansiedad',
    'Regulación emocional',
    'Comunicación asertiva',
    'Autoestima y autoconcepto',
    'Habilidades sociales',
    'Resolución de conflictos',
    'Higiene del sueño',
    'Psicoeducación familiar',
    'Otro',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save(AgendaProvider provider) {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un paciente')),
      );
      return;
    }
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe el tema de la sesión')),
      );
      return;
    }

    final session = Psychoeducation(
      patientId: _selectedPatientId!,
      topic: _topicController.text.trim(),
      description: _descriptionController.text.trim(),
      material: _materialController.text.trim(),
      date: _selectedDate,
    );

    provider.addPsychoeducation(session);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión de psicoeducación registrada ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final activePatients = provider.patients.where((p) => p.isActive).toList();

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Psicoeducación',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header destacado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sesión educativa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkTeal,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Registra el contenido psicoeducativo impartido al paciente',
                              style: TextStyle(color: darkTeal.withOpacity(0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Paciente
                Text('Paciente', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Seleccionar paciente'),
                  value: _selectedPatientId,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down, color: teal),
                  items: activePatients
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, style: TextStyle(color: darkTeal)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPatientId = val),
                ),

                const SizedBox(height: 20),

                // Fecha
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('Fecha de la sesión', style: TextStyle(color: darkTeal.withOpacity(0.7), fontSize: 13)),
                    subtitle: Text(
                      DateFormat('EEEE d MMMM y', 'es_ES').format(_selectedDate),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: darkTeal),
                    ),
                    trailing: Icon(Icons.calendar_today, color: sandPeach),
                    onTap: _pickDate,
                  ),
                ),

                const SizedBox(height: 20),

                // Tema con sugerencias
                Text('Tema', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _topicController,
                  style: TextStyle(color: darkTeal),
                  decoration: const InputDecoration(labelText: 'Tema de la sesión'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _topicSuggestions.map((topic) => GestureDetector(
                    onTap: () => setState(() => _topicController.text = topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _topicController.text == topic
                            ? teal
                            : teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _topicController.text == topic
                              ? teal
                              : teal.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 12,
                          color: _topicController.text == topic ? Colors.white : darkTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 20),

                // Descripción
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: darkTeal),
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Objetivos de la sesión',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Material
                TextField(
                  controller: _materialController,
                  maxLines: 2,
                  style: TextStyle(color: darkTeal),
                  decoration: const InputDecoration(
                    labelText: 'Material entregado / usado',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 40),

                // Botón guardar con durazno
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _save(provider),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Registrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: sandPeach, width: 2),
                    ),
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
