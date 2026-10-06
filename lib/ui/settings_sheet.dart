import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/backup.dart';
import '../data/providers.dart';
import '../models/subscription.dart';
import '../theme.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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

  // snackbars end up behind the sheet so close it first
  void _toast(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: exportBackup(ref.read(subsProvider))));
    _toast('copied');
  }

  Future<void> _restore() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      final subs = importBackup(data?.text ?? '');
      final notifier = ref.read(subsProvider.notifier);
      for (final s in subs) {
        await notifier.save(s);
      }
      _toast('restored ${subs.length} subs');
    } catch (_) {
      _toast("clipboard doesn't look like a subdate backup");
    }
  }

  Future<void> _wipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text("can't undo this, copy a backup first if you care"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final notifier = ref.read(subsProvider.notifier);
    for (final s in [...ref.read(subsProvider)]) {
      await notifier.remove(s.id);
    }
    if (mounted) Navigator.pop(context);
  }

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
          DropdownButtonFormField<int>(
            initialValue: const [7, 14, 30].contains(settings.upcomingDays) ? settings.upcomingDays : 7,
            decoration: const InputDecoration(labelText: 'Coming up shows'),
            items: const [
              DropdownMenuItem(value: 7, child: Text('Next 7 days')),
              DropdownMenuItem(value: 14, child: Text('Next 14 days')),
              DropdownMenuItem(value: 30, child: Text('Next 30 days')),
            ],
            onChanged: (v) => notifier.update(settings.copyWith(upcomingDays: v)),
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
          const SizedBox(height: 20),
          const Divider(color: AppColors.cardBorder),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy backup'),
            subtitle: const Text('everything as json, paste it somewhere safe',
                style: TextStyle(color: AppColors.muted)),
            onTap: _copyBackup,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.paste_rounded),
            title: const Text('Restore from clipboard'),
            onTap: _restore,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            title: const Text('Delete everything', style: TextStyle(color: AppColors.red)),
            onTap: _wipe,
          ),
        ],
      ),
    );
  }
}
