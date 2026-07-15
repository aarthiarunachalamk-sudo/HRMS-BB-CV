import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'employee_models.dart';
import 'employee_shared.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final EmployeeDashboardData data;

  const EmployeeProfileScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final name = '${profile['name'] ?? 'Employee'}';
    final designation = '${profile['designation'] ?? 'Employee'}';
    final department = '${profile['department'] ?? ''}'.trim();
    return EmployeePage(
      title: 'Profile',
      children: [
        EmployeeCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: EmployeeColors.blue,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'E', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text(name, style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(designation),
              if (department.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  department,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EmployeeColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        EmployeeCard(
          child: Column(
            children: [
              EmployeeInfoRow('Employee ID', '${profile['employee_id'] ?? ''}'),
              EmployeeInfoRow('Email', '${profile['email'] ?? ''}'),
              EmployeeInfoRow('Department', '${profile['department'] ?? ''}'),
              EmployeeInfoRow('Date of Joining', '${profile['date_of_joining'] ?? ''}'),
              EmployeeInfoRow('Reporting TL', '${profile['reporting_tl'] ?? ''}'),
              EmployeeInfoRow('Work Mode', '${profile['work_location'] ?? ''}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing is not available yet.')),
              );
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }
}
