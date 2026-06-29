import 'package:flutter/material.dart';

import 'ceo_widgets.dart';

class CeoEmployeeProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const CeoEmployeeProfileScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['name'] ?? 'Employee'}';
    return CeoShell(
      title: name,
      child: pageList([
        CeoListTile(icon: Icons.badge_rounded, titleText: name, subtitle: '${employee['role'] ?? ''}', color: CeoColors.cyan),
        CeoCard(child: Column(children: [
          _row('Employee ID', '${employee['id'] ?? 'EMP1021'}'),
          _row('Email', '${employee['email'] ?? '-'}'),
          _row('Phone', '+91 98765 43210'),
          _row('Department', '${employee['department'] ?? 'Marketing'}'),
          _row('Date of Joining', '${employee['joining_date'] ?? '10 Jan 2023'}'),
        ])),
        CeoMetricGrid(cards: const [
          CeoMetric('Attendance', '95%', '', Icons.calendar_month_rounded, CeoColors.green),
          CeoMetric('Leave Balance', '12 Days', '', Icons.beach_access_rounded, CeoColors.cyan),
          CeoMetric('Performance', '4.5', '', Icons.star_rounded, CeoColors.gold),
          CeoMetric('Status', 'Active', '', Icons.verified_rounded, CeoColors.purple),
        ]),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [Expanded(child: muted(label, 12)), Flexible(child: title(value, 12))]),
    );
  }
}
