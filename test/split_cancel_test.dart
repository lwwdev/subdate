import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/data/backup.dart';
import 'package:subdate/logic/fx.dart';
import 'package:subdate/logic/renewals.dart';
import 'package:subdate/logic/spending.dart';
import 'package:subdate/models/subscription.dart';

Subscription sub({int people = 1, DateTime? endsOn}) => Subscription(
      id: 'x',
      name: 'Family plan',
      amount: 24,
      currency: 'CAD',
      cadence: Cadence.monthly,
      startDate: DateTime(2026, 1, 10),
      people: people,
      endsOn: endsOn,
    );

void main() {
  final fx = FxRates(const {'EUR': 1, 'CAD': 1}, DateTime(2026));

  test('split only counts your share', () {
    final s = sub(people: 3);
    expect(s.share, 8);
    expect(monthlyCost(s), 8);
  });

  test('no renewals after the end date', () {
    final s = sub(endsOn: DateTime(2026, 11, 15));
    expect(occurrencesInRange(s, DateTime(2026, 10, 1), DateTime(2027, 2, 1)),
        [DateTime(2026, 10, 10), DateTime(2026, 11, 10)]);
    expect(nextCharge(s, DateTime(2026, 11, 1)), DateTime(2026, 11, 10));
    expect(nextCharge(s, DateTime(2026, 11, 11)), isNull);
    expect(s.endedBy(DateTime(2026, 11, 16)), isTrue);
    expect(s.endedBy(DateTime(2026, 11, 15)), isFalse);
  });

  test('cancelled ones drop out of spending', () {
    final rows = spendBreakdown([sub(), sub(endsOn: DateTime(2026, 12, 1))], fx, 'CAD');
    expect(rows.length, 1);
  });

  test('backup keeps split + end date', () {
    final back = importBackup(exportBackup([sub(people: 2, endsOn: DateTime(2026, 12, 1))])).single;
    expect(back.people, 2);
    expect(back.endsOn, DateTime(2026, 12, 1));
    expect(importBackup(exportBackup([sub()])).single.endsOn, isNull);
  });
}
