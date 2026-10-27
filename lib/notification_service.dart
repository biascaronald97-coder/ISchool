import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'schedule_class.dart';

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw StateError('The notification service could not be initialized.');
    }
    _initialized = true;
  }

  Future<bool> syncSchedule(List<ScheduleClass> classes) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    await _initialize();
    await _plugin.cancelAll();
    final classesWithReminders = classes
        .where((item) => item.reminderMinutes > 0)
        .toList();
    if (classesWithReminders.isEmpty) return true;

    final permissionGranted = await _requestPermission();
    if (!permissionGranted) return false;

    for (var index = 0; index < classesWithReminders.length; index++) {
      final item = classesWithReminders[index];
      final scheduledDate = _nextReminderTime(item);
      await _plugin.zonedSchedule(
        id: index + 1,
        title: 'Class coming up',
        body:
            '${item.name} starts in ${item.reminderMinutes} minutes'
            '${item.location.isEmpty ? '' : ' · ${item.location}'}',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'class_schedule_reminders',
            'Class reminders',
            channelDescription: 'Reminders before your scheduled classes.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    return true;
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final permission = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return permission ?? true;
    }
    final permission = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return permission ?? true;
  }

  timezone.TZDateTime _nextReminderTime(ScheduleClass item) {
    final now = timezone.TZDateTime.now(timezone.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilClass = (item.weekday - now.weekday + 7) % 7;
    var classDate = today.add(Duration(days: daysUntilClass));
    var classStart = timezone.TZDateTime(
      timezone.local,
      classDate.year,
      classDate.month,
      classDate.day,
      item.startMinutes ~/ 60,
      item.startMinutes % 60,
    );
    var reminderTime = classStart.subtract(
      Duration(minutes: item.reminderMinutes),
    );
    if (!reminderTime.isAfter(now)) {
      classDate = classDate.add(const Duration(days: 7));
      classStart = timezone.TZDateTime(
        timezone.local,
        classDate.year,
        classDate.month,
        classDate.day,
        item.startMinutes ~/ 60,
        item.startMinutes % 60,
      );
      reminderTime = classStart.subtract(
        Duration(minutes: item.reminderMinutes),
      );
    }
    return reminderTime;
  }
}
