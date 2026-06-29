import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrPayrollScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrPayrollScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        HrCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['payroll_month'] ?? ''}', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Row(label: 'Total Employees', value: hrText(data, 'total_employees')),
          _Row(label: 'Processed', value: hrText(data, 'payroll_processed')),
          _Row(label: 'Pending', value: hrText(data, 'payroll_pending')),
        ])),
        const SizedBox(height: 12),
        ...hrList(data, 'payroll_items').map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(icon: Icons.payments_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', color: c.purple),
            )),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700))),
        Text(value, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
