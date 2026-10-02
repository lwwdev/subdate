import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/logic/renewals.dart';
import 'package:subdate/models/subscription.dart';

Subscription sub(Cadence c, DateTime start, {int every = 1}) => Subscription(
      id: 'x',
      name: 'x',
      amount: 1,
      currency: 'CAD',
      cadence: c,
      every: every,
      startDate: start,
    );

void main() {
  test('monthly clamps to end of month but goes back to 31', () {
    final s = sub(Cadence.monthly, DateTime(2026, 1, 31));
    expect(occurrence(s, 1), DateTime(2026, 2, 28));
    expect(occurrence(s, 2), DateTime(2026, 3, 31));
    expect(occurrence(s, 3), DateTime(2026, 4, 30));
  });

  test('yearly on leap day', () {
    final s = sub(Cadence.yearly, DateTime(2024, 2, 29));
    expect(occurrence(s, 1), DateTime(2025, 2, 28));
    expect(occurrence(s, 4), DateTime(2028, 2, 29));
  });

  test('next renewal', () {
    final s = sub(Cadence.monthly, DateTime(2025, 3, 2));
    expect(nextRenewal(s, DateTime(2026, 10, 2)), DateTime(2026, 10, 2));
    expect(nextRenewal(s, DateTime(2026, 10, 3)), DateTime(2026, 11, 2));
    // before start
    expect(nextRenewal(s, DateTime(2020, 1, 1)), DateTime(2025, 3, 2));
  });

  test('weekly in range', () {
    final s = sub(Cadence.weekly, DateTime(2026, 9, 1), every: 2);
    final r = occurrencesInRange(s, DateTime(2026, 9, 1), DateTime(2026, 10, 31));
    expect(r, [
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 15),
      DateTime(2026, 9, 29),
      DateTime(2026, 10, 13),
      DateTime(2026, 10, 27),
    ]);
  });

  test('quarterly + old start date', () {
    final s = sub(Cadence.quarterly, DateTime(2010, 1, 15));
    final r = occurrencesInRange(s, DateTime(2026, 1, 1), DateTime(2026, 12, 31));
    expect(r.length, 4);
    expect(r.first, DateTime(2026, 1, 15));
  });

  test('relative labels', () {
    final now = DateTime(2026, 10, 2, 18);
    expect(relativeLabel(DateTime(2026, 10, 2), now), 'today');
    expect(relativeLabel(DateTime(2026, 10, 3), now), 'tomorrow');
    expect(relativeLabel(DateTime(2026, 10, 7), now), 'in 5 days');
  });

  test('calendar blanks', () {
    // oct 1 2026 is a thursday
    expect(leadingBlanks(DateTime(2026, 10), DateTime.monday), 3);
    expect(leadingBlanks(DateTime(2026, 10), DateTime.sunday), 4);
    // feb 1 2026 is a sunday
    expect(leadingBlanks(DateTime(2026, 2), DateTime.sunday), 0);
    expect(leadingBlanks(DateTime(2026, 2), DateTime.monday), 6);
  });
}
