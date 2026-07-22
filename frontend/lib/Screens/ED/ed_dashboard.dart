import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/MD/md_dashboard.dart';

/// Dedicated Executive Director dashboard entry point.
class ExecutiveDirectorDashboard extends StatelessWidget {
  final String email;
  final String firstName;
  final String userId;

  const ExecutiveDirectorDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MdDashboard(
      email: email,
      firstName: firstName,
      userId: userId,
      role: 'director',
    );
  }
}
