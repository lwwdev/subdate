import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/fx.dart';
import '../logic/renewals.dart';
import '../models/subscription.dart';
import '../services/notifications.dart';
import 'storage.dart';

final storageProvider = Provider<Storage>((ref) => throw UnimplementedError('override me'));
final notificationsProvider = Provider<Notifications>((ref) => Notifications());

// bumped when the app resumes so "today" doesnt get stuck overnight
class NowNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void tick() => state = DateTime.now();
}

final nowProvider = NotifierProvider<NowNotifier, DateTime>(NowNotifier.new);

class SubsNotifier extends Notifier<List<Subscription>> {
  @override
  List<Subscription> build() => ref.read(storageProvider).loadSubs();

  Future<void> save(Subscription s) async {
    await ref.read(storageProvider).putSub(s);
    state = [
      for (final x in state)
        if (x.id != s.id) x,
      s,
    ];
  }

  Future<void> remove(String id) async {
    await ref.read(storageProvider).deleteSub(id);
    state = state.where((s) => s.id != id).toList();
  }
}

final subsProvider = NotifierProvider<SubsNotifier, List<Subscription>>(SubsNotifier.new);

class Settings {
  final String homeCurrency;
  final int defaultRemind;
  final int notifyHour;
  final int upcomingDays;

  const Settings({this.homeCurrency = 'CAD', this.defaultRemind = 1, this.notifyHour = 9, this.upcomingDays = 7});

  Settings copyWith({String? homeCurrency, int? defaultRemind, int? notifyHour, int? upcomingDays}) => Settings(
        homeCurrency: homeCurrency ?? this.homeCurrency,
        defaultRemind: defaultRemind ?? this.defaultRemind,
        notifyHour: notifyHour ?? this.notifyHour,
        upcomingDays: upcomingDays ?? this.upcomingDays,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final st = ref.read(storageProvider);
    return Settings(
      homeCurrency: st.get<String>('home') ?? 'CAD',
      defaultRemind: st.get<int>('remind') ?? 1,
      notifyHour: st.get<int>('hour') ?? 9,
      upcomingDays: st.get<int>('days') ?? 7,
    );
  }

  Future<void> update(Settings s) async {
    final st = ref.read(storageProvider);
    await st.set('home', s.homeCurrency);
    await st.set('remind', s.defaultRemind);
    await st.set('hour', s.notifyHour);
    await st.set('days', s.upcomingDays);
    state = s;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class FxNotifier extends Notifier<FxRates> {
  @override
  FxRates build() {
    final cached = ref.read(storageProvider).loadFx();
    final r = cached ?? FxRates.fallback();
    if (r.stale) Future.microtask(refresh);
    return r;
  }

  Future<void> refresh() async {
    final r = await FxRates.fetch();
    if (r == null) return;
    await ref.read(storageProvider).saveFx(r);
    state = r;
  }
}

final fxProvider = NotifierProvider<FxNotifier, FxRates>(FxNotifier.new);

class Upcoming {
  final Subscription sub;
  final DateTime date;
  const Upcoming(this.sub, this.date);
}

final upcomingProvider = Provider<List<Upcoming>>((ref) {
  final now = dateOnly(ref.watch(nowProvider));
  final days = ref.watch(settingsProvider.select((s) => s.upcomingDays));
  final end = DateTime(now.year, now.month, now.day + days - 1);
  final out = <Upcoming>[
    for (final s in ref.watch(subsProvider))
      if (!s.paused)
        for (final d in occurrencesInRange(s, now, end)) Upcoming(s, d),
  ];
  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.sub.name.compareTo(b.sub.name);
  });
  return out;
});

final upcomingTotalProvider = Provider<double>((ref) {
  final fx = ref.watch(fxProvider);
  final home = ref.watch(settingsProvider).homeCurrency;
  return ref
      .watch(upcomingProvider)
      .fold(0.0, (t, u) => t + fx.convert(u.sub.amount, u.sub.currency, home));
});

// day of month -> subs renewing that day
final monthPaymentsProvider = Provider.family<Map<int, List<Subscription>>, DateTime>((ref, month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  final out = <int, List<Subscription>>{};
  for (final s in ref.watch(subsProvider)) {
    if (s.paused) continue;
    for (final d in occurrencesInRange(s, first, last)) {
      out.putIfAbsent(d.day, () => []).add(s);
    }
  }
  return out;
});
