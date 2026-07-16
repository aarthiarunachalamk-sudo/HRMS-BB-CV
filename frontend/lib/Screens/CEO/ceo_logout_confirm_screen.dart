import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'ceo_widgets.dart';

class CeoLogoutConfirmScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const CeoLogoutConfirmScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final border = ThemeConfig.getCardBorder(context);
    return CeoShell(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.redAccent.withAlpha(
              ThemeConfig.isDark(context) ? 34 : 22,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE1622), foregroundColor: Colors.white), onPressed: onLogout, child: const Text('Logout'))),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: border),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
