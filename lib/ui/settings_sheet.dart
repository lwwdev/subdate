import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../models/subscription.dart';
import '../theme.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SettingsSheet(),
  );
}

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fx = ref.watch(fxProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final currencies = {...fx.currencies, settings.homeCurrency}.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: settings.homeCurrency,
            decoration: const InputDecoration(labelText: 'Home currency (totals)'),
            items: [for (final c in currencies) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => notifier.update(settings.copyWith(homeCurrency: v)),
          ),
          const SizedBox(height: 12),
          if (!kIsWeb) ...[
            DropdownButtonFormField<int>(
              initialValue: remindOptions.containsKey(settings.defaultRemind) ? settings.defaultRemind : 1,
              decoration: const InputDecoration(labelText: 'Default reminder for new subs'),
              items: [
                for (final e in remindOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => notifier.update(settings.copyWith(defaultRemind: v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: settings.notifyHour,
              decoration: const InputDecoration(labelText: 'Remind me at'),
              items: [
                for (var h = 6; h <= 22; h++)
                  DropdownMenuItem(value: h, child: Text(DateFormat.j().format(DateTime(2000, 1, 1, h)))),
              ],
              onChanged: (v) => notifier.update(settings.copyWith(notifyHour: v)),
            ),
            const SizedBox(height: 12),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exchange rates'),
            subtitle: Text('updated ${DateFormat.yMMMd().add_jm().format(fx.fetchedAt)}',
                style: const TextStyle(color: AppColors.muted)),
            trailing: _refreshing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () async {
                      setState(() => _refreshing = true);
                      await ref.read(fxProvider.notifier).refresh();
                      if (mounted) setState(() => _refreshing = false);
                    },
                  ),
          ),
          const SizedBox(height: 8),
          const Text('rates from the ECB via frankfurter.dev, good enough for a rough total',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
