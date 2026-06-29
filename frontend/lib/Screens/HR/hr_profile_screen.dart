import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrProfileScreen extends StatelessWidget {
  final String email;
  final String name;
  final VoidCallback onLogout;

  const HrProfileScreen({super.key, required this.email, required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        HrCard(child: Column(children: [
          CircleAvatar(radius: 34, backgroundColor: c.primary.withAlpha(30), child: Icon(Icons.person_rounded, color: c.primary, size: 34)),
          const SizedBox(height: 10),
          Text(name.trim().isEmpty ? 'HR Manager' : name, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(email, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 12),
        const HrListTile(icon: Icons.person_outline_rounded, title: 'Personal Information', subtitle: 'Profile and contact details'),
        const SizedBox(height: 10),
        const HrListTile(icon: Icons.lock_outline_rounded, title: 'Change Password', subtitle: 'Security settings'),
        const SizedBox(height: 10),
        const HrListTile(icon: Icons.notifications_none_rounded, title: 'Notification Settings', subtitle: 'Alerts and reminders'),
        const SizedBox(height: 10),
        HrListTile(icon: Icons.logout_rounded, title: 'Logout', subtitle: 'End current session', color: c.danger),
        const SizedBox(height: 8),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white), onPressed: onLogout, child: const Text('Logout')),
      ],
    );
  }
}
