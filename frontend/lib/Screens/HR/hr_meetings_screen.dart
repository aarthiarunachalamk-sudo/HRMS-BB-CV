import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrMeetingsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrMeetingsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final meetingNotifications = hrList(data, 'notifications').where((item) {
      final module = '${item['module'] ?? ''}'.toLowerCase();
      final text =
          '${item['title'] ?? ''} ${item['subtitle'] ?? item['message'] ?? ''}'
              .toLowerCase();
      return module == 'meeting' ||
          module == 'meetings' ||
          text.contains('meeting');
    });
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        HrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data['calendar_month'] ?? ''}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final active = '${data['calendar_day'] ?? ''}' == '$day';
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: active ? c.primary : c.row,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: active ? Colors.white : c.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (meetingNotifications.isNotEmpty) ...[
          Text(
            'TL Meeting Notifications',
            style: TextStyle(
              color: c.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...meetingNotifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(
                icon: Icons.notifications_active_rounded,
                title: '${item['title']}',
                subtitle: '${item['subtitle']}',
                trailing: '${item['time']}',
                color: c.danger,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        ...hrList(data, 'meetings').map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.event_note_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['time']}',
              color: c.success,
            ),
          ),
        ),
      ],
    );
  }
}
