import 'package:flutter/material.dart';

import 'ceo_leave_request_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoApprovalsScreen extends StatelessWidget {
  final String userId;

  const CeoApprovalsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoFutureBody(
      future: CeoService().fetchApprovals(userId),
      builder: (data) {
        final approvals = data['approvals'] is List ? data['approvals'] as List : const [];
        return pageList([
          Row(children: [Expanded(child: small('Pending', color: CeoColors.pink)), Expanded(child: muted('History', 12))]),
          const SizedBox(height: 16),
          ...approvals.map((item) {
            final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            return CeoListTile(
              icon: Icons.approval_rounded,
              titleText: '${map['title'] ?? 'Approval'}',
              subtitle: '${map['subtitle'] ?? 'Pending'}',
              color: CeoColors.purple,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CeoLeaveRequestScreen(approvalId: '${map['id'] ?? ''}'))),
            );
          }),
        ]);
      },
    );
  }
}
