import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/agenda_provider.dart';
import '../models/patient.dart';
import '../models/patient_document.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';
import '../widgets/document_picker_widget.dart';

class PatientFormScreen extends StatefulWidget {
  final String? patientId;
  const PatientFormScreen({super.key, this.patientId});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customReasonController = TextEditingController();
  
  int _age = 5;
  String _gender = 'Femenino';
  String _reason = '';
  List<PatientDocument> _documents = [];
  
  bool _isEditing = false;
  late AgendaProvider provider;
  
  final Color darkTeal = const Color(0xFF1D3038);
  final Color sandPeach = const Color(0xFF315A68);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<AgendaProvider>(context, listen: false);
      if (_reason.isEmpty && provider.reasons.isNotEmpty) {
        setState(() {
          _reason = provider.reasons.first;
        });
      }
      
      if (widget.patientId != null) {
        final patient = provider.getPatientById(widget.patientId!);
        if (patient != null) {
          _isEditing = true;
          _nameController.text = patient.name;
          _age = patient.age;
          _gender = patient.gender;
          _documents = List.from(patient.documents);
          
          if (!provider.reasons.contains(patient.generalReason)) {
             provider.addReason(patient.generalReason);
          }
          setState(() {
            _reason = patient.generalReason;
          });
        }
      }
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_reason == 'Otro') {
        if (_customReasonController.text.isNotEmpty) {
          provider.addReason(_customReasonController.text);
          _reason = _customReasonController.text;
        }
      }

      if (_isEditing) {
        final p = provider.getPatientById(widget.patientId!);
        if (p != null) {
          p.name = _nameController.text;
          p.age = _age;
          p.gender = _gender;
          p.generalReason = _reason;
          p.documents = _documents;
          provider.updatePatient(p);
        }
      } else {
        final newPatient = Patient(
          id: const Uuid().v4(),
          name: _nameController.text,
          age: _age,
          gender: _gender,
          generalReason: _reason,
          documents: _documents,
        );
        provider.addPatient(newPatient);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<AgendaProvider>();
    List<int> ageList = List.generate(13, (i) => i + 5); // 5 to 17

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let liquid background show through if wrapped
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Paciente' : 'Nuevo Paciente', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos del Paciente', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: darkTeal),
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      labelStyle: TextStyle(color: darkTeal.withOpacity(0.5)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: _age,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: sandPeach),
                    decoration: InputDecoration(
                      labelText: 'Edad (5 - 17 años)',
                      labelStyle: TextStyle(color: darkTeal.withOpacity(0.5)),
                    ),
                    items: ageList.map((a) => DropdownMenuItem(value: a, child: Text('$a años', style: TextStyle(color: darkTeal)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _age = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: sandPeach),
                    decoration: InputDecoration(
                      labelText: 'Género',
                      labelStyle: TextStyle(color: darkTeal.withOpacity(0.5)),
                    ),
                    items: ['Masculino', 'Femenino'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: TextStyle(color: darkTeal)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _gender = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _reason.isEmpty ? null : _reason,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: sandPeach),
                    decoration: InputDecoration(
                      labelText: 'Motivo General de Consulta',
                      labelStyle: TextStyle(color: darkTeal.withOpacity(0.5)),
                    ),
                    items: provider.reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: darkTeal)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _reason = val);
                    },
                  ),
                  if (_reason == 'Otro') ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _customReasonController,
                      style: TextStyle(color: darkTeal),
                      decoration: InputDecoration(
                        labelText: 'Especificar Motivo',
                        labelStyle: TextStyle(color: darkTeal.withOpacity(0.5)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Documentos Clínicos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: sandPeach)),
                  const SizedBox(height: 12),
                  DocumentPickerWidget(
                    documents: _documents,
                    onChanged: (newDocs) {
                      setState(() => _documents = newDocs);
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Guardar Paciente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
