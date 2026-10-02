import '../models/subscription.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final y = d.year + (total ~/ 12);
  final m = total % 12 + 1;
  final day = d.day > _daysIn(y, m) ? _daysIn(y, m) : d.day;
  return DateTime(y, m, day);
}

// always compute from the start date so jan 31 -> feb 28 -> mar 31 (not mar 28)
DateTime occurrence(Subscription s, int n) {
  final start = dateOnly(s.startDate);
  return switch (s.cadence) {
    Cadence.weekly => DateTime(start.year, start.month, start.day + 7 * s.every * n),
    Cadence.monthly => _addMonths(start, s.every * n),
    Cadence.quarterly => _addMonths(start, 3 * s.every * n),
    Cadence.yearly => _addMonths(start, 12 * s.every * n),
  };
}

// rough guess at which n lands near `d` so we dont loop from 2015 every time
int _guessIndex(Subscription s, DateTime d) {
  final start = dateOnly(s.startDate);
  if (!d.isAfter(start)) return 0;
  final days = d.difference(start).inDays;
  final period = switch (s.cadence) {
    Cadence.weekly => 7 * s.every,
    Cadence.monthly => 28 * s.every,
    Cadence.quarterly => 89 * s.every,
    Cadence.yearly => 365 * s.every,
  };
  final n = days ~/ period - 2;
  return n < 0 ? 0 : n;
}

DateTime nextRenewal(Subscription s, DateTime from) {
  final f = dateOnly(from);
  var n = _guessIndex(s, f);
  while (true) {
    final d = occurrence(s, n);
    if (!d.isBefore(f)) return d;
    n++;
  }
}

/// all renewal dates between start and end, both inclusive
List<DateTime> occurrencesInRange(Subscription s, DateTime start, DateTime end) {
  final a = dateOnly(start), b = dateOnly(end);
  final out = <DateTime>[];
  var n = _guessIndex(s, a);
  while (true) {
    final d = occurrence(s, n);
    if (d.isAfter(b)) break;
    if (!d.isBefore(a)) out.add(d);
    n++;
  }
  return out;
}

String relativeLabel(DateTime d, DateTime now) {
  final diff = dateOnly(d).difference(dateOnly(now)).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff < 0) return '${-diff} days ago';
  return 'in $diff days';
}
