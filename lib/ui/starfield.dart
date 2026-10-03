import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class Starfield extends StatelessWidget {
  final Widget child;
  const Starfield({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bg],
        ),
      ),
      child: CustomPaint(painter: _StarPainter(), child: child),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42); // same stars every frame
    final count = (size.width * size.height / 9000).clamp(40, 400).toInt();
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final o = 0.15 + rnd.nextDouble() * 0.45;
      // a few warm ones like in the mock
      p.color = (rnd.nextDouble() < 0.08 ? const Color(0xFFFFB199) : Colors.white)
          .withValues(alpha: o);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 1.1,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}
