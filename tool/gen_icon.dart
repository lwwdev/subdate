// flutter test tool/gen_icon.dart -> assets/icon.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      const Rect.fromLTWH(0, 0, s, s),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2250), Color(0xFF0B0E1F)],
        ).createShader(const Rect.fromLTWH(0, 0, s, s)),
    );
    // 3x3 grid of rounded slots, one lit up
    const cell = 200.0, gap = 44.0;
    const start = (s - (cell * 3 + gap * 2)) / 2;
    for (var r = 0; r < 3; r++) {
      for (var col = 0; col < 3; col++) {
        final lit = r == 1 && col == 2;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(start + col * (cell + gap), start + r * (cell + gap), cell, cell),
          const Radius.circular(52),
        );
        c.drawRRect(rect, Paint()..color = lit ? const Color(0xFF7B7FF0) : const Color(0x22FFFFFF));
        if (lit) {
          c.drawRRect(
            rect.inflate(16),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..color = const Color(0x997B7FF0),
          );
        }
      }
    }
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/icon.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
