import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaNotificationsAnnouncementsScreen extends StatelessWidget {
  const SaNotificationsAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const items = [['System Maintenance', 'System will be down on May 25', '10:30 AM'], ['Policy Update', 'New leave policy updated', 'Yesterday'], ['Payroll Processed', 'April payroll has been processed', 'May 19'], ['New Employee Joined', 'Michael Brown joined the team', 'May 18'], ['Meeting Reminder', 'Project review meeting at 10 AM', 'May 18']];
    return SaScreen(
      title: 'Notifications & Announcements',
      child: saList([
        Row(children: [Expanded(child: Text('All', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))), Expanded(child: Text('Announcements', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))), Expanded(child: Text('Alerts', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        ...items.map((n) => SaInfoTile(icon: Icons.notifications_none_rounded, title: n[0], subtitle: n[1], trailing: n[2], color: c.primary)),
        SaCard(child: Center(child: Text('View All', style: TextStyle(color: c.primary, fontWeight: FontWeight.w900)))),
      ]),
    );
  }
}
