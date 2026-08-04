import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

class ClientVisitColors {
  static const navy = Color(0xFF061A3A);
  static const blue = Color(0xFF006CE5);
  static const cyan = Color(0xFF03A9C7);
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFDCE2EA);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const green = Color(0xFF24A43A);
  static const orange = Color(0xFFFF9800);
  static const red = Color(0xFFD71936);
}

class ClientVisitTheme extends StatelessWidget {
  final Widget child;

  const ClientVisitTheme({super.key, required this.child});

  static ThemeData data(BuildContext context) {
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    final background = ThemeConfig.getBgStart(context);
    final surface = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: ThemeConfig.blueSecondary,
      brightness: base.brightness,
    ).copyWith(surface: surface);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      dividerColor: border,
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF080E1F) : ClientVisitColors.navy,
        foregroundColor: isDark ? text : Colors.white,
        iconTheme: IconThemeData(color: isDark ? ThemeConfig.blueAccent : Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          color: muted,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ClientVisitColors.blue,
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ClientVisitColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ClientVisitColors.blue,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: ClientVisitColors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: isDark
            ? ThemeConfig.blueSecondary.withAlpha(45)
            : const Color(0xFFE7F1FF),
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = ThemeConfig.getBgStart(context);
    return Theme(
      data: data(context),
      child: ColoredBox(color: background, child: child),
    );
  }
}
