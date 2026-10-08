import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/brand_catalog.dart';
import '../data/providers.dart';
import '../format.dart';
import '../logic/renewals.dart';
import '../logic/sub_list.dart';
import '../models/category.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'service_icon.dart';

Future<void> showAllSubsSheet(BuildContext context, {required void Function(Subscription) onEdit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AllSubsSheet(onEdit: onEdit),
  );
}

class AllSubsSheet extends ConsumerStatefulWidget {
  final void Function(Subscription) onEdit;
  const AllSubsSheet({super.key, required this.onEdit});

  @override
  ConsumerState<AllSubsSheet> createState() => _AllSubsSheetState();
}

class _AllSubsSheetState extends ConsumerState<AllSubsSheet> {
  final _search = TextEditingController();
  SubSort _sort = SubSort.next;
  Category? _cat;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subsProvider);
    final now = ref.watch(nowProvider);
    final home = ref.watch(settingsProvider).homeCurrency;
    final shown = listSubs(
      subs,
      sort: _sort,
      now: now,
      fx: ref.watch(fxProvider),
      home: home,
      query: _search.text,
      category: _cat,
    );
    final cats = {for (final s in subs) categoryOf(s)}.toList()..sort((a, b) => a.index.compareTo(b.index));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: CustomScrollView(
          controller: scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList.list(children: [
                Row(
                  children: [
                    const Text('All subscriptions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    PopupMenuButton<SubSort>(
                      tooltip: 'Sort',
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      itemBuilder: (_) => [for (final s in SubSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.sort_rounded, size: 18, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(_sort.label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'search',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
                if (cats.length > 1) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final c in [null, ...cats])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: c == null ? null : CircleAvatar(backgroundColor: c.color, radius: 5),
                            label: Text(c?.label ?? 'All'),
                            selected: _cat == c,
                            onSelected: (_) => setState(() => _cat = c),
                          ),
                        ),
                    ]),
                  ),
                ],
                const SizedBox(height: 8),
              ]),
            ),
            if (shown.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('nothing matches', style: TextStyle(color: AppColors.muted))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                sliver: SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _Row(shown[i], now: now, onTap: () => widget.onEdit(shown[i])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Subscription s;
  final DateTime now;
  final VoidCallback onTap;
  const _Row(this.s, {required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final next = nextRenewal(s, now);
    final every = s.every == 1 ? s.cadence.label : 'every ${s.every} ${s.cadence.label.toLowerCase()}';
    final when = s.paused ? 'paused' : '${s.trial ? 'trial ends' : 'renews'} ${relativeLabel(next, now)}';
    return Opacity(
      opacity: s.paused ? 0.5 : 1,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: ServiceIcon(s, size: 42),
        title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$every · $when', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(money(s.amount, s.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
            if (!s.paused)
              Text(dayPill(next), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
