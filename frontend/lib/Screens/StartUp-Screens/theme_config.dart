import 'package:flutter/material.dart';

class ThemeConfig {
  // Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Background Gradient Colors
  static Color getBgStart(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1020) : const Color(0xFFF7F8FC);
  static Color getBgEnd(BuildContext context) =>
      isDark(context) ? const Color(0xFF111A2D) : const Color(0xFFEEF1F7);

  // Core Text Colors
  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF4F7FF) : const Color(0xFF172033);
  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFA4AEC0) : const Color(0xFF667085);
  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF778197) : const Color(0xFF7B8496);

  // Card Styles
  static Color getCardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF121A2B) : Colors.white;
  static Color getCardBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF283247) : const Color(0xFFE0E5EE);

  // Network Painter Colors
  static const Color lightPainterColor = Color(0xFF147893); // Hex #147893
  static const Color darkPainterColor = Color(0xFF084B8C);  // Hex #084B8C

  // Get active painter color based on theme
  static Color getPainterColor(BuildContext context) {
    return isDark(context) ? darkPainterColor : lightPainterColor;
  }
  
  // Theme Accent Colors
  // Shared action palette. This matches the active tab treatment used across
  // the dashboards, so tabs and primary buttons feel like one design system.
  static const Color blueAccent = Color(0xFF00C6FF);
  static const Color blueSecondary = Color(0xFF0072FF);
  // Solid equivalent of the Login button gradient for Material buttons.
  static const Color loginButtonColor = blueSecondary;

  static const Color purpleAccent = Color(0xFF9F3BFF);
  static const Color purpleSecondary = Color(0xFF6C1BFF);

  static const Color greenAccent = Color(0xFF00F2FE);
  static const Color greenSecondary = Color(0xFF4FACFE);
  
  static const Color greenThemeAccent = Color(0xFF3DD6C5);
  static const Color greenThemeSecondary = Color(0xFF159A8C);

  // Gradients for Buttons
  static const Gradient blueGradient = LinearGradient(
    colors: [blueAccent, blueSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient purpleGradient = LinearGradient(
    colors: [purpleAccent, purpleSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient greenGradient = LinearGradient(
    colors: [greenThemeAccent, greenThemeSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient splashButtonGradient = LinearGradient(
    colors: [purpleAccent, greenThemeAccent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Standard Box Shadow
  static List<BoxShadow> getPremiumShadow(BuildContext context) => [
        BoxShadow(
          color: isDark(context) ? const Color(0x66000000) : const Color(0x0F000000),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // Font typography styles helper
  static TextStyle headlineStyle(BuildContext context, {
    double size = 28,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: getTextPrimary(context),
      letterSpacing: 0,
    );
  }

  static TextStyle bodyStyle(BuildContext context, {
    double size = 15,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: getTextSecondary(context),
      height: 1.5,
    );
  }
}

// Model representing each Onboarding Slide details
class OnboardingSlideData {
  final String title;
  final String description;
  final IconData centerIcon;
  final IconData cardIcon1;
  final IconData cardIcon2;
  final Color themeColor;
  final Color themeColorDark;
  final Gradient buttonGradient;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.centerIcon,
    required this.cardIcon1,
    required this.cardIcon2,
    required this.themeColor,
    required this.themeColorDark,
    required this.buttonGradient,
  });
}
