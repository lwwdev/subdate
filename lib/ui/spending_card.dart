import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../format.dart';
import '../logic/spending.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'service_icon.dart';

class SpendingCard extends ConsumerStatefulWidget {
  final void Function(Subscription) onEdit;
  const SpendingCard({super.key, required this.onEdit});

  @override
  ConsumerState<SpendingCard> createState() => _SpendingCardState();
}

class _SpendingCardState extends ConsumerState<SpendingCard> {
  bool _yearly = false;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(settingsProvider).homeCurrency;
    final rows = spendBreakdown(ref.watch(subsProvider), ref.watch(fxProvider), home);
    if (rows.isEmpty) return const SizedBox.shrink();
    final mult = _yearly ? 12 : 1;
    final total = rows.fold(0.0, (t, r) => t + r.monthly) * mult;
    final top = rows.first.monthly;
    final shown = _all ? rows : rows.take(5).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 20),
              const SizedBox(width: 10),
              const Text('Spending', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const Spacer(),
              _Toggle(yearly: _yearly, onChanged: (v) => setState(() => _yearly = v)),
            ],
          ),
          const SizedBox(height: 16),
          Text(money(total, home), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          Text(
            _yearly ? 'per year, ${rows.length} subs' : 'per month, ${rows.length} subs',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final r in shown)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onEdit(r.sub),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    ServiceIcon(r.sub, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(r.sub.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              Text(money(r.monthly * mult, home),
                                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: top == 0 ? 0 : r.monthly / top,
                              minHeight: 5,
                              backgroundColor: AppColors.slot,
                              color: Color.lerp(tintFor(r.sub), AppColors.accent, 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (rows.length > 5)
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'show less' : 'show all ${rows.length}'),
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.yearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool value) {
      final on = yearly == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.muted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.slot, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Month', false), seg('Year', true)]),
    );
  }
}
