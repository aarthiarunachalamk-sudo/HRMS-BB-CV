import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/MD/md_dashboard.dart';

/// Dedicated Executive Director dashboard entry point with the shared
/// Client Visits tab and Quick Action in read-only monitoring mode.
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
    return MdDashboard.executiveDirector(
      email: email,
      firstName: firstName,
      userId: userId,
    );
  }
}
