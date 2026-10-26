import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/backend/auth_session.dart';
import 'package:hrms_mobileapp_bitbyte/backend/login_warmup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  Timer? _startupTimer;
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Wake the hosted API while splash animation is playing.
    unawaited(LoginWarmup.start());

    // Pre-check authentication in background immediately.
    _checkFastAuth();

    // Max cap 3 seconds instead of 4-10 seconds
    _startupTimer = Timer(const Duration(milliseconds: 2500), _goNext);
    _controller = VideoPlayerController.asset('assets/videos/SplashScreen.mp4')
      ..initialize()
          .then((_) {
            if (!mounted || _navigated) return;
            setState(() {});
            final duration = _controller.value.duration;
            if (duration > Duration.zero) {
              _startupTimer?.cancel();
              _fallbackTimer = Timer(
                duration > const Duration(seconds: 3)
                    ? const Duration(seconds: 3)
                    : duration,
                _goNext,
              );
            } else {
              _fallbackTimer = Timer(const Duration(seconds: 2), _goNext);
            }
            _controller.play();
          })
          .catchError((_) {
            _goNext();
          });
    _controller.addListener(_handleVideoProgress);
  }

  void _checkFastAuth() async {
    try {
      final userData = await AuthSession.getUserData();
      final token = await AuthSession.accessToken();
      if (userData != null && token != null && token.isNotEmpty) {
        // If logged in, wait just 1.2s for brand recognition and jump into dashboard
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (mounted && !_navigated) {
          _goNext();
        }
      }
    } catch (_) {}
  }

  void _handleVideoProgress() {
    if (_navigated || !_controller.value.isInitialized) return;
    if (_controller.value.hasError) {
      _goNext();
      return;
    }
    final duration = _controller.value.duration;
    if (duration > Duration.zero &&
        _controller.value.position >=
            duration - const Duration(milliseconds: 120)) {
      _goNext();
    }
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _startupTimer?.cancel();
    _fallbackTimer?.cancel();

    try {
      final userData = await AuthSession.getUserData();
      final token = await AuthSession.accessToken();
      if (userData != null && token != null && token.isNotEmpty && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LoginScreen.buildDashboardForUser(userData),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Failed to restore saved session: $e');
    }

    if (!mounted) return;

    // Check if onboarding was previously seen
    var seenOnboarding = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    } catch (_) {}

    if (!mounted) return;

    final targetScreen = seenOnboarding
        ? const LoginScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _fallbackTimer?.cancel();
    _controller.removeListener(_handleVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goNext,
        child: Stack(
          children: [
            SizedBox.expand(
              child: _controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const _SplashFallback(),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _goNext,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black38,
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashFallback extends StatelessWidget {
  const _SplashFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071426), Color(0xFF02050A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 96, height: 96),
            const SizedBox(height: 18),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
