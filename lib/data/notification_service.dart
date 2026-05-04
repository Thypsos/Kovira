import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/income_template.dart';
import '../models/transfer_template.dart';
import '../models/income_source.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'income_reminders';
  static const _channelName = 'Income Reminders';
  static const _channelDesc = 'Reminders to tap your income buttons';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  tz.TZDateTime _nextOccurrence(int day) {
    final now = tz.TZDateTime.now(tz.local);
    final lastDayThis = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = day > lastDayThis ? lastDayThis : day;

    var next = tz.TZDateTime(tz.local, now.year, now.month, clampedDay, 12, 0);
    if (!next.isAfter(now)) {
      final lastDayNext = DateTime(now.year, now.month + 2, 0).day;
      final clampedNext = day > lastDayNext ? lastDayNext : day;
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        clampedNext,
        12,
        0,
      );
    }
    return next;
  }

  tz.TZDateTime _fromDateTime(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }

  Future<void> scheduleIncomeReminder(IncomeTemplate t) async {
    if (t.id == null || t.reminderDay == null) return;
    await cancelIncomeReminder(t.id!);

    try {
      await _plugin.zonedSchedule(
        t.id!,
        '${t.icon} ${t.name}',
        'Time to record your income — tap to open Kovira',
        _nextOccurrence(t.reminderDay!),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      try {
        await _plugin.zonedSchedule(
          t.id!,
          '${t.icon} ${t.name}',
          'Time to record your income — tap to open Kovira',
          _nextOccurrence(t.reminderDay!),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
      } catch (e2) {
        // ignore: empty_catches
      }
    }
  }

  Future<void> snoozeReminder(IncomeTemplate t, int days) async {
    if (t.id == null) return;
    await cancelIncomeReminder(t.id!);
    final when = DateTime.now().add(Duration(days: days));
    final at12 = DateTime(when.year, when.month, when.day, 12, 0);
    try {
      await _plugin.zonedSchedule(
        t.id!,
        '${t.icon} ${t.name}',
        'Snoozed reminder — time to record your income',
        _fromDateTime(at12),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      try {
        await _plugin.zonedSchedule(
          t.id!,
          '${t.icon} ${t.name}',
          'Snoozed reminder — time to record your income',
          _fromDateTime(at12),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelIncomeReminder(int templateId) async {
    await _plugin.cancel(templateId);
  }

  static const int _transferIdOffset = 100000;

  int _transferNotifId(int transferTemplateId) =>
      _transferIdOffset + transferTemplateId;

  Future<void> scheduleTransferReminder(
    TransferTemplate t, {
    required IncomeSource fromSrc,
    required IncomeSource toSrc,
  }) async {
    if (t.id == null || t.reminderDay == null) return;
    final notifId = _transferNotifId(t.id!);
    await _plugin.cancel(notifId);
    final title =
        '${fromSrc.icon} → ${toSrc.icon} ${fromSrc.name} → ${toSrc.name}';
    const body = 'Time for your monthly transfer — tap to open Kovira';
    try {
      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        _nextOccurrence(t.reminderDay!),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      try {
        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          _nextOccurrence(t.reminderDay!),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelTransferReminder(int templateId) async {
    await _plugin.cancel(_transferNotifId(templateId));
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<String> fireTestNotification() async {
    try {
      await init();
      await requestPermission();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      await _plugin.show(
        99999,
        '🔔 Test notification',
        'If you see this, notifications are working. Tap to dismiss.',
        _details,
      );
      return 'Fired test notification.\nPermission granted: $granted';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> scheduledReminders() async {
    try {
      await init();
      final pending = await _plugin.pendingNotificationRequests();
      if (pending.isEmpty) return 'No reminders scheduled.';
      return pending
          .map((n) => 'ID ${n.id}: ${n.title} — ${n.body ?? ""}')
          .join('\n');
    } catch (e) {
      return 'Error: $e';
    }
  }
}
