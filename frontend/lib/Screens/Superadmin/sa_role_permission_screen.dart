import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaRolePermissionScreen extends StatelessWidget {
  const SaRolePermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Role & Permission',
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final roles = ((snapshot.data?['roles'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return saList([
            Row(
              children: [
                Expanded(child: Text('Roles', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))),
                Expanded(child: Text('Permissions', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 12),
            if (roles.isEmpty)
              _empty(context, c)
            else
              ...roles.map(
                (role) => SaInfoTile(
                  icon: Icons.badge_outlined,
                  title: '${role['name'] ?? 'Role'}',
                  subtitle: '${role['department'] ?? ''}',
                  trailing: '${role['filled_positions'] ?? 0} Users',
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
            'No role permission data found in backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
