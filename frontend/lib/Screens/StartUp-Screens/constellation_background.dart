import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_config.dart';

class ConstellationBackground extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final bool isClumsy;

  const ConstellationBackground({
    super.key,
    required this.child,
    this.accentColor = ThemeConfig.blueAccent,
    this.isClumsy = false,
  });

  @override
  State<ConstellationBackground> createState() => _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateParticles();
      });
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      _initParticles();
    }
  }

  @override
  void didUpdateWidget(covariant ConstellationBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize particles if Neat/Clumsy mode changes
    if (widget.isClumsy != oldWidget.isClumsy) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    final size = MediaQuery.of(context).size;
    final w = size.width > 0 ? size.width : 400.0;
    final h = size.height > 0 ? size.height : 800.0;
    
    // Config based on Neat vs Clumsy
    final particleCount = widget.isClumsy ? 65 : 20;
    final speedMultiplier = widget.isClumsy ? 0.75 : 0.35;

    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        _Particle(
          position: Offset(
            _random.nextDouble() * w,
            _random.nextDouble() * h,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * speedMultiplier,
            (_random.nextDouble() - 0.5) * speedMultiplier,
          ),
          radius: _random.nextDouble() * (widget.isClumsy ? 3.0 : 2.0) + 1.0,
        ),
      );
    }
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;
    if (size.width == 0 || size.height == 0) return;

    if (_particles.isEmpty) {
      _initParticles();
    }

    setState(() {
      for (var particle in _particles) {
        particle.position += particle.velocity;

        // Boundary checks and bouncing
        if (particle.position.dx < 0 || particle.position.dx > size.width) {
          particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
        }
        if (particle.position.dy < 0 || particle.position.dy > size.height) {
          particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final bgStart = ThemeConfig.getBgStart(context);
    final bgEnd = ThemeConfig.getBgEnd(context);
    
    // Use user-defined colors for painter nodes and lines:
    // Light Mode: #147893, Dark Mode: #084B8C
    final Color painterColor = ThemeConfig.getPainterColor(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background Glow Blurs
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: painterColor.withAlpha(isDark ? 10 : 35),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: painterColor.withAlpha(isDark ? 8 : 25),
              ),
            ),
          ),
          // Constellation Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _ConstellationPainter(
                particles: _particles,
                painterColor: painterColor,
                isDark: isDark,
                isClumsy: widget.isClumsy,
              ),
            ),
          ),
          // Child content
          widget.child,
        ],
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  final double radius;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
  });
}

class _ConstellationPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color painterColor;
  final bool isDark;
  final bool isClumsy;

  _ConstellationPainter({
    required this.particles,
    required this.painterColor,
    required this.isDark,
    required this.isClumsy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint nodePaint = Paint()
      ..color = painterColor.withAlpha(isDark ? 160 : 210)
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isClumsy ? 0.7 : 0.5;

    // Configuration limits based on mode
    final double maxDistance = isClumsy ? 130.0 : 100.0;
    
    // Draw lines first (so they sit below nodes)
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final double dist = (particles[i].position - particles[j].position).distance;
        if (dist < maxDistance) {
          final double opacity = 1.0 - (dist / maxDistance);
          // Faint lines, slightly higher contrast in clumsy and light modes
          final int maxAlpha = isClumsy ? (isDark ? 55 : 85) : (isDark ? 38 : 65);
          final int alpha = (opacity * maxAlpha).toInt();
          linePaint.color = painterColor.withAlpha(alpha);
          canvas.drawLine(
            particles[i].position,
            particles[j].position,
            linePaint,
          );
        }
      }
    }

    // Draw nodes
    for (var particle in particles) {
      // Add subtle glow around nodes
      final Paint glowPaint = Paint()
        ..color = painterColor.withAlpha(isDark ? 40 : 80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(particle.position, particle.radius * 2.2, glowPaint);
      
      // Core particle
      nodePaint.color = isDark ? Colors.white.withAlpha(180) : const Color(0xFF0F172A).withAlpha(190);
      canvas.drawCircle(particle.position, particle.radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return true; // Repaint on every tick
  }
}
