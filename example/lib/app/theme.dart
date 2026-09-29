import 'package:flutter/material.dart';

/// Identixia workbench palette (cool paper + teal).
abstract final class AppColors {
  static const bg = Color(0xFFE6E9EF);
  static const card = Color(0xFF0F766E);
  static const tile = Color(0xFF0F766E);
  static const tileTouch = Color(0xFF0B4F4A);
  static const accent = Color(0xFF0F766E);
  static const accentDim = Color(0xFF0B4F4A);
  static const text = Color(0xFF141A22);
  static const muted = Color(0xFF5A6573);
  static const statusInfo = Color(0xFF0B4F4A);
  static const statusOk = Color(0xFF0F766E);
  static const statusWarn = Color(0xFFB45309);
  static const statusError = Color(0xFFB91C1C);
  static const surface = Color(0xFFF7F8FA);
  static const surfaceAlt = Color(0xFFDFE4EC);
  static const border = Color(0xFFC5CCD8);
  static const blackBg = Color(0xFFE6E9EF);
  static const livenessReal = Color(0xFF0F766E);
  static const livenessSpoof = Color(0xFFB91C1C);
  static const danger = Color(0xFFB91C1C);
  static const onPrimary = Color(0xFFF4FFFC);
  static const overlayScrim = Color(0xE0141A22);
  static const ovalStroke = Color(0xFF5EEAD4);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
    );
  }

  /// Prefer [light]; kept for call sites that still request dark.
  static ThemeData get dark => light;
}