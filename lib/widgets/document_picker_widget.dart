import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/patient_document.dart';
import '../utils/image_helper.dart';
import 'glass_container.dart';

class DocumentPickerWidget extends StatefulWidget {
  final List<PatientDocument> documents;
  final ValueChanged<List<PatientDocument>> onChanged;

  const DocumentPickerWidget({
    super.key,
    required this.documents,
    required this.onChanged,
  });

  @override
  State<DocumentPickerWidget> createState() => _DocumentPickerWidgetState();
}

class _DocumentPickerWidgetState extends State<DocumentPickerWidget> {
  final Color deepPurple = const Color(0xFF4A148C);
  final Color pastelPurple = const Color(0xFFCE93D8);

  Future<void> _pickImage(ImageSource source) async {
    if (widget.documents.length >= 3) return;

    final path = await ImageHelper.pickAndSaveImage(source);
    if (path != null) {
      final newDoc = PatientDocument(path: path);
      final newList = List<PatientDocument>.from(widget.documents)..add(newDoc);
      widget.onChanged(newList);
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Añadir Documento', style: TextStyle(color: deepPurple, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: pastelPurple),
              title: Text('Tomar Foto', style: TextStyle(color: deepPurple)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: pastelPurple),
              title: Text('Elegir de Galería', style: TextStyle(color: deepPurple)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editDescription(int index) {
    final controller = TextEditingController(text: widget.documents[index].description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Descripción / Notas', style: TextStyle(color: deepPurple)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: deepPurple),
          decoration: InputDecoration(
            hintText: 'Ej. Receta médica, análisis...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final newList = List<PatientDocument>.from(widget.documents);
              newList[index].description = controller.text;
              widget.onChanged(newList);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _removeDocument(int index) {
    final newList = List<PatientDocument>.from(widget.documents)..removeAt(index);
    widget.onChanged(newList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Documentos (${widget.documents.length}/3)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: pastelPurple)),
            if (widget.documents.length < 3)
              IconButton(
                icon: Icon(Icons.add_a_photo, color: pastelPurple),
                onPressed: _showAddDialog,
              )
          ],
        ),
        const SizedBox(height: 12),
        if (widget.documents.isEmpty)
          Text('Sin documentos adjuntos', style: TextStyle(color: deepPurple.withOpacity(0.5))),
        if (widget.documents.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.documents.length,
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: Image.file(File(doc.path), fit: BoxFit.contain),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(doc.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60, height: 60, color: Colors.grey.withOpacity(0.3),
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Documento ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: deepPurple)),
                          Text(
                            doc.description.isEmpty ? 'Sin notas' : doc.description,
                            style: TextStyle(fontSize: 12, color: deepPurple.withOpacity(0.7)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                      onPressed: () => _editDescription(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeDocument(index),
                    ),
                  ],
                ),
              );
            },
          )
      ],
    );
  }
}
