import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'constellation_background.dart';
import 'logo_widget.dart';
import 'boom_in_widget.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    return _slides[_currentPage].themeColor;
  }

  Gradient _getCurrentButtonGradient() {
    return _slides[_currentPage].buttonGradient;
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
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getCurrentAccentColor();
    final buttonGradient = _getCurrentButtonGradient();

    return Scaffold(
      body: ConstellationBackground(
        accentColor: accentColor,
        isClumsy: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 520 ||
                  constraints.maxWidth > constraints.maxHeight;
              return Column(
                children: [
                  _buildTopBar(compact: compact),
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
                        return _buildSlideContent(
                          slide,
                          accentColor,
                          compact: compact,
                        );
                      },
                    ),
                  ),
                  _buildBottomControls(
                    accentColor,
                    buttonGradient,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 24,
        vertical: compact ? 4 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BitByteLogo(compact: true),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _navigateToSignUp,
                style: TextButton.styleFrom(
                  minimumSize: compact ? const Size(44, 34) : null,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: ThemeConfig.getTextSecondary(context),
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    Color accentColor,
    Gradient buttonGradient, {
    required bool compact,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 26 : 24,
        compact ? 4 : 20,
        compact ? 26 : 24,
        compact ? 8 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SizedBox(height: compact ? 10 : 32),
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: double.infinity,
              height: compact ? 46 : 56,
              decoration: BoxDecoration(
                gradient: buttonGradient,
                borderRadius: BorderRadius.circular(compact ? 14 : 16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(90),
                    blurRadius: compact ? 9 : 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: compact ? 17 : 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!compact) const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Widget to build onboarding graphic + headings
  Widget _buildSlideContent(
    OnboardingSlideData slide,
    Color activeColor, {
    required bool compact,
  }) {
    final illustration = BoomInWidget(
      key: ValueKey('${slide.title}_$_currentPage'),
      child: _buildIllustration(
        slide,
        activeColor,
        size: compact ? 150 : 240,
      ),
    );
    final textBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: ThemeConfig.getTextPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          maxLines: compact ? 3 : null,
          overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: ThemeConfig.getTextSecondary(context),
            height: 1.35,
          ),
        ),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            illustration,
            const SizedBox(width: 34),
            Flexible(child: textBlock),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 430),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            illustration,
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: textBlock,
            ),
          ],
        ),
      ),
    );
  }

  // Interactive floating graphics section
  Widget _buildIllustration(
    OnboardingSlideData slide,
    Color activeColor, {
    required double size,
  }) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final center = size / 2;
    final outerSize = size * .83;
    final innerSize = size * .65;
    final mainSize = size * .42;
    final iconSize = size * .16;
    final cardSize = size * .18;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Concentric background circle 1
          Container(
            width: outerSize,
            height: outerSize,
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
            width: innerSize,
            height: innerSize,
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
            width: mainSize,
            height: mainSize,
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
                size: iconSize,
              ),
            ),
          ),

          // Floating Square Card 1 (Top-Right)
          _buildFloatingCard(
            center: center,
            x: size * .27,
            y: -size * .27,
            icon: slide.cardIcon1,
            color: activeColor,
            bobDelay: 0.0,
            cardBg: cardBg,
            size: cardSize,
          ),

          // Floating Square Card 2 (Bottom-Left)
          _buildFloatingCard(
            center: center,
            x: -size * .27,
            y: size * .27,
            icon: slide.cardIcon2,
            color: activeColor,
            bobDelay: 1.5,
            cardBg: cardBg,
            size: cardSize,
          ),
        ],
      ),
    );
  }

  // Floating small widget with micro-animations
  Widget _buildFloatingCard({
    required double center,
    required double x,
    required double y,
    required IconData icon,
    required Color color,
    required double bobDelay,
    required Color cardBg,
    required double size,
  }) {
    final isDark = ThemeConfig.isDark(context);
    return Positioned(
      left: center + x - (size / 2),
      top: center + y - (size / 2),
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
          width: size,
          height: size,
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
              size: size * .45,
            ),
          ),
        ),
      ),
    );
  }
}
