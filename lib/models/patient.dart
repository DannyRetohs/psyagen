import 'patient_document.dart';

class Patient {
  final String id;
  String name;
  int age;
  String gender;
  String generalReason;
  bool isActive;
  List<PatientDocument> documents;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.generalReason,
    this.isActive = true,
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'generalReason': generalReason,
        'isActive': isActive,
        'documents': documents.map((d) => d.toJson()).toList(),
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'],
        name: json['name'],
        age: json['age'],
        gender: json['gender'],
        generalReason: json['generalReason'],
        isActive: json['isActive'] ?? true,
        documents: json['documents'] != null
            ? (json['documents'] as List).map((i) => PatientDocument.fromJson(i)).toList()
            : [],
      );
}
