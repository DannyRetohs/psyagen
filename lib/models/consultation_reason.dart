class ConsultationReason {
  final String id;
  String name;

  ConsultationReason({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory ConsultationReason.fromJson(Map<String, dynamic> json) => ConsultationReason(
        id: json['id'],
        name: json['name'],
      );
}
