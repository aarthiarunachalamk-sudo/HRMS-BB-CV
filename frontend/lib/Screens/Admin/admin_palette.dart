import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

/// Adaptive colour palette for Admin screens – reads current theme from context.
class AdminPalette {
  final bool isDark;

  // Backgrounds
  final Color bg;
  final Color bgAlt;
  final Color surface;

  // Text
  final Color text;
  final Color muted;
  final Color hint;

  // Brand
  final Color primary;    // blue
  final Color green;
  final Color orange;
  final Color purple;
  final Color red;
  final Color gold;

  // UI chrome
  final Color border;
  final Color cardBg;
  final List<BoxShadow> shadow;

  const AdminPalette._({
    required this.isDark,
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.text,
    required this.muted,
    required this.hint,
    required this.primary,
    required this.green,
    required this.orange,
    required this.purple,
    required this.red,
    required this.gold,
    required this.border,
    required this.cardBg,
    required this.shadow,
  });

  factory AdminPalette.of(BuildContext context) {
    final dark = ThemeConfig.isDark(context);
    return dark ? _dark : _light;
  }

  static const _dark = AdminPalette._(
    isDark: true,
    bg:      Color(0xFF070D19),
    bgAlt:   Color(0xFF0F223D),
    surface: Color(0xFF0F1B2E),
    text:    Colors.white,
    muted:   Color(0xFF8E9CAE),
    hint:    Color(0xFF5A6A80),
    primary: Color(0xFF4FACFE),
    green:   Color(0xFF13D989),
    orange:  Color(0xFFF7971E),
    purple:  Color(0xFF9F3BFF),
    red:     Color(0xFFFF3D5F),
    gold:    Color(0xFFD7932E),
    border:  Color(0xFF1E2E44),
    cardBg:  Color(0xFF0F1B2E),
    shadow: [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 8))],
  );

  static const _light = AdminPalette._(
    isDark: false,
    bg:      Color(0xFFF4F7FB),
    bgAlt:   Color(0xFFE9EFF6),
    surface: Colors.white,
    text:    Color(0xFF1A2942),
    muted:   Color(0xFF607086),
    hint:    Color(0xFFB0BEC5),
    primary: Color(0xFF1976D2),
    green:   Color(0xFF0FAD5E),
    orange:  Color(0xFFE87B0C),
    purple:  Color(0xFF7C3AED),
    red:     Color(0xFFDC2626),
    gold:    Color(0xFFB8860B),
    border:  Color(0xFFDDE3EE),
    cardBg:  Colors.white,
    shadow: [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))],
  );

  /// Toggle the global theme between dark and light.
  static void toggleTheme() {
    MyApp.themeNotifier.value =
        MyApp.themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  Gradient get primaryGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF4FACFE), const Color(0xFF0072FF)]
            : [const Color(0xFF2196F3), const Color(0xFF0D47A1)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  Gradient get bgGradient => LinearGradient(
        colors: [bg, bgAlt],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
