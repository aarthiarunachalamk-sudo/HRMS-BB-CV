import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaLeaveManagementScreen extends StatelessWidget {
  const SaLeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const leaves = [['John Doe', 'Casual Leave', 'From: May 20, 2024', '3 Days'], ['Sarah Wilson', 'Sick Leave', 'From: May 19, 2024', '1 Day'], ['Michael Brown', 'Annual Leave', 'From: May 18, 2024', '5 Days']];
    return SaScreen(
      title: 'Leave Management',
      child: saList([
        Row(children: [Expanded(child: Text('Pending', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))), Expanded(child: Text('Approved', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))), Expanded(child: Text('Rejected', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        ...leaves.map((leave) => SaCard(color: c.row, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [SaIconBox(icon: Icons.person_rounded, color: c.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, leave[0], 13), Text(leave[1], style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w800)), saMuted(context, leave[2], 11)])), saMuted(context, leave[3], 11)]), const SizedBox(height: 10), Row(children: [const Spacer(), _Button('Approve', c.success), const SizedBox(width: 8), _Button('Reject', c.danger)])]))),
        const SizedBox(height: 10),
        SaCard(child: Center(child: Text('View All Requests', style: TextStyle(color: c.primary, fontWeight: FontWeight.w900)))),
      ]),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final Color color;
  const _Button(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)));
}
