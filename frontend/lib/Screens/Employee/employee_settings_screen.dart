import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';

import 'employee_shared.dart';

class EmployeeSettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const EmployeeSettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;
    return EmployeePage(
      title: 'Settings',
      children: [
        EmployeeListTile(icon: Icons.lock_outline_rounded, title: 'Change Password', subtitle: 'Update account credentials', trailing: '', color: EmployeeColors.blue, onTap: () => _showUnavailable(context, 'Change password')),
        EmployeeListTile(icon: Icons.notifications_none_rounded, title: 'Notification Settings', subtitle: 'Manage alerts', trailing: '', color: EmployeeColors.gold, onTap: () => _showUnavailable(context, 'Notification settings')),
        EmployeeListTile(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: isDark ? 'Dark' : 'Light',
          trailing: '',
          color: EmployeeColors.purple,
          onTap: () => MyApp.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
        ),
        EmployeeListTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: 'View policy details', trailing: '', color: EmployeeColors.green, onTap: () => _showUnavailable(context, 'Privacy policy')),
        EmployeeListTile(icon: Icons.logout_rounded, title: 'Logout', subtitle: 'Sign out from the app', trailing: '', color: EmployeeColors.red, onTap: onLogout),
      ],
    );
  }

  void _showUnavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is not available yet.')),
    );
  }
}
