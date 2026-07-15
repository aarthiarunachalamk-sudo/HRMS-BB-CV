import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    _startupTimer = Timer(const Duration(seconds: 4), _goNext);
    _controller = VideoPlayerController.asset('assets/videos/SplashScreen.mp4')
      ..initialize().then((_) {
        if (!mounted || _navigated) return;
        setState(() {});
        final duration = _controller.value.duration;
        if (duration > Duration.zero) {
          _startupTimer?.cancel();
          _fallbackTimer = Timer(
            duration + const Duration(milliseconds: 700),
            _goNext,
          );
        } else {
          _fallbackTimer = Timer(const Duration(seconds: 10), _goNext);
        }
        _controller.play();
      }).catchError((_) {
        _goNext();
      });
    _controller.addListener(_handleVideoProgress);
  }

  void _handleVideoProgress() {
    if (_navigated || !_controller.value.isInitialized) return;
    if (_controller.value.hasError) {
      _goNext();
      return;
    }
    final duration = _controller.value.duration;
    if (duration > Duration.zero && _controller.value.position >= duration - const Duration(milliseconds: 120)) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _startupTimer?.cancel();
    _fallbackTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
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
        child: SizedBox.expand(
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
          colors: [
            Color(0xFF071426),
            Color(0xFF02050A),
          ],
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
