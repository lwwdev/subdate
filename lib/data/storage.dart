import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../logic/fx.dart';
import '../models/subscription.dart';

class Storage {
  late Box _subs;
  late Box _settings;

  Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path); // tests
    } else {
      await Hive.initFlutter('subdate');
    }
    _subs = await Hive.openBox('subs');
    _settings = await Hive.openBox('settings');
  }

  List<Subscription> loadSubs() {
    final out = <Subscription>[];
    for (final v in _subs.values) {
      try {
        out.add(Subscription.fromMap(v as Map));
      } catch (_) {
        // corrupted row, skip it
      }
    }
    return out;
  }

  Future<void> putSub(Subscription s) => _subs.put(s.id, s.toMap());
  Future<void> deleteSub(String id) => _subs.delete(id);

  T? get<T>(String key) => _settings.get(key) as T?;
  Future<void> set(String key, Object? value) => _settings.put(key, value);

  FxRates? loadFx() => FxRates.fromMap(_settings.get('fx') as Map?);
  Future<void> saveFx(FxRates r) => _settings.put('fx', r.toMap());
}
