import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _plugin.initialize(initSettings);

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for scheduled study tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    return const NotificationDetails(android: android);
  }

  /// For quick testing: show notification immediately.
  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(notificationId, title, body, _details());
  }

  Future<void> scheduleTaskReminder({
    required int notificationId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    final tzTime = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzTime,
      _details(),
      // inexact is more reliable across OEMs; can change to exactAllowWhileIdle if you prefer
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);
}