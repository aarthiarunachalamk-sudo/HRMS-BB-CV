import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaNotificationDetailScreen extends StatelessWidget {
  const SaNotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const items = [['System Alert', 'System health check completed', 'Now'], ['HR Strategy Discussion', 'Upcoming department meeting', 'Upcoming'], ['Payroll Database updated', 'Backup completed successfully', 'Upcoming'], ['New Employee Joined', 'Michael Brown joined the team', 'May 18'], ['Meeting Reminder', 'Project review meeting at 10 AM', 'May 18']];
    return SaScreen(
      title: 'Notifications',
      trailing: Icon(Icons.campaign_outlined, color: c.primary),
      child: saList(items.map((n) => SaInfoTile(icon: Icons.inbox_outlined, title: n[0], subtitle: n[1], trailing: n[2], color: c.blue)).toList()),
    );
  }
}
