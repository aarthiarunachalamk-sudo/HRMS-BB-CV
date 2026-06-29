import 'package:flutter/material.dart';
import 'theme_config.dart';

class BitByteLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool compact;

  const BitByteLogo({
    super.key,
    this.size = 140.0,
    this.showSubtitle = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Image.asset(
        'assets/logo.png',
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if image fails to load
          return const Icon(Icons.business_center, color: Color(0xFF007BFF), size: 28);
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Renders the official logo image
        Image.asset(
          'assets/logo.png',
          width: size * 1.5,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback icon row if image is missing
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.token_rounded, color: Color(0xFF0072FF), size: 36),
                SizedBox(width: 8),
                Text(
                  'BitByte',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            );
          },
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 16),
          // HRMS Text
          Text(
            'HRMS',
            style: TextStyle(
              fontSize: size * 0.16,
              fontWeight: FontWeight.w900,
              color: ThemeConfig.getTextPrimary(context),
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 8),
          // Full Subtitle
          Text(
            'Human Resource\nManagement System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.w500,
              color: ThemeConfig.getTextSecondary(context),
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
