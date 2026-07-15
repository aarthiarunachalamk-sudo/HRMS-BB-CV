import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaUserManagementScreen extends StatelessWidget {
  final VoidCallback? onCreateUser;

  const SaUserManagementScreen({super.key, this.onCreateUser});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SaScreen(
            title: 'User Management',
            child: saList([
              SaCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: saMuted(context, 'Backend data unavailable', 13),
                  ),
                ),
              ),
            ]),
          );
        }
        if (!snapshot.hasData) {
          return SaScreen(
            title: 'User Management',
            child: Center(child: CircularProgressIndicator(color: c.primary)),
          );
        }

        final rawUsers = snapshot.data!['users'];
        final users = rawUsers is List
            ? rawUsers.map((item) {
                final u = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                return _UserRow(
                  name: '${u['name'] ?? ''}',
                  subtitle: '${u['subtitle'] ?? ''}  ${u['trailing'] ?? ''}',
                  detail: '${u['detail'] ?? ''}',
                  status: '${u['status'] ?? 'Active'}',
                );
              }).toList()
            : <_UserRow>[];

        return SaScreen(
          title: 'User Management',
          trailing: Icon(Icons.filter_list_rounded, color: c.text),
          child: saList([
            saSearch(context, 'Search users...'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: SaCard(
                  color: c.input,
                  padding: const EdgeInsets.all(11),
                  child: saTitle(context, 'All Departments', 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SaCard(
                  color: c.input,
                  padding: const EdgeInsets.all(11),
                  child: saTitle(context, 'All Roles', 12),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (users.isEmpty)
              SaCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: saMuted(context, 'No users found', 13)),
                ),
              )
            else
              ...users.map(
                (u) => SaInfoTile(
                  icon: Icons.person_rounded,
                  title: u.name.isEmpty ? 'User' : u.name,
                  subtitle: '${u.subtitle}  ${u.detail}'.trim(),
                  trailing: u.status,
                  color: u.status.toLowerCase() == 'active'
                      ? c.success
                      : c.danger,
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onCreateUser,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create User',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _UserRow {
  final String name;
  final String subtitle;
  final String detail;
  final String status;
  const _UserRow({
    required this.name,
    required this.subtitle,
    required this.detail,
    required this.status,
  });
}
