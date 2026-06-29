import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaProfileScreen extends StatelessWidget {
  final String email;
  final VoidCallback? onLogout;

  const SaProfileScreen({super.key, required this.email, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Profile',
      child: saList([
        SaCard(child: Row(children: [CircleAvatar(radius: 26, backgroundColor: c.primary.withAlpha(32), child: Icon(Icons.admin_panel_settings_rounded, color: c.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, 'Super Admin', 14), saMuted(context, email, 11)]))])),
        const SizedBox(height: 12),
        SaInfoTile(icon: Icons.badge_outlined, title: 'Employee ID', subtitle: 'EMP001', color: c.primary),
        SaInfoTile(icon: Icons.work_outline_rounded, title: 'Designation', subtitle: 'Super Administrator', color: c.blue),
        SaInfoTile(icon: Icons.apartment_outlined, title: 'Department', subtitle: 'Management', color: c.teal),
        SaInfoTile(icon: Icons.edit_outlined, title: 'Edit Profile', subtitle: 'Update profile information', color: c.primary),
        SaInfoTile(icon: Icons.lock_outline_rounded, title: 'Change Password', subtitle: 'Security settings', color: c.purple),
        SizedBox(height: 48, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: c.danger, side: BorderSide(color: c.danger.withAlpha(120))), onPressed: onLogout, icon: const Icon(Icons.logout_rounded), label: const Text('Logout'))),
      ]),
    );
  }
}
