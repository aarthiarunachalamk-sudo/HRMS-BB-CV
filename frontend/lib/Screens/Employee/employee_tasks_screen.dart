import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeTasksScreen extends StatelessWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;
  final VoidCallback? onChanged;

  const EmployeeTasksScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'Tasks Assigned To Me',
      children: [
        if (data.tasks.isEmpty)
          const EmployeeCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                Icon(Icons.assignment_turned_in_outlined, color: EmployeeColors.blue, size: 42),
                SizedBox(height: 12),
                Text('No tasks assigned yet', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Tasks assigned by your Team Lead will appear here.', textAlign: TextAlign.center),
              ]),
            ),
          )
        else
          ...data.tasks.map((item) => EmployeeListTile(
                icon: Icons.task_alt_rounded,
                title: '${item['title'] ?? ''}',
                subtitle: '${_taskProject(item)}  •  Due ${item['due'] ?? '-'}  •  ${item['status'] ?? ''}',
                trailing: '${item['priority'] ?? ''}',
                color: employeeStatusColor('${item['priority'] ?? ''}'),
                onTap: () => _showDetails(context, item),
              )),
      ],
    );
  }

  Future<void> _showDetails(BuildContext context, Map<String, dynamic> task) async {
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    final completed = '${task['status'] ?? ''}'.toLowerCase() == 'completed';
    final priorityColor = employeeStatusColor('${task['priority'] ?? ''}');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
        decoration: BoxDecoration(
          color: ThemeConfig.getCardBg(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: ThemeConfig.getCardBorder(sheetContext)),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: muted.withAlpha(90), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text('${task['title'] ?? 'Task Details'}', style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: priorityColor.withAlpha(28), borderRadius: BorderRadius.circular(20)),
                child: Text('${task['priority'] ?? ''}', style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 16),
            EmployeeInfoRow('Project', _taskProject(task)),
            EmployeeInfoRow('Due Date', '${task['due'] ?? '-'}'),
            EmployeeInfoRow('Status', '${task['status'] ?? 'Pending'}'),
            if ('${task['assigned_by'] ?? ''}'.isNotEmpty) EmployeeInfoRow('Assigned By', '${task['assigned_by']}'),
            const SizedBox(height: 12),
            Text('Task Instructions', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              '${task['description'] ?? ''}'.trim().isEmpty ? 'No additional instructions provided.' : '${task['description']}',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: completed ? null : () => _complete(sheetContext, task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmployeeColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(completed ? Icons.check_circle_rounded : Icons.task_alt_rounded),
                label: Text(completed ? 'Task Completed' : 'Mark as Completed'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _taskProject(Map<String, dynamic> task) {
    final project = '${task['project'] ?? ''}'.trim();
    return project.isEmpty ? 'No project selected' : project;
  }

  Future<void> _complete(BuildContext context, Map<String, dynamic> task) async {
    try {
      final result = await service.completeTask(userId, task['id'] ?? '');
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Task completed'}')));
      onChanged?.call();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
