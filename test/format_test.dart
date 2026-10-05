import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/format.dart';

void main() {
  test('money', () {
    expect(money(7.22, 'CAD'), 'CA\$7.22');
    expect(money(20, 'USD'), 'US\$20.00');
    expect(money(5, 'EUR'), '€5.00');
    // intl uses non-breaking spaces for sv
    expect(money(129, 'SEK').replaceAll('\u00A0', ' '), '129,00 kr');
    expect(money(1234.5, 'SEK').replaceAll('\u00A0', ' '), '1 234,50 kr');
  });

  test('dates', () {
    expect(dayPill(DateTime(2026, 10, 2)), 'Fri 2');
    expect(longDate(DateTime(2026, 10, 2)), 'Fri 2 Oct');
    expect(monthTitle(DateTime(2026, 10, 2)), 'October 2026');
  });
}
