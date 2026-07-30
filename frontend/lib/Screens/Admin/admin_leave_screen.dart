import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
import 'admin_approve_leave_screen.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

class AdminLeaveScreen extends StatelessWidget {
  final String userId;
  const AdminLeaveScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Leave Requests',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchLeaves(userId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final leaves = _leaveRecords(data);
          return adminPageList([
            // Segment bar
            AdminCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: AppModuleTabs<String>(
                tabs: const [
                  AppModuleTab('pending', 'Pending'),
                  AppModuleTab('approved', 'Approved'),
                  AppModuleTab('rejected', 'Rejected'),
                ],
                selected: 'pending',
                onSelected: (_) {},
              ),
            ),
            const SizedBox(height: 4),
            if (leaves.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No leave requests found', 12, c),
                ),
              ),
            ...leaves.map(
              (l) => _LeaveTile(
                leave: l,
                c: c,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminApproveLeaveScreen(leave: l),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  List<Map<String, String>> _leaveRecords(Map<String, dynamic> data) {
    final raw = data['leaves'] as List? ?? [];
    if (raw.isNotEmpty) {
      return raw
          .map(
            (e) => e is Map
                ? Map<String, String>.from(
                    e.map((k, v) => MapEntry('$k', '$v')),
                  )
                : <String, String>{},
          )
          .toList();
    }
    return const [];
  }
}

class _LeaveTile extends StatelessWidget {
  final Map<String, String> leave;
  final AdminPalette c;
  final VoidCallback onTap;

  const _LeaveTile({required this.leave, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = leave['status'] ?? 'Pending';
    final Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = c.green;
        break;
      case 'Rejected':
        statusColor = c.red;
        break;
      default:
        statusColor = c.orange;
    }

    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmployeeAvatar(
                name: '${leave['name'] ?? ''}',
                photoUrl: '${leave['doc_passport_photo'] ?? ''}',
                radius: 20,
                backgroundColor: c.primary.withOpacity(0.14),
                foregroundColor: c.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    adminTitle(leave['name'] ?? '', 13, c),
                    adminMuted(leave['role'] ?? '', 11, c),
                  ],
                ),
              ),
              AdminBadge(status, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.beach_access_rounded, color: c.orange, size: 14),
              const SizedBox(width: 6),
              adminSmall(leave['type'] ?? '', c.orange),
              const Spacer(),
              adminMuted(
                '${leave['from'] ?? ''} - ${leave['to'] ?? ''}',
                11,
                c,
              ),
            ],
          ),
          const SizedBox(height: 4),
          adminSmall('Duration: ${leave['days'] ?? ''}', c.muted),
        ],
      ),
    );
  }
}
