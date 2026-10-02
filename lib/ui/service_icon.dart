import 'package:flutter/material.dart';

import '../brand/brand_catalog.dart';
import '../models/subscription.dart';

class ServiceIcon extends StatelessWidget {
  final Subscription sub;
  final double size;

  const ServiceIcon(this.sub, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final brand = brandFor(sub.brandKey);
    final radius = BorderRadius.circular(size * 0.24);
    final bg = brand?.bg ?? Color(sub.color ?? 0xFF5B5FD0);

    Widget child;
    if (sub.customImage != null) {
      child = Image.memory(sub.customImage!, fit: BoxFit.cover, width: size, height: size);
    } else if (brand?.icon != null) {
      child = Icon(brand!.icon, size: size * 0.58, color: brand.fg);
    } else {
      child = Text(
        sub.name.isEmpty ? '?' : sub.name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}

// tint used for card gradients
Color tintFor(Subscription s) {
  final b = brandFor(s.brandKey);
  if (b == null) return Color(s.color ?? 0xFF5B5FD0);
  // white/black tiles look bad as a tint so use the glyph color
  final lum = b.bg.computeLuminance();
  return (lum > 0.8 || lum < 0.02) ? b.fg : b.bg;
}
