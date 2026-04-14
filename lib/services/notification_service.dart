import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/appointment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // Iniciar configuración de Firebase Messaging
    await _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    try {
      // Obtener el token de FCM para este dispositivo
      String? token = await messaging.getToken();
      print('====== FCM TOKEN ======');
      print(token);
      print('========================');
    } catch (e) {
      print('Error obteniendo token FCM: $e');
    }

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');

      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title ?? 'Nueva Notificación',
      notification.body ?? '',
      _getNotificationDetails(),
    );
  }

  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'psicoagenda_reminders',
        'Recordatorios de Citas',
        channelDescription: 'Canal para recordatorios de citas y resúmenes',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  int _createUniqueId(String idStr) {
    return idStr.hashCode.abs();
  }

  Future<void> scheduleAppointmentReminder(
    Appointment appt,
    String patientName,
  ) async {
    final reminderTime = appt.scheduledDate.subtract(
      const Duration(minutes: 15),
    );
    if (reminderTime.isBefore(DateTime.now())) return; // Past

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    final id = _createUniqueId(appt.id);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Cita en 15 minutos',
      'Tu sesión con $patientName comenzará pronto.',
      scheduledDate,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAppointmentReminder(String apptId) async {
    await _flutterLocalNotificationsPlugin.cancel(_createUniqueId(apptId));
  }

  Future<void> syncDailySummaries(List<Appointment> appointments) async {
    for (int i = 0; i <= 30; i++) {
      await _flutterLocalNotificationsPlugin.cancel(cf_dailySummaryPrefix + i);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<DateTime, int> counts = {};
    for (var appt in appointments) {
      final apptDay = DateTime(
        appt.scheduledDate.year,
        appt.scheduledDate.month,
        appt.scheduledDate.day,
      );
      if (!apptDay.isBefore(today)) {
        counts[apptDay] = (counts[apptDay] ?? 0) + 1;
      }
    }

    int limit = 0;
    for (var entry in counts.entries) {
      if (limit >= 30) break;

      final day = entry.key;
      final count = entry.value;

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        8,
        0,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        continue;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        cf_dailySummaryPrefix + limit,
        'Agenda del Día',
        'Tienes $count cita(s) programada(s) para hoy.',
        scheduledDate,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      limit++;
    }
  }

  static const int cf_dailySummaryPrefix = 800000;
}
