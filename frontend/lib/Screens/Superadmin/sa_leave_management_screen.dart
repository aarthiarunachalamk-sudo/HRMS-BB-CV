import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaLeaveManagementScreen extends StatelessWidget {
  const SaLeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Leave Management',
      child: saList([
        Row(children: [Expanded(child: Text('Pending', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))), Expanded(child: Text('Approved', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))), Expanded(child: Text('Rejected', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        SaCard(
          child: Center(child: saMuted(context, 'No leave requests found', 12)),
        ),
      ]),
    );
  }
}
