import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';

import 'employee_documents_screen.dart';
import 'employee_approvals_screen.dart';
import 'employee_meetings_screen.dart';
import 'employee_models.dart';
import 'employee_notifications_screen.dart';
import 'employee_payslip_screen.dart';
import 'employee_profile_screen.dart';
import 'employee_service.dart';
import 'employee_settings_screen.dart';
import 'employee_shared.dart';
import 'employee_tasks_screen.dart';

class EmployeeMoreScreen extends StatelessWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;
  final VoidCallback onLogout;
  final ValueChanged<Map<String, dynamic>> onNotificationTap;
  final Future<void> Function() onDocumentsChanged;

  const EmployeeMoreScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
    required this.onLogout,
    required this.onNotificationTap,
    required this.onDocumentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'More',
      children: [
        _tile(
          context,
          Icons.approval_rounded,
          'Approvals',
          EmployeeColors.purple,
          EmployeeApprovalsScreen(userId: userId, service: service),
        ),
        _tile(
          context,
          Icons.notifications_active_rounded,
          'Notifications',
          EmployeeColors.red,
          EmployeeNotificationsScreen(
            data: data,
            onNotificationTap: (item) {
              Navigator.of(context).pop();
              onNotificationTap(item);
            },
          ),
        ),
        _tile(
          context,
          Icons.calendar_month_rounded,
          'Meetings',
          EmployeeColors.purple,
          EmployeeMeetingsScreen(userId: userId, data: data, service: service),
        ),
        _tile(
          context,
          Icons.task_alt_rounded,
          'Tasks',
          EmployeeColors.green,
          EmployeeTasksScreen(userId: userId, data: data, service: service),
        ),
        _tile(
          context,
          Icons.payments_rounded,
          'Payslip',
          EmployeeColors.blue,
          EmployeePayslipScreen(userId: userId, data: data, service: service),
        ),
        _tile(
          context,
          Icons.description_rounded,
          'Documents',
          EmployeeColors.gold,
          EmployeeDocumentsScreen(
            userId: userId,
            data: data,
            service: service,
            onUploaded: onDocumentsChanged,
          ),
        ),
        _tile(
          context,
          Icons.person_rounded,
          'Profile',
          EmployeeColors.pink,
          EmployeeProfileScreen(data: data),
        ),
        _tile(
          context,
          Icons.settings_rounded,
          'Settings',
          EmployeeColors.purple,
          EmployeeSettingsScreen(onLogout: onLogout),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    Widget screen,
  ) {
    return EmployeeListTile(
      icon: icon,
      title: title,
      subtitle: 'Open $title',
      trailing: '',
      color: color,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: AppBarLogoTitle(title: title)),
            body: screen,
          ),
        ),
      ),
    );
  }
}
