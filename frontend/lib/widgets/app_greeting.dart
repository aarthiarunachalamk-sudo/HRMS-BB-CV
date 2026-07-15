import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppGreetingData {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color accent;

  const AppGreetingData({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.accent,
  });
}

class AppGreeting {
  static AppGreetingData current([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) {
      return const AppGreetingData(
        label: 'Good Morning',
        shortLabel: 'Morning',
        icon: Icons.wb_sunny_rounded,
        accent: Color(0xFFFFC247),
      );
    }
    if (hour >= 12 && hour < 17) {
      return const AppGreetingData(
        label: 'Good Afternoon',
        shortLabel: 'Afternoon',
        icon: Icons.light_mode_rounded,
        accent: Color(0xFFFF9F43),
      );
    }
    if (hour >= 17 && hour < 21) {
      return const AppGreetingData(
        label: 'Good Evening',
        shortLabel: 'Evening',
        icon: Icons.wb_twilight_rounded,
        accent: Color(0xFFFF6B8A),
      );
    }
    return const AppGreetingData(
      label: 'Good Night',
      shortLabel: 'Night',
      icon: Icons.nightlight_round,
      accent: Color(0xFF8B7CFF),
    );
  }

  static String roleLabel(String role) {
    const labels = {
      'superadmin': 'Super Admin',
      'super_admin': 'Super Admin',
      'ceo': 'CEO',
      'md': 'MD',
      'hr': 'HR',
      'finance': 'Finance',
      'admin': 'Admin',
      'it': 'IT Team',
      'it_team': 'IT Team',
      'manager': 'Manager',
      'marketing': 'Marketing',
      'tl': 'Team Lead',
      'employee': 'Employee',
    };
    if (labels.containsKey(role)) return labels[role]!;
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class AppGreetingSession {
  static Completer<void>? _dismissed;

  static void begin() {
    _dismissed = Completer<void>();
  }

  static void complete() {
    final completer = _dismissed;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  static Future<void> waitUntilDismissed() =>
      _dismissed?.future ?? Future<void>.value();
}

class LoginGreetingGate extends StatefulWidget {
  final String name;
  final String role;
  final Widget child;

  const LoginGreetingGate({
    super.key,
    required this.name,
    required this.role,
    required this.child,
  });

  @override
  State<LoginGreetingGate> createState() => _LoginGreetingGateState();
}

class _LoginGreetingGateState extends State<LoginGreetingGate> {
  @override
  void initState() {
    super.initState();
    AppGreetingSession.begin();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGreeting());
  }

  Future<void> _showGreeting() async {
    if (!mounted) {
      AppGreetingSession.complete();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _GreetingDialog(name: widget.name, role: widget.role),
    );
    AppGreetingSession.complete();
  }

  @override
  void dispose() {
    AppGreetingSession.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _GreetingDialog extends StatelessWidget {
  final String name;
  final String role;

  const _GreetingDialog({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final greeting = AppGreeting.current();
    final displayName = name.trim().isEmpty ? role : name.trim();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: const Color(0xFF07172A),
            border: Border.all(color: const Color(0xFF183A5A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 138,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ConfettiPainter()),
                    ),
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A2035),
                        border: Border.all(color: greeting.accent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: greeting.accent.withValues(alpha: 0.42),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(greeting.icon, color: greeting.accent, size: 29),
                          const SizedBox(height: 4),
                          Text(
                            greeting.shortLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  children: [
                    Text(
                      greeting.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: greeting.accent,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Welcome back to your ${AppGreeting.roleLabel(role)} dashboard.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF91A8BE),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: greeting.accent,
                          foregroundColor: const Color(0xFF061321),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF00D5FF),
      Color(0xFF22E58B),
      Color(0xFFFFC247),
      Color(0xFFFF5C7A),
      Color(0xFF9D72FF),
    ];
    final random = math.Random(27);
    for (var index = 0; index < 34; index++) {
      final x = random.nextDouble() * size.width;
      final y = 8 + random.nextDouble() * (size.height - 22);
      if ((x - size.width / 2).abs() < 62) continue;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final length = 4 + random.nextDouble() * 5;
      final angle = random.nextDouble() * math.pi;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * length, y + math.sin(angle) * length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
