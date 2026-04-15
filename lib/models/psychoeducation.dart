import 'package:uuid/uuid.dart';

class Psychoeducation {
  final String id;
  final String patientId;
  final String topic;
  final String description;
  final String material;
  final DateTime date;

  Psychoeducation({
    String? id,
    required this.patientId,
    required this.topic,
    required this.description,
    required this.material,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'topic': topic,
        'description': description,
        'material': material,
        'date': date.toIso8601String(),
      };

  factory Psychoeducation.fromJson(Map<String, dynamic> json) =>
      Psychoeducation(
        id: json['id'],
        patientId: json['patientId'] ?? '',
        topic: json['topic'] ?? '',
        description: json['description'] ?? '',
        material: json['material'] ?? '',
        date: DateTime.parse(json['date']),
      );
}
