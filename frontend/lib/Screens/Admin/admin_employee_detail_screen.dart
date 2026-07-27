import 'package:flutter/material.dart';
import 'admin_palette.dart';
import 'admin_widgets.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';

// The employee model is shared via a simple map for decoupling.
class AdminEmployeeDetailScreen extends StatelessWidget {
  final dynamic employee; // accepts _Employee or Map

  const AdminEmployeeDetailScreen({super.key, required this.employee});

  String _get(String key) {
    if (employee is Map) return '${(employee as Map)[key] ?? ''}';
    try {
      return '${(employee as dynamic).toMap()[key] ?? ''}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final name = _get('name').isEmpty ? 'Employee' : _get('name');
    final role = _get('role');
    final email = _get('email');
    final id = _get('id');
    final dept = _get('department');
    final status = _get('status').isEmpty ? 'Active' : _get('status');
    final isActive = status == 'Active';

    return AdminShell(
      title: 'Employee Details',
      child: adminPageList([
        // Avatar + name card
        AdminCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              EmployeeAvatar(
                name: name,
                photoUrl: _get('doc_passport_photo'),
                radius: 38,
                backgroundColor: c.primary.withOpacity(0.15),
                foregroundColor: c.primary,
              ),
              const SizedBox(height: 12),
              adminTitle(name, 18, c),
              const SizedBox(height: 4),
              adminMuted(role, 13, c),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AdminBadge(status, color: isActive ? c.green : c.red),
                  const SizedBox(width: 10),
                  AdminBadge(dept.isEmpty ? 'General' : dept, color: c.primary),
                ],
              ),
            ],
          ),
        ),

        // Segment tabs
        _SegmentRow(c: c),

        const SizedBox(height: 8),
        const AdminSectionTitle('Personal Details'),

        AdminCard(
          child: Column(
            children: [
              AdminInfoRow('Employee ID', id.isEmpty ? 'N/A' : id),
              Divider(color: c.border, height: 1),
              AdminInfoRow('Department', dept.isEmpty ? 'N/A' : dept),
              Divider(color: c.border, height: 1),
              AdminInfoRow('Designation', role.isEmpty ? 'N/A' : role),
              Divider(color: c.border, height: 1),
              AdminInfoRow('Email', email.isEmpty ? 'N/A' : email),
              Divider(color: c.border, height: 1),
              const AdminInfoRow('Phone', '+91 98XXXXXXX0'),
              Divider(color: c.border, height: 1),
              const AdminInfoRow('Date of Joining', '10 Jan 2023'),
              Divider(color: c.border, height: 1),
              const AdminInfoRow('Reporting Manager', 'N/A'),
              Divider(color: c.border, height: 1),
              AdminInfoRow(
                'Status',
                status,
                valueColor: isActive ? c.green : c.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _StatMini('Attendance', '96%', 'This Month', c.green, c),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatMini(
                'Leave Balance',
                '12 Days',
                'Remaining',
                c.orange,
                c,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatMini('Performance', '4.5 ★', 'Rating', c.gold, c),
            ),
          ],
        ),

        const SizedBox(height: 10),
        AdminPrimaryButton(
          label: 'Save Employee',
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.save_rounded,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'View Employee',
              style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final AdminPalette c;
  const _SegmentRow({required this.c});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          _Tab('Attendance', true, c),
          _Tab('Leaves', false, c),
          _Tab('Tasks', false, c),
          _Tab('More', false, c),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminPalette c;
  const _Tab(this.label, this.selected, this.c);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                )
              : null,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : c.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;
  final AdminPalette c;

  const _StatMini(this.label, this.value, this.caption, this.color, this.c);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminMuted(label, 10, c),
          const SizedBox(height: 4),
          adminTitle(value, 16, c),
          const SizedBox(height: 2),
          adminSmall(caption, color),
        ],
      ),
    );
  }
}
