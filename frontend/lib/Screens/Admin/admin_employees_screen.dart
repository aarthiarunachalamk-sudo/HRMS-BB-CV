import 'package:flutter/material.dart';
import 'admin_add_employee_screen.dart';
import 'admin_employee_detail_screen.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';

class AdminEmployeesScreen extends StatelessWidget {
  final String userId;
  const AdminEmployeesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Employees',
      trailing: GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AdminAddEmployeeScreen())),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.person_add_rounded, color: c.primary, size: 18),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchEmployees(userId),
        builder: (context, snapshot) {
          final employees = _employeeRecords(snapshot.data);
          return adminPageList([
            const AdminSearchBox(hint: 'Search employees...'),
            const SizedBox(height: 4),
            AdminCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  adminSmall('All Departments', c.primary),
                  const Spacer(),
                  adminSmall('${employees.length} Employees', c.primary),
                ],
              ),
            ),
            if (employees.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No employees found', 12, c),
                ),
              ),
            ...employees.map((e) => _EmployeeTile(
                  employee: e,
                  c: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AdminEmployeeDetailScreen(employee: e)),
                  ),
                )),
          ]);
        },
      ),
    );
  }

  List<_Employee> _employeeRecords(Map<String, dynamic>? data) {
    final raw = data?['employees'] as List? ?? [];
    if (raw.isNotEmpty) {
      return raw
          .map((e) => _Employee.fromMap(e is Map ? Map<String, dynamic>.from(e) : {}))
          .toList();
    }
    return const [];
  }
}

class _EmployeeTile extends StatelessWidget {
  final _Employee employee;
  final AdminPalette c;
  final VoidCallback onTap;

  const _EmployeeTile({required this.employee, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = employee.status == 'Active';
    return AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          EmployeeAvatar(
            name: employee.name,
            photoUrl: employee.photoUrl,
            radius: 22,
            backgroundColor: c.primary.withOpacity(0.15),
            foregroundColor: c.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminTitle(employee.name, 14, c),
              const SizedBox(height: 2),
              adminMuted('${employee.role}  ·  ${employee.department}', 11, c),
              const SizedBox(height: 2),
              adminSmall(employee.id, c.primary),
            ]),
          ),
          AdminBadge(employee.status, color: isActive ? c.green : c.red),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────
class _Employee {
  final String name;
  final String role;
  final String email;
  final String id;
  final String department;
  final String status;
  final String photoUrl;

  const _Employee(this.name, this.role, this.email, this.id, this.department, this.status, this.photoUrl);

  factory _Employee.fromMap(Map<String, dynamic> m) => _Employee(
        '${m['name'] ?? ''}',
        '${m['role'] ?? ''}',
        '${m['email'] ?? ''}',
        '${m['id'] ?? ''}',
        '${m['department'] ?? ''}',
        '${m['status'] ?? 'Active'}',
        '${m['doc_passport_photo'] ?? ''}',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'email': email,
        'id': id,
        'department': department,
        'status': status,
        'doc_passport_photo': photoUrl,
      };
}
