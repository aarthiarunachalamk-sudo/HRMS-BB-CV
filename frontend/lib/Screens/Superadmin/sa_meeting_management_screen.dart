import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaMeetingManagementScreen extends StatelessWidget {
  const SaMeetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const meetings = [['Project Review Meeting', '10:00 AM - 11:00 AM', 'Ongoing'], ['HR Strategy Discussion', '01:15 PM - 02:30 PM', 'Upcoming'], ['Budget Planning Meeting', '04:00 PM - 05:00 PM', 'Upcoming']];
    return SaScreen(
      title: 'Meeting Management',
      child: saList([
        SaCard(child: Column(children: [saTitle(context, 'May 2024', 14), const SizedBox(height: 12), Row(children: List.generate(7, (i) { final active = i == 3; return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: active ? c.primary : c.row, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? c.primary : c.border)), child: Column(children: [Text('${20 + i}', style: TextStyle(color: active ? Colors.white : c.text, fontWeight: FontWeight.w900)), Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i], style: TextStyle(color: active ? Colors.white70 : c.muted, fontSize: 10))]))); }))])),
        const SizedBox(height: 12),
        ...meetings.map((m) => SaInfoTile(icon: Icons.calendar_month_outlined, title: m[0], subtitle: m[1], trailing: m[2], color: m[2] == 'Ongoing' ? c.success : c.primary)),
      ]),
    );
  }
}
