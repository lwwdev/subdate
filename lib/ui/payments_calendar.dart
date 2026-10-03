import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../format.dart';
import '../logic/renewals.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'service_icon.dart';

class PaymentsCalendar extends ConsumerStatefulWidget {
  final void Function(DateTime day, List<Subscription> subs) onDayTap;
  const PaymentsCalendar({super.key, required this.onDayTap});

  @override
  ConsumerState<PaymentsCalendar> createState() => _PaymentsCalendarState();
}

class _PaymentsCalendarState extends ConsumerState<PaymentsCalendar> {
  late DateTime _month;
  int _dir = 1; // which way the grid slides

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int by) => setState(() {
        _dir = by.sign;
        _month = DateTime(_month.year, _month.month + by);
      });

  void _goToday() {
    final now = DateTime.now();
    final m = DateTime(now.year, now.month);
    if (m == _month) return;
    setState(() {
      _dir = m.isAfter(_month) ? 1 : -1;
      _month = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(monthPaymentsProvider(_month));
    final today = dateOnly(ref.watch(nowProvider));
    final fx = ref.watch(fxProvider);
    final home = ref.watch(settingsProvider).homeCurrency;
    final monthTotal = payments.values
        .expand((l) => l)
        .fold(0.0, (t, s) => t + fx.convert(s.amount, s.currency, home));

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday - 1; // monday first
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 200) _shift(v < 0 ? 1 : -1);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
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
                const Icon(Icons.calendar_month_rounded, size: 19),
                const SizedBox(width: 10),
                const Text('Payments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (monthTotal > 0)
                  Text(money(monthTotal, home),
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _goToday,
                    child: Row(
                      children: [
                        Text(monthTitle(_month), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                        if (_month != DateTime(today.year, today.month)) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.today_rounded, size: 16, color: AppColors.muted),
                        ],
                      ],
                    ),
                  ),
                ),
                _NavButton(icon: Icons.chevron_left_rounded, onTap: () => _shift(-1)),
                const SizedBox(width: 12),
                _NavButton(icon: Icons.chevron_right_rounded, onTap: () => _shift(1)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                  Expanded(
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey(_month);
                  final dx = (incoming ? 0.15 : -0.15) * _dir;
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: Column(
                  key: ValueKey(_month),
                  children: [
                    for (var r = 0; r < rows; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            for (var c = 0; c < 7; c++)
                              Expanded(child: _cell(r * 7 + c - lead + 1, daysInMonth, payments, today)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int day, int daysInMonth, Map<int, List<Subscription>> payments, DateTime today) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
    final date = DateTime(_month.year, _month.month, day);
    final subs = payments[day] ?? const [];
    final isToday = date == today;
    final numColor = isToday
        ? AppColors.accent
        : subs.isNotEmpty
            ? AppColors.text
            : AppColors.dim;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: subs.isEmpty ? null : () => widget.onDayTap(date, subs),
      child: Column(
        children: [
          Text('$day',
              style: TextStyle(
                  color: numColor,
                  fontSize: 12.5,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500)),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, c) {
            final size = (c.maxWidth - 8).clamp(24.0, 56.0);
            return Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.26),
                color: subs.isEmpty ? AppColors.slot.withValues(alpha: 0.35) : AppColors.slot,
                border: Border.all(
                  color: isToday ? AppColors.accent : Colors.white.withValues(alpha: 0.04),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: subs.isEmpty
                  ? null
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: ServiceIcon(subs.first, size: size - 8)),
                        if (subs.length > 1)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('+${subs.length - 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.slot,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.accent, size: 24),
      ),
    );
  }
}
