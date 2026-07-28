import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_approvals_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_service.dart';

import 'ceo_leave_request_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoApprovalsScreen extends StatefulWidget {
  final String userId;

  const CeoApprovalsScreen({super.key, required this.userId});

  @override
  State<CeoApprovalsScreen> createState() => _CeoApprovalsScreenState();
}

class _CeoApprovalsScreenState extends State<CeoApprovalsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return CeoFutureBody(
      future: CeoService().fetchApprovals(widget.userId),
      builder: (data) {
        final approvals =
            data['approvals'] is List ? data['approvals'] as List : const [];
        final history =
            data['history'] is List ? data['history'] as List : const [];
        final items = _showHistory ? history : approvals;
        final emptyText =
            _showHistory ? 'No leave approval history' : 'No pending leave approvals';
        return pageList([
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showHistory = false),
                  child: Center(
                    child: _showHistory
                        ? muted('Pending', 12)
                        : small('Pending', color: CeoColors.pink),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showHistory = true),
                  child: Center(
                    child: _showHistory
                        ? small('History', color: CeoColors.pink)
                        : muted('History', 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            CeoCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: muted(emptyText, 12)),
              ),
            ),
          ...items.map((item) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{};
            return CeoListTile(
              icon: Icons.approval_rounded,
              titleText: '${map['title'] ?? 'Approval'}',
              subtitle: '${map['subtitle'] ?? 'Pending'}',
              color: CeoColors.purple,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                  builder: (_) => const {'daily_report', 'social_media_post', 'leave_request'}.contains(map['approval_type'])
                      ? EmployeeApprovalDetailScreen(
                          item: map,
                          userId: widget.userId,
                          service: EmployeeService(),
                          received: !_showHistory,
                        )
                      : CeoLeaveRequestScreen(
                          approvalId: '${map['id'] ?? ''}',
                          userId: widget.userId,
                        ),
                  ),
                );
                if (mounted) setState(() {});
              },
            );
          }),
        ]);
      },
    );
  }
}
