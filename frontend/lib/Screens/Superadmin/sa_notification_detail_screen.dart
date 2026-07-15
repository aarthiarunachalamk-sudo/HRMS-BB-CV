import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaNotificationDetailScreen extends StatelessWidget {
  const SaNotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Notifications',
      trailing: Icon(Icons.campaign_outlined, color: c.primary),
      child: saList([
        SaCard(
          child: Center(child: saMuted(context, 'No notifications found', 12)),
        ),
      ]),
    );
  }
}
