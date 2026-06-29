import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoNotificationsScreen extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;

  const CeoNotificationsScreen({super.key, required this.firstName, required this.email, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Notifications',
      trailing: const Icon(Icons.more_vert_rounded, color: CeoColors.muted),
      child: CeoFutureBody(
        future: CeoService().fetchNotifications(userId),
        builder: (data) => pageList([
          CeoListTile(icon: Icons.account_circle_rounded, titleText: 'Logged in user', subtitle: firstName.isEmpty ? email : firstName, color: CeoColors.cyan),
          ...(data['notifications'] as List? ?? const []).map((item) {
            final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            return CeoListTile(icon: Icons.notifications_rounded, titleText: '${map['title']}', subtitle: '${map['subtitle']}  ${map['time']}', color: CeoColors.purple);
          }),
        ]),
      ),
    );
  }
}
