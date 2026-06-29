import 'package:flutter/material.dart';

import 'ceo_widgets.dart';

class CeoMoreScreen extends StatelessWidget {
  final String firstName;
  final String email;
  final VoidCallback onProfile;
  final VoidCallback onBudget;
  final VoidCallback onDirectory;
  final VoidCallback onNotifications;
  final VoidCallback onMeetings;
  final VoidCallback onDepartment;
  final VoidCallback onBranch;
  final VoidCallback onCreateMember;
  final VoidCallback onLogout;

  const CeoMoreScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.onProfile,
    required this.onBudget,
    required this.onDirectory,
    required this.onNotifications,
    required this.onMeetings,
    required this.onDepartment,
    required this.onBranch,
    required this.onCreateMember,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return pageList([
      CeoListTile(icon: Icons.account_circle_rounded, titleText: firstName.isEmpty ? 'CEO' : firstName, subtitle: email, color: CeoColors.cyan),
      CeoListTile(icon: Icons.account_circle_rounded, titleText: 'Profile & Settings', subtitle: 'Account, security, preferences', onTap: onProfile),
      CeoListTile(icon: Icons.pie_chart_rounded, titleText: 'Budget Overview', subtitle: 'Budget, spent, remaining', onTap: onBudget),
      CeoListTile(icon: Icons.groups_rounded, titleText: 'Employee Directory', subtitle: 'Leadership and teams', onTap: onDirectory),
      CeoListTile(icon: Icons.notifications_rounded, titleText: 'Notifications', subtitle: 'Alerts and updates', onTap: onNotifications),
      CeoListTile(icon: Icons.calendar_month_rounded, titleText: 'Meetings', subtitle: 'Board and department reviews', onTap: onMeetings),
      CeoListTile(icon: Icons.stacked_bar_chart_rounded, titleText: 'Department Performance', subtitle: 'Team performance snapshot', onTap: onDepartment),
      CeoListTile(icon: Icons.business_rounded, titleText: 'Branch Performance', subtitle: 'Location performance snapshot', onTap: onBranch),
      CeoListTile(icon: Icons.person_add_rounded, titleText: 'Create Team Member', subtitle: 'Add HR, Finance, IT, etc.', onTap: onCreateMember),
      CeoListTile(icon: Icons.logout_rounded, titleText: 'Logout', subtitle: 'End current session', color: Colors.redAccent, onTap: onLogout),
    ]);
  }
}
