import 'package:flutter/material.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrLeaveRequestsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;

  const HrLeaveRequestsScreen({super.key, required this.data, required this.userId, required this.onChanged});

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
      await HrService().updateLeaveRequest(id, status, widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave ${status == 'approved' ? 'approved' : 'rejected'} by HR')));
      widget.onChanged();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final pending = hrList(widget.data, 'leave_requests');
    final approved = hrList(widget.data, 'leave_requests_approved');
    final rejected = hrList(widget.data, 'leave_requests_rejected');
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Row(children: [
          _Tab(label: 'Pending (${pending.length})', active: _tab == 'pending', onTap: () => setState(() => _tab = 'pending')),
          const SizedBox(width: 8),
          _Tab(label: 'Approved (${approved.length})', active: _tab == 'approved', onTap: () => setState(() => _tab = 'approved')),
          const SizedBox(width: 8),
          _Tab(label: 'Rejected (${rejected.length})', active: _tab == 'rejected', onTap: () => setState(() => _tab = 'rejected')),
        ]),
        const SizedBox(height: 12),
        if (leaves.isEmpty)
          HrCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(child: Text(emptyMessage, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w800))),
            ),
          ),
        ...leaves.map((leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HrCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HrListTile(icon: Icons.person_rounded, title: '${leave['name']}', subtitle: '${leave['subtitle']}', trailing: '${leave['status'] ?? leave['days']}', color: c.primary),
                  const SizedBox(height: 8),
                  _Detail(label: 'Reason', value: '${leave['reason'] ?? ''}'),
                  if ('${leave['medical_certificate'] ?? leave['document_name'] ?? ''}'.trim().isNotEmpty)
                    _Detail(label: 'Medical Certificate', value: '${leave['medical_certificate'] ?? leave['document_name']}'),
                  _Detail(label: 'TL Status', value: '${leave['tl_status'] ?? ''}'),
                  _Detail(label: 'HR Status', value: '${leave['hr_status'] ?? ''}'),
                  if (_tab == 'pending') ...[
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final id = int.tryParse('${leave['id'] ?? ''}');
                      final saving = id != null && _savingId == id;
                      return Row(children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.success.withAlpha(28), foregroundColor: c.success, elevation: 0, side: BorderSide(color: c.success.withAlpha(90))), onPressed: saving ? null : () => _decide(leave, 'approved'), child: saving ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.success)) : const Text('Approve'))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger.withAlpha(24), foregroundColor: c.danger, elevation: 0, side: BorderSide(color: c.danger.withAlpha(85))), onPressed: saving ? null : () => _decide(leave, 'rejected'), child: const Text('Reject'))),
                      ]);
                    }),
                  ],
                ]),
              ),
            )),
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
      child: Text('$label: ${value.trim().isEmpty ? '-' : value}', style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? c.primary.withAlpha(30) : c.row, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
        child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? c.primary : c.muted, fontSize: 11, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
