import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/user_notification_settings_screen.dart';

import 'ceo_widgets.dart';

class CeoProfileSettingsScreen extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;
  final VoidCallback onLogout;

  const CeoProfileSettingsScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.userId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Profile & Settings',
      child: pageList([
        CeoListTile(
          icon: Icons.account_circle_rounded,
          titleText: firstName.isEmpty ? 'CEO' : firstName,
          subtitle: userId.isEmpty ? email : userId,
          color: CeoColors.cyan,
        ),
        CeoListTile(
          icon: Icons.person_outline_rounded,
          titleText: 'Personal Information',
          subtitle: 'Profile details',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserPersonalInformationScreen(userId: userId),
            ),
          ),
        ),
        const CeoListTile(
          icon: Icons.business_center_outlined,
          titleText: 'Organization Info',
          subtitle: 'Company and role',
        ),
        const CeoListTile(
          icon: Icons.lock_outline_rounded,
          titleText: 'Change Password',
          subtitle: 'Security',
        ),
        const CeoListTile(
          icon: Icons.notifications_none_rounded,
          titleText: 'Notification Settings',
          subtitle: 'Alerts and updates',
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE1622),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onLogout,
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}
