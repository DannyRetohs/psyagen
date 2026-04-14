import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../models/professional_event.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_background.dart';

class EventFormScreen extends StatefulWidget {
  final String? eventId;
  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  String _selectedType = 'Salida a campo';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _titleController = TextEditingController();
  final _activityController = TextEditingController();
  final _materialController = TextEditingController();

  bool _isEditing = false;
  late AgendaProvider provider;
  final Color deepPurple = const Color(0xFF4A148C);
  final Color pastelPurple = const Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<AgendaProvider>(context, listen: false);

      if (widget.eventId != null) {
        final ev = provider.events.firstWhere((e) => e.id == widget.eventId);
        _isEditing = true;
        _selectedType = ev.type;
        _selectedDate = ev.date;
        _selectedTime = TimeOfDay.fromDateTime(ev.date);
        _titleController.text = ev.title ?? '';
        _activityController.text = ev.activity ?? '';
        _materialController.text = ev.material ?? '';
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
    if (_selectedType == 'Inasistencia') return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    final finalDateTime = _selectedType == 'Inasistencia'
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);

    if (_isEditing) {
      final ev = provider.events.firstWhere((e) => e.id == widget.eventId);
      ev.type = _selectedType;
      ev.date = finalDateTime;
      ev.title = _selectedType == 'Salida a campo' ? _titleController.text : null;
      ev.activity = _selectedType == 'Salida a campo' ? _activityController.text : null;
      ev.material = _selectedType == 'Salida a campo' ? _materialController.text : null;
      provider.updateEvent(ev);
    } else {
      final newEv = ProfessionalEvent(
        id: const Uuid().v4(),
        type: _selectedType,
        date: finalDateTime,
        title: _selectedType == 'Salida a campo' ? _titleController.text : null,
        activity: _selectedType == 'Salida a campo' ? _activityController.text : null,
        material: _selectedType == 'Salida a campo' ? _materialController.text : null,
      );
      provider.addEvent(newEv);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<AgendaProvider>();

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Form has liquid background from Main or can wrap
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Evento' : 'Nuevo Evento', style: TextStyle(fontWeight: FontWeight.bold, color: deepPurple)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalles del Suceso', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: pastelPurple)),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo de Evento'),
                  value: _selectedType,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down, color: pastelPurple),
                  items: ['Salida a campo', 'Inasistencia'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: deepPurple)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('Fecha', style: TextStyle(color: deepPurple.withOpacity(0.7), fontSize: 13)),
                    subtitle: Text(DateFormat('EEEE d MMMM y', 'es_ES').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: deepPurple)),
                    trailing: Icon(Icons.calendar_today, color: pastelPurple),
                    onTap: _pickDate,
                  ),
                ),
                if (_selectedType == 'Salida a campo') ...[
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text('Hora de la Salida', style: TextStyle(color: deepPurple.withOpacity(0.7), fontSize: 13)),
                      subtitle: Text(_selectedTime.format(context), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: deepPurple)),
                      trailing: Icon(Icons.access_time, color: pastelPurple),
                      onTap: _pickTime,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: deepPurple),
                    decoration: const InputDecoration(labelText: 'Lugar / Título de la Salida'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _activityController,
                    maxLines: 2,
                    style: TextStyle(color: deepPurple),
                    decoration: const InputDecoration(labelText: 'Actividad que se realizó'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _materialController,
                    maxLines: 2,
                    style: TextStyle(color: deepPurple),
                    decoration: const InputDecoration(labelText: 'Material empleado / requerido'),
                  ),
                ],
                if (_selectedType == 'Inasistencia') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Al marcar inasistencia, este día completo quedará bloqueado en la agenda para registrar nuevas citas.',
                            style: TextStyle(color: deepPurple, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Guardar Evento'),
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
