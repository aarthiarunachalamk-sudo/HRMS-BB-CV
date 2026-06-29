import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaSettingsScreen extends StatelessWidget {
  const SaSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const settings = ['Company Profile', 'Theme Settings', 'Security Settings', 'Backup & Restore', 'Notification Settings', 'App Version 1.0.0'];
    return SaScreen(
      title: 'Settings',
      child: saList(settings.map((s) => SaInfoTile(icon: Icons.settings_outlined, title: s, subtitle: 'Manage $s', color: c.primary)).toList()),
    );
  }
}
