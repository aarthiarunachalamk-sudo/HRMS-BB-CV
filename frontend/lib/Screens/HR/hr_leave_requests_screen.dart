import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrLeaveRequestsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;

  const HrLeaveRequestsScreen({
    super.key,
    required this.data,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<HrLeaveRequestsScreen> createState() => _HrLeaveRequestsScreenState();
}

class _HrLeaveRequestsScreenState extends State<HrLeaveRequestsScreen> {
  int? _savingId;
  String _tab = 'pending';

  Future<void> _decide(Map<String, dynamic> leave, String status) async {
    final id = int.tryParse('${leave['id'] ?? ''}');
    if (id == null || _savingId != null) return;
    setState(() => _savingId = id);
    try {
      if (leave['approval_type'] == 'early_checkout') {
        await HrService().updateCheckoutPermission(id, status, widget.userId);
      } else {
        await HrService().updateLeaveRequest(id, status, widget.userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave ${status == 'approved' ? 'approved' : 'rejected'} by HR',
          ),
        ),
      );
      widget.onChanged();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final pending = [
      ...hrList(widget.data, 'leave_requests'),
      ...hrList(widget.data, 'checkout_permissions'),
    ];
    final approved = [
      ...hrList(widget.data, 'leave_requests_approved'),
      ...hrList(widget.data, 'checkout_permissions_approved'),
    ];
    final rejected = [
      ...hrList(widget.data, 'leave_requests_rejected'),
      ...hrList(widget.data, 'checkout_permissions_rejected'),
    ];
    final leaves = switch (_tab) {
      'approved' => approved,
      'rejected' => rejected,
      _ => pending,
    };
    final emptyMessage = switch (_tab) {
      'approved' => 'No approved leave requests yet',
      'rejected' => 'No rejected leave requests yet',
      _ => 'No TL-approved leave requests pending HR review',
    };
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        AppModuleTabs<String>(
          tabs: [
            AppModuleTab('pending', 'Pending (${pending.length})'),
            AppModuleTab('approved', 'Approved (${approved.length})'),
            AppModuleTab('rejected', 'Rejected (${rejected.length})'),
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 12),
        if (leaves.isEmpty)
          HrCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ...leaves.map(
          (leave) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HrCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HrListTile(
                    icon: Icons.person_rounded,
                    title: '${leave['name']}',
                    subtitle: '${leave['subtitle']}',
                    trailing: '${leave['status'] ?? leave['days']}',
                    color: c.primary,
                  ),
                  const SizedBox(height: 8),
                  _Detail(label: 'Reason', value: '${leave['reason'] ?? ''}'),
                  if ('${leave['medical_certificate'] ?? leave['document_name'] ?? ''}'
                      .trim()
                      .isNotEmpty)
                    _Detail(
                      label: 'Medical Certificate',
                      value:
                          '${leave['medical_certificate'] ?? leave['document_name']}',
                    ),
                  if (leave['approval_type'] != 'early_checkout') ...[
                    _Detail(
                      label: 'TL Status',
                      value: '${leave['tl_status'] ?? ''}',
                    ),
                    _Detail(
                      label: 'HR Status',
                      value: '${leave['hr_status'] ?? ''}',
                    ),
                  ] else
                    _Detail(
                      label: 'Requested Check-Out',
                      value: '${leave['requested_check_out'] ?? ''}',
                    ),
                  if (_tab == 'pending') ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final id = int.tryParse('${leave['id'] ?? ''}');
                        final saving = id != null && _savingId == id;
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.success.withAlpha(28),
                                  foregroundColor: c.success,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: c.success.withAlpha(90),
                                  ),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => _decide(leave, 'approved'),
                                child: saving
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: c.success,
                                        ),
                                      )
                                    : const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.danger.withAlpha(24),
                                  foregroundColor: c.danger,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: c.danger.withAlpha(85),
                                  ),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => _decide(leave, 'rejected'),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: TextStyle(
          color: c.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
