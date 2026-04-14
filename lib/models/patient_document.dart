class PatientDocument {
  final String path;
  String description;

  PatientDocument({
    required this.path,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'description': description,
      };

  factory PatientDocument.fromJson(Map<String, dynamic> json) => PatientDocument(
        path: json['path'],
        description: json['description'] ?? '',
      );
}
