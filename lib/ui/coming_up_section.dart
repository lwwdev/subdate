import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../format.dart';
import '../logic/renewals.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'service_icon.dart';

class ComingUpSection extends ConsumerStatefulWidget {
  final void Function(Subscription) onEdit;
  const ComingUpSection({super.key, required this.onEdit});

  @override
  ConsumerState<ComingUpSection> createState() => _ComingUpSectionState();
}

class _ComingUpSectionState extends ConsumerState<ComingUpSection> {
  int _open = 0;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(upcomingProvider);
    final total = ref.watch(upcomingTotalProvider);
    final home = ref.watch(settingsProvider).homeCurrency;
    final now = ref.watch(nowProvider);
    final fx = ref.watch(fxProvider);
    final open = _open.clamp(0, max(0, items.length - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Coming up',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            _ChevronButton(
              collapsed: _collapsed,
              onTap: () => setState(() => _collapsed = !_collapsed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Next 7 days, ${money(total, home)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _collapsed
              ? const SizedBox(width: double.infinity)
              : items.isEmpty
                  ? const _Empty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _Overlap(
                            overlap: i == items.length - 1 ? 0 : 24,
                            child: _UpcomingCard(
                              item: items[i],
                              now: now,
                              expanded: i == open,
                              amountHint: items[i].sub.currency == home
                                  ? null
                                  : '≈ ${money(fx.convert(items[i].sub.amount, items[i].sub.currency, home), home)}',
                              onTap: () => i == open
                                  ? widget.onEdit(items[i].sub)
                                  : setState(() => _open = i),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _ChevronButton({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card.withValues(alpha: 0.6),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: AnimatedRotation(
          turns: collapsed ? -0.25 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Upcoming item;
  final DateTime now;
  final bool expanded;
  final String? amountHint;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.item,
    required this.now,
    required this.expanded,
    required this.onTap,
    this.amountHint,
  });

  @override
  Widget build(BuildContext context) {
    final s = item.sub;
    final tint = tintFor(s);
    final isToday = dateOnly(item.date) == dateOnly(now);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Color.lerp(AppColors.cardBorder, tint, 0.25)!),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppColors.card, tint, 0.28)!,
              AppColors.card,
            ],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, -6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ServiceIcon(s, size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.pill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(dayPill(item.date),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Row(children: [
                            _Field(
                              label: 'RENEWS',
                              value: relativeLabel(item.date, now),
                              color: isToday ? AppColors.red : null,
                            ),
                            _Field(
                              label: 'AMOUNT',
                              value: money(s.amount, s.currency),
                              hint: amountHint,
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            _Field(
                              label: 'CADENCE',
                              value: s.every == 1
                                  ? s.cadence.label
                                  : '${s.cadence.label} ×${s.every}',
                            ),
                            _Field(label: 'DATE', value: longDate(item.date)),
                          ]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? hint;

  const _Field({required this.label, required this.value, this.color, this.hint});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: color)),
          if (hint != null)
            Text(hint!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text('nothing due this week 🎉',
          style: TextStyle(color: AppColors.muted, fontSize: 16)),
    );
  }
}

// lays out the child but reports a shorter height so the next card slides over it
class _Overlap extends SingleChildRenderObjectWidget {
  final double overlap;
  const _Overlap({required this.overlap, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOverlap(overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderOverlap r) => r.overlap = overlap;
}

class _RenderOverlap extends RenderProxyBox {
  _RenderOverlap(this._overlap);

  double _overlap;
  set overlap(double v) {
    if (v == _overlap) return;
    _overlap = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints.loosen().copyWith(minWidth: constraints.minWidth), parentUsesSize: true);
    size = constraints.constrain(Size(c.size.width, max(0, c.size.height - _overlap)));
  }
}
