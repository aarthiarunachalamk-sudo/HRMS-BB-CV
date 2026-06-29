import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoLeaveRequestScreen extends StatefulWidget {
  final String approvalId;

  const CeoLeaveRequestScreen({super.key, required this.approvalId});

  @override
  State<CeoLeaveRequestScreen> createState() => _CeoLeaveRequestScreenState();
}

class _CeoLeaveRequestScreenState extends State<CeoLeaveRequestScreen> {
  bool _saving = false;

  Future<void> _update(String status) async {
    setState(() => _saving = true);
    final result = await CeoService().updateApproval(widget.approvalId, status);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request ${result['status'] ?? status}'), backgroundColor: CeoColors.green));
  }

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Leave Request',
      child: pageList([
        const CeoListTile(icon: Icons.person_rounded, titleText: 'Aarthi M', subtitle: 'Marketing Executive', color: CeoColors.cyan),
        CeoCard(child: Column(children: const [
          _InfoRow('Leave Type', 'Casual Leave'),
          _InfoRow('From Date', '20 May 2025'),
          _InfoRow('To Date', '21 May 2025'),
          _InfoRow('Total Days', '2 Days'),
          _InfoRow('Reason', 'Personal Work'),
          _InfoRow('Status', 'Pending'),
        ])),
        if (_saving) const Center(child: CircularProgressIndicator(color: CeoColors.cyan)),
        _DecisionButton('Approve', CeoColors.green, Icons.check_rounded, () => _update('approved')),
        _DecisionButton('Reject', Colors.redAccent, Icons.close_rounded, () => _update('rejected')),
      ]),
    );
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
      child: Row(children: [Expanded(child: muted(label, 12)), Flexible(child: title(value, 12))]),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _DecisionButton(this.label, this.color, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
