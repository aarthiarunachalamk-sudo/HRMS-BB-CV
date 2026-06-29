import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrTasksScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrTasksScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Row(children: const [
          _TaskTab(label: 'All', active: true),
          SizedBox(width: 8),
          _TaskTab(label: 'In Progress'),
          SizedBox(width: 8),
          _TaskTab(label: 'Completed'),
        ]),
        const SizedBox(height: 12),
        ...hrList(data, 'tasks').map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(icon: Icons.task_alt_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['status']}', color: c.warning),
            )),
      ],
    );
  }
}

class _TaskTab extends StatelessWidget {
  final String label;
  final bool active;

  const _TaskTab({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Expanded(
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? c.primary.withAlpha(30) : c.row, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
        child: Text(label, style: TextStyle(color: active ? c.primary : c.muted, fontSize: 11, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
