import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
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
        AppModuleTabs<String>(
          tabs: const [
            AppModuleTab('all', 'All'),
            AppModuleTab('in_progress', 'In Progress'),
            AppModuleTab('completed', 'Completed'),
          ],
          selected: 'all',
          onSelected: (_) {},
        ),
        const SizedBox(height: 12),
        ...hrList(data, 'tasks').map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.task_alt_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['status']}',
              color: c.warning,
            ),
          ),
        ),
      ],
    );
  }
}
