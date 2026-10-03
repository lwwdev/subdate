import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/sample.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'coming_up_section.dart';
import 'payments_calendar.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(nowProvider.notifier).tick();
  }

  void _edit([Subscription? s]) {
    // TODO edit sheet
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subsProvider);
    return Scaffold(
      body: Starfield(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  if (subs.isEmpty)
                    _FirstRun(onSample: () async {
                      for (final s in sampleSubs(DateTime.now())) {
                        await ref.read(subsProvider.notifier).save(s);
                      }
                    }, onAdd: _edit)
                  else ...[
                    ComingUpSection(onEdit: _edit),
                    const SizedBox(height: 28),
                    PaymentsCalendar(onDayTap: (day, subs) {}),
                  ],
                ],
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(top: 80),
      child: Column(
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
