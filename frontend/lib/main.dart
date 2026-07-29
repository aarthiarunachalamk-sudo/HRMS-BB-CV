import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/splash_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

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
  static const Color _brand = Color(0xFF0072FF);
  static const Color _brandDark = Color(0xFF0072FF);
  static const Color _accent = Color(0xFF20B8A6);

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
    final text = isDark ? const Color(0xFFF4F7FF) : const Color(0xFF172033);
    final muted = isDark ? const Color(0xFFA4AEC0) : const Color(0xFF667085);
    final fill = isDark ? const Color(0xFF151D2E) : const Color(0xFFF4F6FA);
    final surface = isDark ? card : Colors.white;
    final primary = isDark ? _brandDark : _brand;
    final onPrimary = Colors.white;
    final outline = isDark ? const Color(0xFF283247) : const Color(0xFFE0E5EE);
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
        secondary: _accent,
        onSecondary: onPrimary,
        outline: outline,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: text),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(minHeight: AppLayout.controlHeight),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1B2E) : const Color(0xFF1F3654),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFF00C6FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
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
        elevation: 0,
        height: 72,
        indicatorColor: primary.withAlpha(isDark ? 34 : 24),
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
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: primary),
        unselectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: muted),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ThemeConfig.blueSecondary,
          foregroundColor: onPrimary,
          disabledBackgroundColor:
              isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConfig.blueSecondary,
          foregroundColor: onPrimary,
          disabledBackgroundColor:
              isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
          disabledForegroundColor: muted,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeConfig.blueSecondary,
          disabledForegroundColor: muted,
          side: const BorderSide(color: ThemeConfig.blueSecondary),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: muted,
          minimumSize: const Size.square(AppLayout.iconTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
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
          side: WidgetStatePropertyAll(BorderSide(color: primary)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: outline,
        circularTrackColor: outline,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: muted, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
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
            scaffold: const Color(0xFFF7F8FC),
            card: Colors.white,
          ),
          darkTheme: _theme(
            brightness: Brightness.dark,
            scaffold: const Color(0xFF0B1020),
            card: const Color(0xFF121A2B),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
