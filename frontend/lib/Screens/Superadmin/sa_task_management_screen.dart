import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaTaskManagementScreen extends StatelessWidget {
  const SaTaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const tasks = [['System Update', 'Admin', 'High'], ['Data Migration', 'IT Team', 'High'], ['Employee Onboarding', 'HR Team', 'Medium'], ['Payroll Review', 'Finance Team', 'Medium'], ['Performance Review', 'HR Team', 'Medium'], ['UI/UX Enhancement', 'Design Team', 'Low']];
    return SaScreen(
      title: 'Task Management',
      floatingActionButton: FloatingActionButton(backgroundColor: c.primary, foregroundColor: Colors.white, onPressed: () {}, child: const Icon(Icons.add_rounded)),
      child: saList([
        Row(children: [Expanded(child: Text('Kanban', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))), Expanded(child: Text('List', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))), Expanded(child: Text('Calendar', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.65, children: tasks.map((task) => _Task(task[0], task[1], task[2])).toList()),
        const SizedBox(height: 12),
        SizedBox(height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('Create Task'))),
      ]),
    );
  }
}

class _Task extends StatelessWidget {
  final String title;
  final String team;
  final String priority;
  const _Task(this.title, this.team, this.priority);
  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    final color = priority == 'High' ? c.danger : priority == 'Medium' ? c.warning : c.success;
    return SaCard(color: c.row, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saTitle(context, title, 12), const SizedBox(height: 4), Text(priority, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)), const Spacer(), saMuted(context, team, 11)]));
  }
}
