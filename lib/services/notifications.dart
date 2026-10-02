import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../format.dart';
import '../logic/renewals.dart';
import '../models/subscription.dart';

class Reminder {
  final Subscription sub;
  final DateTime renewal;
  final DateTime fireAt;
  const Reminder(this.sub, this.renewal, this.fireAt);
}

// pure so it can be tested. ios caps pending notifications at 64 so keep it under that
List<Reminder> planReminders(List<Subscription> subs, DateTime now, int hour, {int max = 60}) {
  final out = <Reminder>[];
  final horizon = now.add(const Duration(days: 120));
  for (final s in subs) {
    if (s.remindDaysBefore < 0) continue;
    for (final d in occurrencesInRange(s, now, horizon.add(Duration(days: s.remindDaysBefore)))) {
      final fire = DateTime(d.year, d.month, d.day - s.remindDaysBefore, hour);
      if (fire.isAfter(now) && fire.isBefore(horizon)) out.add(Reminder(s, d, fire));
    }
  }
  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out.take(max).toList();
}

String reminderText(Reminder r) {
  final days = dateOnly(r.renewal).difference(dateOnly(r.fireAt)).inDays;
  final when = switch (days) { 0 => 'today', 1 => 'tomorrow', _ => 'in $days days' };
  return '${r.sub.name} renews $when · ${money(r.sub.amount, r.sub.currency)}';
}

class Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get supported => !kIsWeb;

  Future<void> init() async {
    if (!supported) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // falls back to UTC, reminders might be off by a few hours but whatever
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
  }

  Future<void> sync(List<Subscription> subs, int hour) async {
    if (!_ready) return;
    final plan = planReminders(subs, DateTime.now(), hour);
    if (plan.isNotEmpty) await requestPermission();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'renewals',
        'Renewals',
        channelDescription: 'heads up before a subscription renews',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (var i = 0; i < plan.length; i++) {
      final r = plan[i];
      try {
        await _plugin.zonedSchedule(
          id: i,
          title: 'subdate',
          body: reminderText(r),
          scheduledDate: tz.TZDateTime.from(r.fireAt, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('schedule failed: $e');
      }
    }
  }
}
