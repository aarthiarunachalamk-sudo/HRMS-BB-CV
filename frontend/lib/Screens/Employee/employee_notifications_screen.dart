import 'package:flutter/material.dart';

import 'employee_models.dart';
import 'employee_shared.dart';

class EmployeeNotificationsScreen extends StatelessWidget {
  final EmployeeDashboardData data;
  final ValueChanged<Map<String, dynamic>>? onNotificationTap;

  const EmployeeNotificationsScreen({
    super.key,
    required this.data,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'Notifications',
      action: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications are already visible.')),
          );
        },
        child: const Text('Mark All'),
      ),
      children: [
        if (data.notifications.isEmpty)
          const EmployeeCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ...data.notifications.map(
          (item) => EmployeeListTile(
            icon: Icons.notifications_active_rounded,
            title: '${item['title'] ?? ''}',
            subtitle: '${item['message'] ?? ''}',
            trailing: '${item['time'] ?? ''}',
            color: employeeStatusColor('${item['type'] ?? ''}'),
            onTap: onNotificationTap == null
                ? null
                : () => onNotificationTap!(item),
          ),
        ),
      ],
    );
  }
}
