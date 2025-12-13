import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationsService {
  ReminderNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'unigo_reminders';
  static const String _channelName = 'UniGO Reminders';
  static const String _channelDesc = 'Reminder notifications for UniGO';

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    tz.initializeTimeZones();
    // Force Amman timezone (prevents device/emulator timezone weirdness)
    tz.setLocalLocation(tz.getLocation('Asia/Amman'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Exact alarms permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    _inited = true;
  }

  /// Reminders are DATE-only in your app (stored as a date),
  /// so notification time is fixed at 7:00 AM.
  ///
  /// Schedules:
  /// 1) 1 day before @ 7:00 AM
  /// 2) same day @ 7:00 AM
  static Future<void> scheduleForReminder({
    required String reminderId, // Firestore doc id
    required String title, // Reminder title (what user typed)
    required DateTime reminderDate, // date-only
  }) async {
    await init();

    // 7:00 AM on reminder day
    final reminder7am = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      7,
      0,
    );

    final tzSameDay7am = tz.TZDateTime.from(reminder7am, tz.local);
    final tzDayBefore7am = tzSameDay7am.subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);

    final baseId = _stableId(reminderId);
    final idDayBefore = baseId;
    final idSameDay = baseId + 1;

    // Avoid duplicates if user re-saves/edits
    await cancelForReminder(reminderId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    if (kDebugMode) {
      debugPrint('[Notif] now=$now');
      debugPrint('[Notif] dayBefore=$tzDayBefore7am');
      debugPrint('[Notif] sameDay=$tzSameDay7am');
    }

    // 1) Day before @ 7AM
    if (tzDayBefore7am.isAfter(now)) {
      await _plugin.zonedSchedule(
        idDayBefore,
        'Tomorrow',
        title,
        tzDayBefore7am,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else if (kDebugMode) {
      debugPrint('[Notif] Skipped day-before (past)');
    }

    // 2) Same day @ 7AM
    if (tzSameDay7am.isAfter(now)) {
      await _plugin.zonedSchedule(
        idSameDay,
        'Today',
        title,
        tzSameDay7am,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else if (kDebugMode) {
      debugPrint('[Notif] Skipped same-day (past)');
    }

    if (kDebugMode) {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[Notif] Pending count = ${pending.length}');
      for (final p in pending) {
        debugPrint('[Notif] Pending id=${p.id} title=${p.title}');
      }
    }
  }

  static Future<void> cancelForReminder(String reminderId) async {
    await init();
    final baseId = _stableId(reminderId);
    await _plugin.cancel(baseId);
    await _plugin.cancel(baseId + 1);
  }

  static int _stableId(String s) {
    var hash = 0;
    for (final c in s.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return max(10000, hash.abs() % 2000000000);
  }
}
