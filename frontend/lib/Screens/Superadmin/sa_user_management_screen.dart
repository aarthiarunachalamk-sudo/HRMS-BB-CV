import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaUserManagementScreen extends StatelessWidget {
  final VoidCallback? onCreateUser;

  const SaUserManagementScreen({super.key, this.onCreateUser});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const users = [
      ['John Doe', 'EMP001 - HR Manager', 'Human Resources', 'Active'],
      ['Sarah Wilson', 'EMP003 - Manager', 'Finance Department', 'Active'],
      ['Michael Brown', 'EMP004 - Admin', 'IT Department', 'Active'],
      ['Jessica Park', 'EMP005 - Team Lead', 'Marketing Department', 'Active'],
      ['David Lee', 'EMP006 - Employee', 'Sales Department', 'Inactive'],
      ['Emily Clark', 'EMP007 - Employee', 'Sales Department', 'Active'],
    ];
    return SaScreen(
      title: 'User Management',
      trailing: Icon(Icons.filter_list_rounded, color: c.text),
      child: saList([
        saSearch(context, 'Search users...'),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: SaCard(color: c.input, padding: const EdgeInsets.all(11), child: saTitle(context, 'All Departments', 12))), const SizedBox(width: 10), Expanded(child: SaCard(color: c.input, padding: const EdgeInsets.all(11), child: saTitle(context, 'All Roles', 12)))]),
        const SizedBox(height: 12),
        ...users.map((u) => SaInfoTile(icon: Icons.person_rounded, title: u[0], subtitle: '${u[1]}  ${u[2]}', trailing: u[3], color: u[3] == 'Active' ? c.success : c.danger)),
        SizedBox(height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), onPressed: onCreateUser, icon: const Icon(Icons.add_rounded), label: const Text('Create User'))),
      ]),
    );
  }
}
