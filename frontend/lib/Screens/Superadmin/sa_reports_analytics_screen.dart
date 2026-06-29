import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaReportsAnalyticsScreen extends StatelessWidget {
  const SaReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const reports = ['Attendance Report', 'Leave Report', 'Employee Report', 'Payroll Report', 'Performance Report', 'Department Report'];
    return SaScreen(
      title: 'Reports & Analytics',
      child: saList([
        ...reports.map((r) => SaInfoTile(icon: Icons.description_outlined, title: r, subtitle: 'View Details', color: c.blue)),
        const SizedBox(height: 8),
        saTitle(context, 'Export Reports', 14),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _Export('PDF', Icons.picture_as_pdf_outlined, c.danger)), const SizedBox(width: 10), Expanded(child: _Export('Excel', Icons.table_chart_outlined, c.success)), const SizedBox(width: 10), Expanded(child: _Export('CSV', Icons.file_copy_outlined, c.blue))]),
      ]),
    );
  }
}

class _Export extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Export(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => SaCard(child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), saTitle(context, label, 11)]));
}
