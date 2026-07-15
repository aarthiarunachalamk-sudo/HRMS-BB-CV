import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaNotificationsAnnouncementsScreen extends StatelessWidget {
  const SaNotificationsAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchNotifications(),
      builder: (context, snapshot) {
        final notifications = _parseNotifications(snapshot.data);
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return SaScreen(
          title: 'Notifications & Announcements',
          child: saList([
            // Segment tabs
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(children: [
                _SegTab('All', true, c),
                _SegTab('Announcements', false, c),
                _SegTab('Alerts', false, c),
              ]),
            ),
            const SizedBox(height: 12),

            if (loading)
              SaCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                ),
              )
            else if (snapshot.hasError || notifications.isEmpty)
              SaCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: saMuted(context, 'No notifications found', 13),
                  ),
                ),
              )
            else
              ...notifications.map((n) {
                final type = n['type'] ?? 'info';
                final Color color;
                final IconData icon;
                switch (type) {
                  case 'success':
                    color = c.success;
                    icon = Icons.check_circle_outline_rounded;
                    break;
                  case 'warning':
                    color = c.warning;
                    icon = Icons.warning_amber_rounded;
                    break;
                  case 'error':
                    color = c.danger;
                    icon = Icons.error_outline_rounded;
                    break;
                  default:
                    color = c.primary;
                    icon = Icons.notifications_none_rounded;
                }
                return SaInfoTile(
                  icon: icon,
                  title: '${n['title'] ?? 'Notification'}',
                  subtitle: '${n['message'] ?? n['subtitle'] ?? ''}',
                  trailing: '${n['time'] ?? n['trailing'] ?? ''}',
                  color: color,
                );
              }),
          ]),
        );
      },
    );
  }

  List<Map<String, dynamic>> _parseNotifications(Map<String, dynamic>? data) {
    if (data == null) return [];
    final raw = data['notifications'];
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList();
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final bool active;
  final SaPalette c;
  const _SegTab(this.label, this.active, this.c);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? c.primary : c.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
