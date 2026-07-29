import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
import 'hr_shared.dart';

class HrTasksScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const HrTasksScreen({super.key, required this.data});

  @override
  State<HrTasksScreen> createState() => _HrTasksScreenState();
}

class _HrTasksScreenState extends State<HrTasksScreen> {
  String _selected = 'all';

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final tasks = hrList(widget.data, 'tasks');
    final filtered = tasks.where((item) {
      final status = '${item['status'] ?? ''}'.trim().toLowerCase();
      if (_selected == 'in_progress') return status == 'in_progress';
      if (_selected == 'completed') return status == 'completed';
      return true;
    }).toList();
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        AppModuleTabs<String>(
          tabs: const [
            AppModuleTab('all', 'All'),
            AppModuleTab('in_progress', 'In Progress'),
            AppModuleTab('completed', 'Completed'),
          ],
          selected: _selected,
          onSelected: (value) => setState(() => _selected = value),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          HrCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    tasks.isEmpty
                        ? Icons.task_alt_rounded
                        : Icons.filter_alt_off_rounded,
                    color: c.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tasks.isEmpty ? 'No tasks available' : 'No matching tasks',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tasks.isEmpty
                        ? 'Tasks assigned by Admin or Team Lead will appear here.'
                        : 'Select another status to view available tasks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ...filtered.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.task_alt_rounded,
              title: '${item['title']}',
              subtitle:
                  '${item['assignee'] ?? 'Unassigned'} • ${item['subtitle'] ?? 'No description'}',
              trailing: '${item['status_label'] ?? item['status'] ?? ''}',
              color: c.warning,
            ),
          ),
        ),
      ],
    );
  }
}
