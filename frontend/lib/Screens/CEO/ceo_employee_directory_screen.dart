import 'package:flutter/material.dart';

import 'ceo_employee_profile_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoEmployeeDirectoryScreen extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;

  const CeoEmployeeDirectoryScreen({super.key, required this.firstName, required this.email, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Employee Directory',
      trailing: const Icon(Icons.filter_list_rounded, color: CeoColors.muted),
      child: CeoFutureBody(
        future: CeoService().fetchEmployees(userId),
        builder: (data) {
          final employees = [
            {'name': firstName.isEmpty ? 'CEO' : firstName, 'role': 'Chief Executive Officer', 'email': email, 'id': userId},
            ...(data['employees'] as List? ?? const []),
          ];
          return pageList([
            CeoCard(child: Row(children: [const Icon(Icons.search_rounded, color: CeoColors.muted), const SizedBox(width: 10), muted('Search employee...', 12)])),
            ...employees.map((item) {
              final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
              return CeoListTile(
                icon: Icons.person_rounded,
                titleText: '${map['name'] ?? 'Employee'}',
                subtitle: '${map['role'] ?? ''}  ${map['id'] ?? ''}',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CeoEmployeeProfileScreen(employee: map))),
              );
            }),
          ]);
        },
      ),
    );
  }
}
