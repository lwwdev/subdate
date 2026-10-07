import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/logic/fx.dart';
import 'package:subdate/logic/spending.dart';
import 'package:subdate/models/subscription.dart';

Subscription sub(String name, double amount, Cadence c, {int every = 1, String cur = 'CAD'}) => Subscription(
      id: name,
      name: name,
      amount: amount,
      currency: cur,
      cadence: c,
      every: every,
      startDate: DateTime(2026),
    );

void main() {
  test('monthly equivalents', () {
    expect(monthlyCost(sub('a', 12, Cadence.monthly)), 12);
    expect(monthlyCost(sub('a', 120, Cadence.yearly)), 10);
    expect(monthlyCost(sub('a', 30, Cadence.quarterly)), 10);
    expect(monthlyCost(sub('a', 12, Cadence.weekly)), closeTo(52, 1e-9));
    expect(monthlyCost(sub('a', 20, Cadence.monthly, every: 2)), 10);
  });

  test('breakdown converts + sorts', () {
    final fx = FxRates(const {'EUR': 1, 'USD': 1, 'CAD': 1.5}, DateTime(2026));
    final rows = spendBreakdown([
      sub('cheap', 5, Cadence.monthly),
      sub('usd', 20, Cadence.monthly, cur: 'USD'),
    ], fx, 'CAD');
    expect(rows.first.sub.name, 'usd');
    expect(rows.first.monthly, closeTo(30, 1e-9));
  });

  test('by category uses brand default unless overridden', () {
    final fx = FxRates(const {'EUR': 1, 'CAD': 1}, DateTime(2026));
    final rows = spendBreakdown([
      sub('a', 10, Cadence.monthly).copyWith(brandKey: 'spotify'),
      sub('b', 5, Cadence.monthly).copyWith(brandKey: 'tidal'),
      sub('c', 20, Cadence.monthly).copyWith(brandKey: 'spotify', category: 'gaming'),
      sub('d', 1, Cadence.monthly),
    ], fx, 'CAD');
    final cats = byCategory(rows);
    expect(cats.map((e) => e.key.name).toList(), ['gaming', 'music', 'other']);
    expect(cats[1].value, 15);
  });
}
