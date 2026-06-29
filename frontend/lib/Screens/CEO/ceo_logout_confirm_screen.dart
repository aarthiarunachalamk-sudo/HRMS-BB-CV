import 'package:flutter/material.dart';

import 'ceo_widgets.dart';

class CeoLogoutConfirmScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const CeoLogoutConfirmScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircleAvatar(radius: 48, backgroundColor: CeoColors.cardAlt, child: Icon(Icons.logout_rounded, color: Colors.white, size: 42)),
          const SizedBox(height: 22),
          const Text('Are you sure you want to logout?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE1622), foregroundColor: Colors.white), onPressed: onLogout, child: const Text('Logout'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: CeoColors.border)), onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
          ]),
        ]),
      ),
    );
  }
}
