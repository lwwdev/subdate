import '../brand/brand_catalog.dart';
import '../models/category.dart';
import '../models/subscription.dart';
import 'fx.dart';

double monthlyCost(Subscription s) => switch (s.cadence) {
      Cadence.weekly => s.amount * 52 / 12 / s.every,
      Cadence.monthly => s.amount / s.every,
      Cadence.quarterly => s.amount / (3 * s.every),
      Cadence.yearly => s.amount / (12 * s.every),
    };

class SpendRow {
  final Subscription sub;
  final double monthly; // in home currency
  const SpendRow(this.sub, this.monthly);
}

List<SpendRow> spendBreakdown(List<Subscription> subs, FxRates fx, String home) {
  final rows = [
    for (final s in subs)
      if (!s.paused) SpendRow(s, fx.convert(monthlyCost(s), s.currency, home)),
  ];
  rows.sort((a, b) => b.monthly.compareTo(a.monthly));
  return rows;
}

/// monthly totals per category, biggest first
List<MapEntry<Category, double>> byCategory(List<SpendRow> rows) {
  final m = <Category, double>{};
  for (final r in rows) {
    final c = categoryOf(r.sub);
    m[c] = (m[c] ?? 0) + r.monthly;
  }
  return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}
