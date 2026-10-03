import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0E1F);
  static const bgTop = Color(0xFF111430);
  static const card = Color(0xFF1A1E33);
  static const cardBorder = Color(0xFF2A2F4A);
  static const slot = Color(0xFF20253D);
  static const accent = Color(0xFF7B7FF0);
  static const red = Color(0xFFFF6B5E);
  static const text = Colors.white;
  static const muted = Color(0xFF9CA0B8);
  static const dim = Color(0xFF4A4F6A);
  static const pill = Color(0xFF0D1020);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.card,
      error: AppColors.red,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slot,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// the little uppercase labels like RENEWS / AMOUNT
const labelStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 12,
  letterSpacing: 2,
  fontWeight: FontWeight.w500,
);
