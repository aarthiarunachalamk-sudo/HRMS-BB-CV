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
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash_screen.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        final duration = _controller.value.duration;
        if (duration > Duration.zero) {
          _fallbackTimer = Timer(duration + const Duration(milliseconds: 700), _goNext);
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
              : const ColoredBox(color: Colors.black),
        ),
      ),
    );
  }
}
