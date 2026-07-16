import 'package:flutter/material.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

/// Admin meetings: view-only list + calendar strip.
/// Meeting creation is handled by MD / TL.
class AdminMeetingsScreen extends StatelessWidget {
  final String userId;
  const AdminMeetingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Meetings',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchMeetings(userId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final meetings = _meetingRecords(data);
          return adminPageList([
            adminTitle(_monthLabel(), 16, c),
            const SizedBox(height: 10),
            _AdminCalendarStrip(c: c),
            const SizedBox(height: 18),
            const AdminSectionTitle('Today\'s Meetings'),
            if (meetings.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No meetings scheduled today', 13, c),
                ),
              )
            else
              ...meetings.map((m) => _MeetingTile(meeting: m, c: c)),
          ]);
        },
      ),
    );
  }

  String _monthLabel() {
    final now = DateTime.now();
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month]} ${now.year}';
  }

  List<Map<String, String>> _meetingRecords(Map<String, dynamic> data) {
    final raw = data['meetings'] as List? ?? [];
    if (raw.isEmpty) return const [];
    return raw
        .map((e) => e is Map
            ? Map<String, String>.from(
                e.map((k, v) => MapEntry('$k', '$v')),
              )
            : <String, String>{})
        .toList();
  }
}

class _AdminCalendarStrip extends StatelessWidget {
  final AdminPalette c;
  const _AdminCalendarStrip({required this.c});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 3 - i)));
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 62,
      child: Row(
        children: days.map((d) {
          final isToday =
              d.day == now.day && d.month == now.month && d.year == now.year;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isToday ? c.primary : c.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isToday ? c.primary : c.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdays[d.weekday - 1],
                    style: TextStyle(
                      color: isToday ? Colors.white : c.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      color: isToday ? Colors.white : c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final Map<String, String> meeting;
  final AdminPalette c;
  const _MeetingTile({required this.meeting, required this.c});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.event_rounded, color: c.purple, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminTitle(meeting['title'] ?? '', 13, c),
            const SizedBox(height: 3),
            adminMuted(meeting['time'] ?? '', 11, c),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_rounded, color: c.muted, size: 12),
              const SizedBox(width: 4),
              Expanded(child: adminMuted(meeting['location'] ?? '', 11, c)),
              Icon(Icons.people_rounded, color: c.muted, size: 12),
              const SizedBox(width: 4),
              adminMuted('${meeting['participants'] ?? '0'}', 11, c),
            ]),
          ]),
        ),
      ]),
    );
  }
}
