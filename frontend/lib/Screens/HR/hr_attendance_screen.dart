import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrAttendanceScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final records = hrList(data, 'attendance_records');
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Text(
          'Team Attendance Overview',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review employee attendance here. To mark your own attendance, switch to the Employee role.',
          style: TextStyle(color: c.muted, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: HrMetricCard(title: 'Present', value: hrText(data, 'present_today'), icon: Icons.verified_rounded, color: c.success)),
          const SizedBox(width: 10),
          Expanded(child: HrMetricCard(title: 'Absent', value: hrText(data, 'absent_today'), icon: Icons.person_off_rounded, color: c.danger)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: HrMetricCard(title: 'Late Entry', value: hrText(data, 'late_entry'), icon: Icons.schedule_rounded, color: c.warning)),
          const SizedBox(width: 10),
          Expanded(child: HrMetricCard(title: 'WFH', value: hrText(data, 'wfh'), icon: Icons.home_work_rounded, color: c.purple)),
        ]),
        const SizedBox(height: 16),
        Text('Recent Records', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...records.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(icon: Icons.access_time_rounded, title: '${item['name']}', subtitle: '${item['subtitle']}', trailing: '${item['time']}', color: c.teal),
            )),
      ],
    );
  }
}
