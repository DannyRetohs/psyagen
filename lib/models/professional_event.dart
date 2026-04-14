class ProfessionalEvent {
  final String id;
  DateTime date;
  String type; // 'Salida a campo' o 'Inasistencia'
  String? title;
  String? activity;
  String? material;

  ProfessionalEvent({
    required this.id,
    required this.date,
    required this.type,
    this.title,
    this.activity,
    this.material,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type,
        'title': title,
        'activity': activity,
        'material': material,
      };

  factory ProfessionalEvent.fromJson(Map<String, dynamic> json) => ProfessionalEvent(
        id: json['id'],
        date: DateTime.parse(json['date']),
        type: json['type'],
        title: json['title'],
        activity: json['activity'],
        material: json['material'],
      );
}
