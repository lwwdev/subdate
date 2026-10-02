import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/data/backup.dart';
import 'package:subdate/models/subscription.dart';

void main() {
  test('roundtrip', () {
    final subs = [
      Subscription(
        id: '1',
        name: 'Spotify',
        amount: 7.22,
        currency: 'CAD',
        cadence: Cadence.monthly,
        startDate: DateTime(2025, 3, 2),
        brandKey: 'spotify',
      ),
      Subscription(
        id: '2',
        name: 'Gym',
        amount: 40,
        currency: 'CAD',
        cadence: Cadence.weekly,
        every: 2,
        startDate: DateTime(2026, 1, 31),
        customImage: Uint8List.fromList([1, 2, 3]),
        remindDaysBefore: -1,
      ),
    ];
    final back = importBackup(exportBackup(subs));
    expect(back.length, 2);
    expect(back[0].name, 'Spotify');
    expect(back[0].startDate, DateTime(2025, 3, 2));
    expect(back[1].customImage, [1, 2, 3]);
    expect(back[1].every, 2);
    expect(back[1].remindDaysBefore, -1);
  });

  test('junk throws', () {
    expect(() => importBackup('{"hi": 1}'), throwsFormatException);
    expect(() => importBackup('lol'), throwsFormatException);
  });
}
