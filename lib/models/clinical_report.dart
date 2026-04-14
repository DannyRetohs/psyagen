class ClinicalReport {
  String mentalState;
  String cognitiveArea;
  String emotionalArea;
  String reason;
  String goal;
  String development;
  String progress;
  String incidents;
  String psychiatric;
  String plan;
  String prognosis;
  String scheduling;

  ClinicalReport({
    this.mentalState = '',
    this.cognitiveArea = '',
    this.emotionalArea = '',
    this.reason = '',
    this.goal = '',
    this.development = '',
    this.progress = '',
    this.incidents = '',
    this.psychiatric = '',
    this.plan = '',
    this.prognosis = '',
    this.scheduling = '',
  });

  Map<String, dynamic> toJson() => {
        'mentalState': mentalState,
        'cognitiveArea': cognitiveArea,
        'emotionalArea': emotionalArea,
        'reason': reason,
        'goal': goal,
        'development': development,
        'progress': progress,
        'incidents': incidents,
        'psychiatric': psychiatric,
        'plan': plan,
        'prognosis': prognosis,
        'scheduling': scheduling,
      };

  factory ClinicalReport.fromJson(Map<String, dynamic> json) => ClinicalReport(
        mentalState: json['mentalState'] ?? '',
        cognitiveArea: json['cognitiveArea'] ?? '',
        emotionalArea: json['emotionalArea'] ?? '',
        reason: json['reason'] ?? '',
        goal: json['goal'] ?? '',
        development: json['development'] ?? '',
        progress: json['progress'] ?? '',
        incidents: json['incidents'] ?? '',
        psychiatric: json['psychiatric'] ?? '',
        plan: json['plan'] ?? '',
        prognosis: json['prognosis'] ?? '',
        scheduling: json['scheduling'] ?? '',
      );
}
