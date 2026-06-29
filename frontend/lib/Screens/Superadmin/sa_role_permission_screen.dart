import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaRolePermissionScreen extends StatelessWidget {
  const SaRolePermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const roles = [['Super Admin', '1 User'], ['MD', '2 Users'], ['Director', '3 Users'], ['CEO', '1 User'], ['HR Manager', '2 Users'], ['Finance Manager', '2 Users'], ['IT Manager', '2 Users'], ['Admin', '4 Users'], ['Manager', '10 Users'], ['Team Lead', '24 Users'], ['Employee', '1,156 Users']];
    return SaScreen(
      title: 'Role & Permission',
      child: saList([
        Row(children: [Expanded(child: Text('Roles', textAlign: TextAlign.center, style: TextStyle(color: c.primary, fontWeight: FontWeight.w900))), Expanded(child: Text('Permissions', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        ...roles.map((r) => SaInfoTile(icon: Icons.badge_outlined, title: r[0], subtitle: 'Role access summary', trailing: r[1], color: c.primary)),
      ]),
    );
  }
}
