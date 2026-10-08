import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/logic/fx.dart';
import 'package:subdate/logic/sub_list.dart';
import 'package:subdate/models/category.dart';
import 'package:subdate/models/subscription.dart';

Subscription sub(String name, double amount, DateTime start, {String cur = 'CAD', bool paused = false}) =>
    Subscription(
      id: name,
      name: name,
      amount: amount,
      currency: cur,
      cadence: Cadence.monthly,
      startDate: start,
      paused: paused,
    );

void main() {
  final now = DateTime(2026, 10, 3);
  final fx = FxRates(const {'EUR': 1, 'CAD': 1.5, 'USD': 1}, DateTime(2026));
  final subs = [
    sub('Zed', 5, DateTime(2026, 1, 20)),
    sub('alpha', 10, DateTime(2026, 1, 5)),
    sub('Mid', 9, DateTime(2026, 1, 10), cur: 'USD'),
    sub('Old', 50, DateTime(2026, 1, 4), paused: true),
  ];
  List<String> names(List<Subscription> l) => l.map((s) => s.name).toList();

  test('sorts by next renewal, paused last', () {
    expect(names(listSubs(subs, sort: SubSort.next, now: now, fx: fx, home: 'CAD')), ['alpha', 'Mid', 'Zed', 'Old']);
  });

  test('sorts by price in home currency', () {
    // Mid is 9 USD = 13.50 CAD
    expect(names(listSubs(subs, sort: SubSort.price, now: now, fx: fx, home: 'CAD')), ['Mid', 'alpha', 'Zed', 'Old']);
  });

  test('name sort ignores case, search + category filter', () {
    expect(names(listSubs(subs, sort: SubSort.name, now: now, fx: fx, home: 'CAD')), ['alpha', 'Mid', 'Zed', 'Old']);
    expect(names(listSubs(subs, sort: SubSort.name, now: now, fx: fx, home: 'CAD', query: 'ZE')), ['Zed']);
    expect(listSubs(subs, sort: SubSort.name, now: now, fx: fx, home: 'CAD', category: Category.music), isEmpty);
  });
}
