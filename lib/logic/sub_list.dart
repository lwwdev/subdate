import '../brand/brand_catalog.dart';
import '../models/category.dart';
import '../models/subscription.dart';
import 'fx.dart';
import 'renewals.dart';
import 'spending.dart';

enum SubSort {
  next('Next up'),
  price('Price'),
  name('Name');

  final String label;
  const SubSort(this.label);
}

/// filter + sort for the all subs list. paused ones always go last
List<Subscription> listSubs(
  List<Subscription> subs, {
  required SubSort sort,
  required DateTime now,
  required FxRates fx,
  required String home,
  String query = '',
  Category? category,
}) {
  final q = query.trim().toLowerCase();
  final out = [
    for (final s in subs)
      if ((q.isEmpty || s.name.toLowerCase().contains(q) || s.notes.toLowerCase().contains(q)) &&
          (category == null || categoryOf(s) == category))
        s,
  ];
  int by(Subscription a, Subscription b) => switch (sort) {
        SubSort.next => nextRenewal(a, now).compareTo(nextRenewal(b, now)),
        SubSort.price => fx
            .convert(monthlyCost(b), b.currency, home)
            .compareTo(fx.convert(monthlyCost(a), a.currency, home)),
        SubSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
  out.sort((a, b) {
    if (a.paused != b.paused) return a.paused ? 1 : -1;
    final c = by(a, b);
    return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return out;
}
