import 'package:flutter/material.dart';

class ThemeConfig {
  // Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Background Gradient Colors
  static Color getBgStart(BuildContext context) =>
      isDark(context) ? const Color(0xFF070D19) : const Color(0xFFF8FAFC);
  static Color getBgEnd(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F223D) : const Color(0xFFE2E8F0);

  // Core Text Colors
  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1F3654);
  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF8E9CAE) : const Color(0xFF607086);
  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF5A6A80) : const Color(0xFF94A3B8);

  // Card Styles
  static Color getCardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F1B2E) : Colors.white;
  static Color getCardBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0);

  // Network Painter Colors
  static const Color lightPainterColor = Color(0xFF147893); // Hex #147893
  static const Color darkPainterColor = Color(0xFF084B8C);  // Hex #084B8C

  // Get active painter color based on theme
  static Color getPainterColor(BuildContext context) {
    return isDark(context) ? darkPainterColor : lightPainterColor;
  }
  
  // Theme Accent Colors
  static const Color blueAccent = Color(0xFF00C6FF);
  static const Color blueSecondary = Color(0xFF0072FF);

  static const Color purpleAccent = Color(0xFF9F3BFF);
  static const Color purpleSecondary = Color(0xFF6C1BFF);

  static const Color greenAccent = Color(0xFF00F2FE);
  static const Color greenSecondary = Color(0xFF4FACFE);
  
  static const Color greenThemeAccent = Color(0xFF00FF9D);
  static const Color greenThemeSecondary = Color(0xFF00B876);

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
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 10),
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
