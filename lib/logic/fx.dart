import 'dart:convert';

import 'package:http/http.dart' as http;

// EUR based. only used until the first fetch works
const fallbackRates = <String, double>{
  'EUR': 1,
  'USD': 1.1225,
  'CAD': 1.5984,
  'GBP': 0.85033,
  'AUD': 1.6176,
  'NZD': 2.0002,
  'JPY': 176.99,
  'CHF': 0.9279,
  'SEK': 11.29,
  'NOK': 10.8315,
  'DKK': 7.4736,
  'PLN': 4.3775,
  'CZK': 24.47,
  'INR': 108.1245,
  'CNY': 7.5259,
  'HKD': 8.8084,
  'SGD': 1.4366,
  'KRW': 1513.44,
  'MXN': 20.5806,
  'BRL': 5.861,
  'ZAR': 18.7839,
  'TRY': 55.165,
};

class FxRates {
  final Map<String, double> rates; // 1 EUR = rates[x]
  final DateTime fetchedAt;

  const FxRates(this.rates, this.fetchedAt);

  factory FxRates.fallback() => FxRates(fallbackRates, DateTime(2026, 10, 2));

  List<String> get currencies => rates.keys.toList()..sort();

  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final f = rates[from], t = rates[to];
    if (f == null || t == null) return amount; // meh, better than crashing
    return amount / f * t;
  }

  bool get stale => DateTime.now().difference(fetchedAt).inHours > 12;

  Map<String, dynamic> toMap() =>
      {'rates': rates, 'at': fetchedAt.millisecondsSinceEpoch};

  static FxRates? fromMap(Map? m) {
    if (m == null) return null;
    return FxRates(
      (m['rates'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
    );
  }

  static Future<FxRates?> fetch({http.Client? client}) async {
    try {
      final c = client ?? http.Client();
      final res = await c
          .get(Uri.parse('https://api.frankfurter.dev/v1/latest?base=EUR'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = (j['rates'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()));
      rates['EUR'] = 1;
      return FxRates(rates, DateTime.now());
    } catch (_) {
      return null;
    }
  }
}
