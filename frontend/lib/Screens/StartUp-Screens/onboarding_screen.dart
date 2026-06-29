import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'theme_config.dart';
import 'constellation_background.dart';
import 'logo_widget.dart';
import 'boom_in_widget.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Customizer state
  bool _isClumsy = false;
  
  // Theme manual override index: 0 = Default (follows page theme), 1 = Blue, 2 = Purple, 3 = Green
  int _themeOverrideIndex = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Smart Workforce Management',
      description: 'Manage your entire workforce from a single dashboard. Track attendance, leaves, and performance in real time.',
      centerIcon: Icons.people_rounded,
      cardIcon1: Icons.calendar_today_rounded,
      cardIcon2: Icons.trending_up_rounded,
      themeColor: ThemeConfig.blueAccent,
      themeColorDark: ThemeConfig.blueSecondary,
      buttonGradient: ThemeConfig.blueGradient,
    ),
    OnboardingSlideData(
      title: 'Payroll & Insights',
      description: 'Process payroll with one tap and gain deep analytics on team productivity, leave trends, and HR metrics.',
      centerIcon: Icons.bar_chart_rounded,
      cardIcon1: Icons.insights_rounded,
      cardIcon2: Icons.show_chart_rounded,
      themeColor: ThemeConfig.purpleAccent,
      themeColorDark: ThemeConfig.purpleSecondary,
      buttonGradient: ThemeConfig.purpleGradient,
    ),
    OnboardingSlideData(
      title: 'GEO Tracking Attendance',
      description: 'Clock in and out using GPS location tracking. Secure, accurate, and location-based attendance verification.',
      centerIcon: Icons.location_on_rounded,
      cardIcon1: Icons.gps_fixed_rounded,
      cardIcon2: Icons.map_outlined,
      themeColor: ThemeConfig.greenThemeAccent,
      themeColorDark: ThemeConfig.greenThemeSecondary,
      buttonGradient: ThemeConfig.greenGradient,
    ),
  ];

  Color _getCurrentAccentColor() {
    if (_themeOverrideIndex == 0) {
      return _slides[_currentPage].themeColor;
    } else if (_themeOverrideIndex == 1) {
      return ThemeConfig.blueAccent;
    } else if (_themeOverrideIndex == 2) {
      return ThemeConfig.purpleAccent;
    } else {
      return ThemeConfig.greenThemeAccent;
    }
  }

  Gradient _getCurrentButtonGradient() {
    if (_themeOverrideIndex == 0) {
      return _slides[_currentPage].buttonGradient;
    } else if (_themeOverrideIndex == 1) {
      return ThemeConfig.blueGradient;
    } else if (_themeOverrideIndex == 2) {
      return ThemeConfig.purpleGradient;
    } else {
      return ThemeConfig.greenGradient;
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToSignUp();
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _toggleThemeOverride() {
    setState(() {
      _themeOverrideIndex = (_themeOverrideIndex + 1) % 4;
    });
    final themes = ['Sync with Pages', 'Cool Blue Theme', 'Royal Purple Theme', 'Emerald Green Theme'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme set to: ${themes[_themeOverrideIndex]}'),
        duration: const Duration(seconds: 1),
        backgroundColor: _getCurrentAccentColor().withAlpha(204),
      ),
    );
  }

  void _toggleBrightnessMode() {
    final currentMode = MyApp.themeNotifier.value;
    if (currentMode == ThemeMode.dark) {
      MyApp.themeNotifier.value = ThemeMode.light;
    } else {
      MyApp.themeNotifier.value = ThemeMode.dark;
    }
  }

  void _toggleNetworkDensity() {
    setState(() {
      _isClumsy = !_isClumsy;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network background set to: ${_isClumsy ? "Clumsy (Dense)" : "Neat (Sparse)"}'),
        duration: const Duration(seconds: 1),
        backgroundColor: _getCurrentAccentColor().withAlpha(204),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final accentColor = _getCurrentAccentColor();
    final buttonGradient = _getCurrentButtonGradient();

    return Scaffold(
      body: ConstellationBackground(
        accentColor: accentColor,
        isClumsy: _isClumsy,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar (Logo, Skip button, Theme override, Light/Dark toggle, Neat/Clumsy toggle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mini Logo
                    const BitByteLogo(
                      compact: true,
                    ),

                    // Actions
                    Row(
                      children: [
                        TextButton(
                          onPressed: _navigateToSignUp,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: ThemeConfig.getTextSecondary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Neat/Clumsy Background Switcher
                        IconButton(
                          icon: Icon(
                            _isClumsy ? Icons.grain_rounded : Icons.grid_goldenratio_rounded,
                            color: accentColor,
                          ),
                          onPressed: _toggleNetworkDensity,
                          tooltip: _isClumsy ? 'Switch to Neat Network' : 'Switch to Clumsy Network',
                        ),
                        // Light/Dark Theme Mode Toggle
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            color: accentColor,
                          ),
                          onPressed: _toggleBrightnessMode,
                          tooltip: 'Toggle Light/Dark Theme',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: accentColor,
                          ),
                          onPressed: _toggleThemeOverride,
                          tooltip: 'Switch Accent Colors',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Page Content (Slider)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideContent(slide, accentColor);
                  },
                ),
              ),

              // Dots and Bottom Buttons Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isActive ? 24 : 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isActive
                                ? accentColor
                                : ThemeConfig.getTextMuted(context).withAlpha(128),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Navigation Button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: buttonGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(90),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _slides.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build onboarding graphic + headings
  Widget _buildSlideContent(OnboardingSlideData slide, Color activeColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Premium Bobbing Graphics wrapped in BoomIn pop animation
        BoomInWidget(
          key: ValueKey('${slide.title}_$_currentPage'),
          child: _buildIllustration(slide, activeColor),
        ),
        const SizedBox(height: 48),

        // Title text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.getTextPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: ThemeConfig.getTextSecondary(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Interactive floating graphics section
  Widget _buildIllustration(OnboardingSlideData slide, Color activeColor) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);

    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Concentric background circle 1
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withAlpha(isDark ? 20 : 40),
                width: 1.5,
              ),
            ),
          ),
          // Concentric background circle 2
          Container(
            width: 155,
            height: 155,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withAlpha(isDark ? 38 : 65),
                width: 1.0,
              ),
            ),
          ),

          // Main Center Circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(
                color: activeColor,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withAlpha(isDark ? 64 : 45),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                slide.centerIcon,
                color: activeColor,
                size: 38,
              ),
            ),
          ),

          // Floating Square Card 1 (Top-Right)
          _buildFloatingCard(
            x: 65.0,
            y: -65.0,
            icon: slide.cardIcon1,
            color: activeColor,
            bobDelay: 0.0,
            cardBg: cardBg,
          ),

          // Floating Square Card 2 (Bottom-Left)
          _buildFloatingCard(
            x: -65.0,
            y: 65.0,
            icon: slide.cardIcon2,
            color: activeColor,
            bobDelay: 1.5,
            cardBg: cardBg,
          ),
        ],
      ),
    );
  }

  // Floating small widget with micro-animations
  Widget _buildFloatingCard({
    required double x,
    required double y,
    required IconData icon,
    required Color color,
    required double bobDelay,
    required Color cardBg,
  }) {
    final isDark = ThemeConfig.isDark(context);
    return Positioned(
      left: 120.0 + x - 22.0,
      top: 120.0 + y - 22.0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 2 * math.pi),
        duration: const Duration(seconds: 4),
        builder: (context, angle, child) {
          final double bobOffset = math.sin(angle + bobDelay) * 6.0;
          return Transform.translate(
            offset: Offset(0, bobOffset),
            child: child,
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withAlpha(isDark ? 90 : 130),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 76 : 15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
