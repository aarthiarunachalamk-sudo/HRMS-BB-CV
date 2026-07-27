import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/splash_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 6));
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
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
    final fill = isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9);
    final surface = isDark ? card : Colors.white;
    const primary = ThemeConfig.loginButtonColor;
    final onPrimary = Colors.white;
    final outline = isDark ? const Color(0xFF1E2E44) : const Color(0xFFD8E1EC);
    final textTheme = _appTextTheme(text, muted);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0072FF),
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: text,
        secondary: const Color(0xFF00C6FF),
        onSecondary: onPrimary,
        outline: outline,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: text),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
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
        textColor: text,
        selectedColor: primary,
        selectedTileColor: primary.withAlpha(isDark ? 30 : 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
        prefixIconColor: muted,
        suffixIconColor: muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyLarge,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: outline),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1B2E) : const Color(0xFF1F3654),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFF00C6FF),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fill,
        selectedColor: primary.withAlpha(isDark ? 55 : 35),
        disabledColor: isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
        labelStyle: textTheme.labelMedium!.copyWith(color: text),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: text),
        side: BorderSide(color: outline),
        iconTheme: IconThemeData(color: muted),
        checkmarkColor: primary,
        brightness: brightness,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: muted,
        indicator: BoxDecoration(
          gradient: ThemeConfig.blueGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: ThemeConfig.blueAccent.withAlpha(isDark ? 55 : 35),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected) ? primary : muted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: ThemeConfig.blueAccent.withAlpha(isDark ? 55 : 35),
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: primary),
        unselectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: muted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor:
              isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor:
              isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: muted,
          side: const BorderSide(color: primary),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: muted,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : primary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary
                : Colors.transparent,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: primary)),
        ),
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
