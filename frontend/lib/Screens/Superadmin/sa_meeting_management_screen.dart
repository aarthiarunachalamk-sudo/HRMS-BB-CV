import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaMeetingManagementScreen extends StatelessWidget {
  const SaMeetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Meeting Management',
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final meetings = ((snapshot.data?['meetings'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return saList([
            if (meetings.isEmpty)
              _empty(context, c)
            else
              ...meetings.map(
                (meeting) => SaInfoTile(
                  icon: Icons.calendar_month_outlined,
                  title: '${meeting['title'] ?? 'Meeting'}',
                  subtitle: '${meeting['date'] ?? ''} ${meeting['time'] ?? ''}',
                  trailing: '${meeting['status'] ?? ''}',
                  color: c.primary,
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context, SaPalette c) => SaCard(
        child: Center(
          child: Text(
            'No meeting data found in backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
