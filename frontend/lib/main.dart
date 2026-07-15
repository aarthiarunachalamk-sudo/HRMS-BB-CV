import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeFirebase();
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 6));
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global static notifier to toggle light/dark theme dynamically
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  static const String _fontFamily = 'Roboto';

  static TextTheme _appTextTheme(Color text, Color muted) {
    const base = TextStyle(
      fontFamily: _fontFamily,
      letterSpacing: 0,
      height: 1.25,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: base.copyWith(
        color: text,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: base.copyWith(
        color: text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: base.copyWith(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: base.copyWith(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: base.copyWith(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.copyWith(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: base.copyWith(
        color: text,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.copyWith(
        color: muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.copyWith(
        color: text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.copyWith(
        color: muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: base.copyWith(
        color: muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.copyWith(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.copyWith(
        color: muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.copyWith(
        color: muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffold,
    required Color card,
  }) {
    final isDark = brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF1F3654);
    final muted = isDark ? const Color(0xFF8E9CAE) : const Color(0xFF607086);
    final textTheme = _appTextTheme(text, muted);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0072FF),
        brightness: brightness,
      ),
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: muted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'BitByte HRMS',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: _theme(
            brightness: Brightness.light,
            scaffold: const Color(0xFFF3F6FA),
            card: Colors.white,
          ),
          darkTheme: _theme(
            brightness: Brightness.dark,
            scaffold: const Color(0xFF070D19),
            card: const Color(0xFF0F1B2E),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
