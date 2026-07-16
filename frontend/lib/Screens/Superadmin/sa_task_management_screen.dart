import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaTaskManagementScreen extends StatelessWidget {
  const SaTaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Task Management',
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final tasks = ((snapshot.data?['tasks'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return saList([
            Row(
              children: [
                Expanded(child: Text('Kanban', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))),
                Expanded(child: Text('List', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))),
                Expanded(child: Text('Calendar', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              _empty(context, c)
            else
              ...tasks.map(
                (task) => SaInfoTile(
                  icon: Icons.task_alt_rounded,
                  title: '${task['title'] ?? 'Task'}',
                  subtitle: '${task['assignee'] ?? ''} • ${task['project'] ?? ''}',
                  trailing: '${task['status'] ?? ''}',
                  color: _priorityColor(c, '${task['priority'] ?? ''}'),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Color _priorityColor(SaPalette c, String priority) {
    if (priority.toLowerCase() == 'high' || priority.toLowerCase() == 'urgent') return c.danger;
    if (priority.toLowerCase() == 'medium') return c.warning;
    return c.success;
  }

  Widget _empty(BuildContext context, SaPalette c) => SaCard(
        child: Center(
          child: Text(
            'No task data found in backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
