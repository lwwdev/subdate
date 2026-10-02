import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/sample.dart';
import '../format.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'coming_up_section.dart';
import 'edit_subscription_sheet.dart';
import 'payments_calendar.dart';
import 'service_icon.dart';
import 'settings_sheet.dart';
import 'spending_card.dart';
import 'starfield.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminders());
  }

  void _syncReminders() {
    ref.read(notificationsProvider).sync(
          ref.read(subsProvider),
          ref.read(settingsProvider).notifyHour,
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(nowProvider.notifier).tick();
      _syncReminders(); // tops up the queue since we only schedule ~60 ahead
    }
  }

  void _edit([Subscription? s]) => showEditSheet(context, existing: s);

  void _showDay(DateTime day, List<Subscription> subs) {
    final fx = ref.read(fxProvider);
    final home = ref.read(settingsProvider).homeCurrency;
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(longDate(day), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final s in subs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ServiceIcon(s, size: 44),
                  title: Text(s.name),
                  subtitle: Text(s.notes.isEmpty ? s.cadence.label : '${s.cadence.label} · ${s.notes}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(s.amount, s.currency),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (s.currency != home)
                        Text('≈ ${money(fx.convert(s.amount, s.currency, home), home)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _edit(s);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subsProvider);
    ref.listen(subsProvider, (_, _) => _syncReminders());
    ref.listen(settingsProvider.select((s) => s.notifyHour), (_, _) => _syncReminders());
    return Scaffold(
      floatingActionButton: subs.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _edit,
              tooltip: 'Add subscription',
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
      body: Starfield(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, c) {
            final header = Row(
              children: [
                const Text('subdate',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const Spacer(),
                IconButton(
                  onPressed: () => showSettingsSheet(context),
                  tooltip: 'Settings',
                  icon: const Icon(Icons.tune_rounded, color: AppColors.muted, size: 20),
                ),
              ],
            );
            if (subs.isEmpty) {
              return Center(
                child: _FirstRun(
                  onSample: () async {
                    for (final s in sampleSubs(DateTime.now())) {
                      await ref.read(subsProvider.notifier).save(s);
                    }
                  },
                  onAdd: _edit,
                ),
              );
            }
            // side by side on desktop-ish widths
            if (c.maxWidth >= 1000) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(24, 4, 24, 0), child: header),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(24, 4, 12, 120),
                                children: [
                                  ComingUpSection(onEdit: _edit),
                                  const SizedBox(height: 20),
                                  SpendingCard(onEdit: _edit),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(12, 56, 24, 120),
                                children: [PaymentsCalendar(onDayTap: _showDay)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    header,
                    const SizedBox(height: 4),
                    ComingUpSection(onEdit: _edit),
                    const SizedBox(height: 28),
                    PaymentsCalendar(onDayTap: _showDay),
                    const SizedBox(height: 20),
                    SpendingCard(onEdit: _edit),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _FirstRun extends StatelessWidget {
  final VoidCallback onSample;
  final VoidCallback onAdd;
  const _FirstRun({required this.onSample, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('no subs yet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('add one or load some sample data to look around',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAdd, child: const Text('Add subscription')),
          TextButton(onPressed: onSample, child: const Text('Load sample data')),
        ],
      ),
    );
  }
}
