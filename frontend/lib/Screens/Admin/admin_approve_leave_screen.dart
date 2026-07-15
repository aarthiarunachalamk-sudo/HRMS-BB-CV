import 'package:flutter/material.dart';
import 'admin_palette.dart';
import 'admin_widgets.dart';
import 'admin_success_screen.dart';

class AdminApproveLeaveScreen extends StatelessWidget {
  final Map<String, String> leave;
  const AdminApproveLeaveScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final name = leave['name'] ?? 'Employee';
    final status = leave['status'] ?? 'Pending';
    final isPending = status == 'Pending';

    return AdminShell(
      title: 'Approve Leave',
      child: adminPageList([
        // Employee card
        AdminCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: c.primary.withOpacity(0.14),
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: c.primary, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                adminTitle(name, 16, c),
                adminMuted(leave['role'] ?? '', 12, c),
                const SizedBox(height: 4),
                adminSmall(leave['type'] ?? '', c.orange),
              ]),
            ),
          ]),
        ),

        // Details card
        AdminCard(
          child: Column(children: [
            AdminInfoRow('Leave Type', leave['type'] ?? ''),
            Divider(color: c.border, height: 1),
            AdminInfoRow('From Date', leave['from'] ?? ''),
            Divider(color: c.border, height: 1),
            AdminInfoRow('To Date', leave['to'] ?? ''),
            Divider(color: c.border, height: 1),
            AdminInfoRow('Total Days', leave['days'] ?? ''),
            Divider(color: c.border, height: 1),
            const AdminInfoRow('Reason', 'Personal Work'),
            Divider(color: c.border, height: 1),
            AdminInfoRow('Status', status,
                valueColor: isPending ? c.orange : (status == 'Approved' ? c.green : c.red)),
          ]),
        ),

        const SizedBox(height: 6),

        if (isPending) ...[
          AdminPrimaryButton(
            label: 'Approve Leave',
            onTap: () => _respond(context, 'Approved'),
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.red.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.close_rounded, color: c.red, size: 18),
              label: Text('Reject Leave', style: TextStyle(color: c.red, fontWeight: FontWeight.w700)),
              onPressed: () => _respond(context, 'Rejected'),
            ),
          ),
        ] else
          AdminPrimaryButton(
            label: 'View All Leaves',
            onTap: () => Navigator.of(context).pop(),
          ),
      ]),
    );
  }

  void _respond(BuildContext context, String decision) {
    final name = leave['name'] ?? 'Employee';
    final isApproved = decision == 'Approved';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminSuccessScreen(
        message: isApproved ? 'Leave Approved\nSuccessfully!' : 'Leave Rejected',
        subMessage: isApproved
            ? "$name's leave has been approved."
            : "$name's leave has been rejected.",
        actionLabel: 'View All Leaves',
        onAction: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    ));
  }
}
