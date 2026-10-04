import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/data/csv.dart';
import 'package:subdate/logic/fx.dart';
import 'package:subdate/models/subscription.dart';

void main() {
  test('csv quotes commas and quotes, converts monthly', () {
    final fx = FxRates(const {'EUR': 1, 'CAD': 1.5, 'USD': 1}, DateTime(2026));
    final csv = exportCsv([
      Subscription(
        id: '1',
        name: 'Gym, "premium"',
        amount: 30,
        currency: 'USD',
        cadence: Cadence.monthly,
        startDate: DateTime(2026, 1, 10),
        people: 2,
      ),
    ], fx, 'CAD', DateTime(2026, 10, 4));
    final lines = csv.split('\n');
    expect(lines.first, startsWith('name,amount,currency'));
    expect(lines[1], '"Gym, ""premium""",30.00,USD,monthly,1,Other,2026-10-10,22.50,2,active,');
  });
}
