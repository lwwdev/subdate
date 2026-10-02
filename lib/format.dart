import 'package:intl/intl.dart';

final _money = <String, NumberFormat>{};

// intl just says "$" for all of these which is useless when mixing currencies
const _dollars = {
  'CAD': 'CA\$',
  'USD': 'US\$',
  'AUD': 'A\$',
  'NZD': 'NZ\$',
  'HKD': 'HK\$',
  'SGD': 'S\$',
  'MXN': 'MX\$',
  'BRL': 'R\$',
};

String money(double v, String currency) {
  final f = _money.putIfAbsent(currency, () {
    final sym = _dollars[currency];
    return sym == null
        ? NumberFormat.simpleCurrency(name: currency, locale: 'en')
        : NumberFormat.currency(name: currency, symbol: sym, locale: 'en', decimalDigits: 2);
  });
  return f.format(v);
}

String dayPill(DateTime d) => DateFormat('EEE d').format(d); // Fri 2
String longDate(DateTime d) => DateFormat('EEE d MMM').format(d); // Fri 2 Oct
String monthTitle(DateTime d) => DateFormat('MMMM y').format(d);
