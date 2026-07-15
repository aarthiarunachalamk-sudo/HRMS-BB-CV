import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoMeetingsScreen extends StatelessWidget {
  final String userId;

  const CeoMeetingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Meetings',
      trailing: const Icon(Icons.more_vert_rounded, color: CeoColors.muted),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CeoColors.purple,
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting creation is not available yet.')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      child: CeoFutureBody(
        future: CeoService().fetchMeetings(userId),
        builder: (data) => pageList([
          title('Today', 16),
          const SizedBox(height: 10),
          ...(data['meetings'] as List? ?? const []).map((item) {
            final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            return CeoListTile(icon: Icons.calendar_month_rounded, titleText: '${map['title']}', subtitle: '${map['time']}  ${map['location']}', color: CeoColors.pink);
          }),
        ]),
      ),
    );
  }
}
