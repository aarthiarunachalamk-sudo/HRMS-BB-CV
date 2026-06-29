import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaLogoutScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const SaLogoutScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 48, backgroundColor: c.danger.withAlpha(28), child: Icon(Icons.logout_rounded, color: c.danger, size: 42)),
          const SizedBox(height: 20),
          Text('Are you sure you want to logout?', textAlign: TextAlign.center, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white), onPressed: onLogout, child: const Text('Logout'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: c.text, side: BorderSide(color: c.border)), onPressed: () => Navigator.maybePop(context), child: const Text('Cancel'))),
          ]),
        ]),
      ),
    );
  }
}
