import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrScheduleInterviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrScheduleInterviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final candidate = hrList(data, 'candidates').isEmpty ? <String, dynamic>{} : hrList(data, 'candidates').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        HrListTile(icon: Icons.person_rounded, title: '${candidate['name'] ?? 'Candidate'}', subtitle: '${candidate['role'] ?? ''}', color: c.primary),
        const SizedBox(height: 12),
        HrCard(child: Column(children: [
          _Field(label: 'Date', value: '${data['interview_date'] ?? ''}', icon: Icons.calendar_today_rounded),
          _Field(label: 'Time', value: '${data['interview_time'] ?? ''}', icon: Icons.schedule_rounded),
          _Field(label: 'Mode', value: '${data['interview_mode'] ?? ''}', icon: Icons.video_call_rounded),
          _Field(label: 'Location / Link', value: '${data['interview_link'] ?? ''}', icon: Icons.link_rounded),
        ])),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Interview scheduling is not available yet.')),
            );
          },
          child: const Text('Schedule Interview'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Field({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: c.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
          Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)),
        ])),
      ]),
    );
  }
}
