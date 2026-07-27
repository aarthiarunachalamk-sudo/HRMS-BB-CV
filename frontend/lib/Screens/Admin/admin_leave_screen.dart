import 'package:flutter/material.dart';
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
              child: Row(children: [
                _SegTab('Pending', true, c),
                _SegTab('Approved', false, c),
                _SegTab('Rejected', false, c),
              ]),
            ),
            const SizedBox(height: 4),
            if (leaves.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No leave requests found', 12, c),
                ),
              ),
            ...leaves.map((l) => _LeaveTile(
                  leave: l,
                  c: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminApproveLeaveScreen(leave: l),
                    ),
                  ),
                )),
          ]);
        },
      ),
    );
  }

  List<Map<String, String>> _leaveRecords(Map<String, dynamic> data) {
    final raw = data['leaves'] as List? ?? [];
    if (raw.isNotEmpty) {
      return raw.map((e) => e is Map ? Map<String, String>.from(e.map((k, v) => MapEntry('$k', '$v'))) : <String, String>{}).toList();
    }
    return const [];
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminPalette c;
  const _SegTab(this.label, this.selected, this.c);

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
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : c.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
      ),
    );
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: c.primary.withOpacity(0.14),
            child: Text(
              (leave['name'] ?? 'E').substring(0, 1).toUpperCase(),
              style: TextStyle(color: c.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminTitle(leave['name'] ?? '', 13, c),
            adminMuted(leave['role'] ?? '', 11, c),
          ])),
          AdminBadge(status, color: statusColor),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.beach_access_rounded, color: c.orange, size: 14),
          const SizedBox(width: 6),
          adminSmall(leave['type'] ?? '', c.orange),
          const Spacer(),
          adminMuted('${leave['from'] ?? ''} - ${leave['to'] ?? ''}', 11, c),
        ]),
        const SizedBox(height: 4),
        adminSmall('Duration: ${leave['days'] ?? ''}', c.muted),
      ]),
    );
  }
}
