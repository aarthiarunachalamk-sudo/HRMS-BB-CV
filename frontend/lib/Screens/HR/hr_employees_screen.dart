import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrEmployeesScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrEmployeesScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final employees = hrList(data, 'employees');
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        _Search(hint: 'Search employee...'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: ['All', 'HR', 'IT', 'Finance', 'Sales'].map((label) => Chip(label: Text(label), backgroundColor: label == 'All' ? c.primary.withAlpha(35) : c.row, labelStyle: TextStyle(color: label == 'All' ? c.primary : c.text, fontWeight: FontWeight.w800))).toList()),
        const SizedBox(height: 10),
        ...employees.map((employee) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(
                icon: Icons.person_rounded,
                title: '${employee['name']}',
                subtitle: '${employee['subtitle']}',
                trailing: '${employee['trailing']}',
                color: c.primary,
              ),
            )),
      ],
    );
  }
}

class _Search extends StatelessWidget {
  final String hint;

  const _Search({required this.hint});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return HrCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [Icon(Icons.search_rounded, color: c.muted, size: 18), const SizedBox(width: 8), Text(hint, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700))]),
    );
  }
}
