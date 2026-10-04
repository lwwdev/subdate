import '../brand/brand_catalog.dart';
import '../logic/fx.dart';
import '../logic/renewals.dart';
import '../logic/spending.dart';
import '../models/subscription.dart';

String _cell(Object? v) {
  final s = v?.toString() ?? '';
  return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

String _day(DateTime? d) => d == null ? '' : d.toIso8601String().substring(0, 10);

/// for spreadsheets. monthly column is your share in the home currency
String exportCsv(List<Subscription> subs, FxRates fx, String home, DateTime now) {
  final rows = [
    ['name', 'amount', 'currency', 'cadence', 'every', 'category', 'next charge', 'monthly ($home)', 'split', 'status', 'notes'],
    for (final s in subs)
      [
        s.name,
        s.amount.toStringAsFixed(2),
        s.currency,
        s.cadence.name,
        s.every,
        categoryOf(s).label,
        s.paused ? '' : _day(nextCharge(s, now)),
        fx.convert(monthlyCost(s), s.currency, home).toStringAsFixed(2),
        s.people,
        s.paused ? 'paused' : s.endsOn != null ? 'cancelled' : s.inTrial(now) ? 'trial' : 'active',
        s.notes,
      ],
  ];
  return rows.map((r) => r.map(_cell).join(',')).join('\n');
}
