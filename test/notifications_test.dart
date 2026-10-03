import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/models/subscription.dart';
import 'package:subdate/services/notifications.dart';

Subscription sub(String name, DateTime start, {int remind = 1}) => Subscription(
      id: name,
      name: name,
      amount: 7.22,
      currency: 'CAD',
      cadence: Cadence.monthly,
      startDate: start,
      remindDaysBefore: remind,
    );

void main() {
  final now = DateTime(2026, 10, 2, 12);

  test('fires day before at the set hour, skips ones already passed', () {
    final plan = planReminders([sub('spotify', DateTime(2025, 1, 3))], now, 9);
    // oct 3 renewal -> oct 2 9am, already passed at noon so next one is nov
    expect(plan.first.fireAt, DateTime(2026, 11, 2, 9));
    expect(plan.first.renewal, DateTime(2026, 11, 3));
  });

  test('off means nothing', () {
    expect(planReminders([sub('x', DateTime(2025, 1, 5), remind: -1)], now, 9), isEmpty);
  });

  test('capped + sorted', () {
    final subs = [for (var i = 0; i < 40; i++) sub('s$i', DateTime(2025, 1, 1 + i % 28))];
    final plan = planReminders(subs, now, 9, max: 60);
    expect(plan.length, 60);
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
    }
  });

  test('text', () {
    final plan = planReminders([sub('Spotify', DateTime(2025, 1, 5), remind: 0)], now, 9);
    expect(reminderText(plan.first), 'Spotify renews today · CA\$7.22');
  });
}
