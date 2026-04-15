import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/agenda_provider.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/clinical_report.dart';
import '../widgets/custom_alert_dialog.dart';

class DocumentExporter {
  static Future<void> exportReportToWord(BuildContext context, Patient patient, Appointment appointment, ClinicalReport report) async {
    try {
      final provider = Provider.of<AgendaProvider>(context, listen: false);
      final String dateStr = DateFormat('dd \'de\' MMMM \'de\' yyyy, h:mm a', 'es_ES').format(appointment.scheduledDate);
      
      // Construir el HTML estricto para que Word lo interprete como MS Word Document
      final htmlContent = '''
<html xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<style>
  body { font-family: 'Arial', sans-serif; font-size: 11pt; line-height: 1.5; color: #000; }
  h1 { font-size: 16pt; text-align: center; color: #2C3E50; border-bottom: 2px solid #2C3E50; padding-bottom: 10px; margin-bottom: 20px;}
  h2 { font-size: 12pt; color: #34495E; margin-top: 20px; border-bottom: 1px solid #BDC3C7; padding-bottom: 5px;}
  .header-data { margin-bottom: 20px; }
  .header-data p { margin: 2px 0; }
  .field-title { font-weight: bold; color: #34495E; }
  .field-content { margin-left: 10px; margin-bottom: 10px; text-align: justify;}
</style>
</head>
<body>

<h1>REPORTE CLÍNICO PSICOLÓGICO</h1>

<div class="header-data">
  <p><span class="field-title">Fecha de Sesión:</span> $dateStr</p>
  <p><span class="field-title">Nombre del Paciente:</span> ${patient.name}</p>
  <p><span class="field-title">Edad del Paciente:</span> ${patient.age} años</p>
  <p><span class="field-title">Género:</span> ${patient.gender}</p>
  <p><span class="field-title">Tema / Motivo General:</span> ${provider.getReasonNameById(patient.generalReason)}</p>
  <p><span class="field-title">Psicólogo Tratante:</span> [Su Nombre / Firma Aquí]</p>
</div>

<h2>EVALUACIÓN INICIAL</h2>
<p class="field-title">Estado mental y apariencia general:</p>
<div class="field-content">${report.mentalState.isEmpty ? 'N/A' : report.mentalState}</div>

<p class="field-title">Área cognitiva:</p>
<div class="field-content">${report.cognitiveArea.isEmpty ? 'N/A' : report.cognitiveArea}</div>

<p class="field-title">Área emocional y conductual:</p>
<div class="field-content">${report.emotionalArea.isEmpty ? 'N/A' : report.emotionalArea}</div>

<p class="field-title">Antecedentes psiquiátricos:</p>
<div class="field-content">${report.psychiatric.isEmpty ? 'N/A' : report.psychiatric}</div>


<h2>DESARROLLO DE LA SESIÓN</h2>
<p class="field-title">Motivo de atención específico:</p>
<div class="field-content">${report.reason.isEmpty ? 'N/A' : report.reason}</div>

<p class="field-title">Objetivo de intervención:</p>
<div class="field-content">${report.goal.isEmpty ? 'N/A' : report.goal}</div>

<p class="field-title">Desarrollo de la sesión:</p>
<div class="field-content">${report.development.isEmpty ? 'N/A' : report.development}</div>

<p class="field-title">Avances y observaciones relevantes:</p>
<div class="field-content">${report.progress.isEmpty ? 'N/A' : report.progress}</div>

<p class="field-title">Incidencias:</p>
<div class="field-content">${report.incidents.isEmpty ? 'N/A' : report.incidents}</div>


<h2>PLAN Y PRONÓSTICO</h2>
<p class="field-title">Plan de intervención:</p>
<div class="field-content">${report.plan.isEmpty ? 'N/A' : report.plan}</div>

<p class="field-title">Pronóstico y número aproximado de sesiones:</p>
<div class="field-content">${report.prognosis.isEmpty ? 'N/A' : report.prognosis}</div>

<p class="field-title">Programación de citas:</p>
<div class="field-content">${report.scheduling.isEmpty ? 'N/A' : report.scheduling}</div>

<br><br><br>
<p style="text-align: center;">_______________________________________</p>
<p style="text-align: center;">Firma del Psicólogo Tratante</p>

</body>
</html>
      ''';

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      // Safe filename
      final safeName = patient.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final safeDate = DateFormat('dd_MMM').format(appointment.scheduledDate);
      final filePath = '${directory.path}/Reporte_${safeName}_$safeDate.doc';
      
      final file = File(filePath);
      await file.writeAsString(htmlContent);

      // Share
      final result = await Share.shareXFiles(
        [XFile(filePath)], 
        text: 'Reporte Clínico - ${patient.name}',
      );

      // Opcional: limpiar cache si result fue success (share_plus maneja esto a veces)

    } catch (e) {
      if (context.mounted) {
        showCustomAlert(context, 'Error de Exportación', 'Ha ocurrido un problema al exportar: $e', isError: true);
      }
    }
  }
}
