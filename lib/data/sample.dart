import 'package:uuid/uuid.dart';

import '../logic/renewals.dart';
import '../models/subscription.dart';

List<Subscription> sampleSubs(DateTime now) {
  final t = dateOnly(now);
  DateTime ago(int monthsBack, int dayOffset) =>
      DateTime(t.year, t.month - monthsBack, t.day + dayOffset);
  const uuid = Uuid();
  return [
    Subscription(id: uuid.v4(), name: 'Spotify', amount: 129, currency: 'SEK',
        cadence: Cadence.monthly, startDate: ago(14, 0), brandKey: 'spotify'),
    Subscription(id: uuid.v4(), name: 'Claude', amount: 20, currency: 'USD',
        cadence: Cadence.monthly, startDate: ago(5, -1), brandKey: 'claude'),
    Subscription(id: uuid.v4(), name: 'PlayStation Plus', amount: 139, currency: 'SEK',
        cadence: Cadence.monthly, startDate: ago(8, 4), brandKey: 'playstation'),
    Subscription(id: uuid.v4(), name: 'ChatGPT', amount: 20, currency: 'USD',
        cadence: Cadence.monthly, startDate: ago(3, 5), brandKey: 'chatgpt'),
    Subscription(id: uuid.v4(), name: 'Netflix', amount: 149, currency: 'SEK',
        cadence: Cadence.monthly, startDate: ago(20, 12), brandKey: 'netflix'),
    Subscription(id: uuid.v4(), name: 'iCloud+', amount: 12, currency: 'SEK',
        cadence: Cadence.monthly, startDate: ago(30, 19), brandKey: 'icloud'),
  ];
}
