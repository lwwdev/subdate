import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subdate/logic/fx.dart';

void main() {
  final fx = FxRates(const {'EUR': 1, 'USD': 1.1, 'CAD': 1.5}, DateTime(2026));

  test('convert', () {
    expect(fx.convert(10, 'CAD', 'CAD'), 10);
    expect(fx.convert(11, 'USD', 'EUR'), closeTo(10, 1e-9));
    expect(fx.convert(1.1, 'USD', 'CAD'), closeTo(1.5, 1e-9));
  });

  test('unknown currency just passes through', () {
    expect(fx.convert(5, 'XYZ', 'CAD'), 5);
  });

  test('roundtrip map', () {
    final back = FxRates.fromMap(fx.toMap())!;
    expect(back.rates, fx.rates);
  });

  test('fetch parses', () async {
    final client = MockClient((_) async => http.Response(
        '{"amount":1.0,"base":"EUR","date":"2026-10-02","rates":{"CAD":1.6}}', 200));
    final r = await FxRates.fetch(client: client);
    expect(r!.rates['CAD'], 1.6);
    expect(r.rates['EUR'], 1);
  });

  test('fetch fails gracefully', () async {
    final client = MockClient((_) async => http.Response('nope', 500));
    expect(await FxRates.fetch(client: client), isNull);
  });
}
