import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoLeaveRequestScreen extends StatefulWidget {
  final String approvalId;
  final String userId;

  const CeoLeaveRequestScreen({
    super.key,
    required this.approvalId,
    this.userId = 'CEO',
  });

  @override
  State<CeoLeaveRequestScreen> createState() => _CeoLeaveRequestScreenState();
}

class _CeoLeaveRequestScreenState extends State<CeoLeaveRequestScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _saving = false;
  Map<String, dynamic> _leave = {};
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _loadLeave();
  }

  Future<Map<String, dynamic>> _loadLeave() async {
    final id = int.tryParse(widget.approvalId);
    if (id == null) return {};
    final data = await CeoService().fetchLeaveDetail(id);
    final leave = data['leave'] is Map
        ? Map<String, dynamic>.from(data['leave'] as Map)
        : <String, dynamic>{};
    _leave = leave;
    _commentsController.text = '${leave['approver_comments'] ?? ''}';
    return leave;
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _update(String status) async {
    if (_saving) return;
    final comments = _commentsController.text.trim();
    if (comments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter approver comments.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Leave'),
        content: Text(
          'Are you sure you want to $status this leave request? This updates the employee record immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  status == 'approved' ? CeoColors.green : Colors.redAccent,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final result = await CeoService().updateApproval(
        widget.approvalId,
        status,
        widget.userId.isEmpty ? 'CEO' : widget.userId,
        comments,
      );
      if (!mounted) return;
      if (result.isEmpty || result['success'] == false) {
        throw Exception(result['message'] ?? 'Leave approval failed');
      }
      final updated = result['leave'] is Map
          ? Map<String, dynamic>.from(result['leave'] as Map)
          : <String, dynamic>{};
      setState(() {
        _saving = false;
        if (updated.isNotEmpty) _leave = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['message'] ?? 'Request $status'}'),
          backgroundColor:
              status == 'approved' ? CeoColors.green : Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update request: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Leave Request',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: CeoColors.cyan),
            );
          }

          final leave = _leave.isNotEmpty ? _leave : (snapshot.data ?? {});
          if (leave.isEmpty) {
            return pageList([
              CeoCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: muted('Leave request not found', 12)),
                ),
              ),
            ]);
          }

          final name = _text(leave, 'name', fallback: 'Employee');
          final employeeId = _text(leave, 'employee_id');
          final status = _text(
            leave,
            'status',
            fallback: _text(leave, 'overall_status', fallback: 'Pending'),
          );
          final overallStatus = _text(
            leave,
            'overall_status',
            fallback: status,
          );
          final pending = overallStatus.toLowerCase() == 'pending';

          return pageList([
            CeoListTile(
              icon: Icons.person_rounded,
              titleText: name,
              subtitle: employeeId.isEmpty ? 'Leave Request' : employeeId,
              color: CeoColors.cyan,
            ),
            CeoCard(
              child: Column(
                children: [
                  _InfoRow('Leave Type', _leaveType(leave)),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('From Date', _dateLabel(leave['from_date'])),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('To Date', _dateLabel(leave['to_date'])),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('Total Days', _text(leave, 'days', fallback: '-')),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('Reason', _text(leave, 'reason', fallback: '-')),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('Applied On', _dateTimeLabel(leave['applied_on'])),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'TL Status',
                    _text(leave, 'tl_status', fallback: '-'),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'TL Reviewed By',
                    _text(leave, 'tl_approved_by', fallback: '-'),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'TL Reviewed At',
                    _dateTimeLabel(leave['tl_reviewed_at']),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'HR Status',
                    _text(leave, 'hr_status', fallback: '-'),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'HR Reviewed By',
                    _text(leave, 'hr_approved_by', fallback: '-'),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'HR Reviewed At',
                    _dateTimeLabel(leave['hr_reviewed_at']),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'Final Reviewed By',
                    _text(leave, 'approved_by', fallback: '-'),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow(
                    'Final Reviewed At',
                    _dateTimeLabel(leave['reviewed_at']),
                  ),
                  const Divider(color: CeoColors.border, height: 1),
                  _InfoRow('Status', status),
                ],
              ),
            ),
            if (pending)
              CeoCard(
                child: TextField(
                  controller: _commentsController,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: ThemeConfig.getTextPrimary(context)),
                  decoration: const InputDecoration(
                    labelText: 'Approver Comments *',
                    hintText: 'Enter comments for this leave request',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              )
            else if (_text(leave, 'approver_comments').isNotEmpty)
              CeoCard(
                child: _InfoRow(
                  'Approver Comments',
                  _text(leave, 'approver_comments'),
                ),
              ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(color: CeoColors.cyan),
                ),
              ),
            if (pending) ...[
              _DecisionButton(
                'Approve',
                CeoColors.green,
                Icons.check_rounded,
                _saving ? null : () => _update('approved'),
              ),
              const SizedBox(height: 10),
              _DecisionButton(
                'Reject',
                Colors.redAccent,
                Icons.close_rounded,
                _saving ? null : () => _update('rejected'),
              ),
            ] else
              _DecisionButton(
                'Back to Approvals',
                CeoColors.cyan,
                Icons.arrow_back_rounded,
                () => Navigator.of(context).pop(),
              ),
          ]);
        },
      ),
    );
  }

  String _leaveType(Map<String, dynamic> leave) {
    final subtitle = _text(leave, 'subtitle');
    if (subtitle.contains(' - ')) return subtitle.split(' - ').first;
    return _text(leave, 'leave_type', fallback: 'Leave');
  }

  String _text(
    Map<String, dynamic> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}');
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _dateTimeLabel(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}');
    if (date == null) return '-';
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${_dateLabel(value)} $hour:$minute $period';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: muted(label, 12)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: TextStyle(
                color: ThemeConfig.getTextPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  const _DecisionButton(this.label, this.color, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isReject = normalized.contains('reject');
    final isApprove = normalized.contains('approve');
    final backgroundColor = isReject
        ? const Color(0xFFFFE4E6)
        : isApprove
            ? const Color(0xFFDCFCE7)
            : color.withAlpha(34);
    final foregroundColor = isReject
        ? const Color(0xFFB42318)
        : isApprove
            ? const Color(0xFF047857)
            : color;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          side: BorderSide(color: foregroundColor.withAlpha(90)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
