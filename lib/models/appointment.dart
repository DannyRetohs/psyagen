import 'clinical_report.dart';

class Appointment {
  final String id;
  String patientId;
  DateTime scheduledDate;
  String status;
  String notes;
  String incidents;
  ClinicalReport? report;

  Appointment({
    required this.id,
    required this.patientId,
    required this.scheduledDate,
    this.status = 'Programada',
    this.notes = '',
    this.incidents = '',
    this.report,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'scheduledDate': scheduledDate.toIso8601String(),
        'status': status,
        'notes': notes,
        'incidents': incidents,
        'report': report?.toJson(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        patientId: json['patientId'],
        scheduledDate: DateTime.parse(json['scheduledDate']),
        status: json['status'] ?? 'Programada',
        notes: json['notes'] ?? '',
        incidents: json['incidents'] ?? '',
        report: json['report'] != null ? ClinicalReport.fromJson(json['report']) : null,
      );
}
