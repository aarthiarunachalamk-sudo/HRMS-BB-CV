import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaDepartmentManagementScreen extends StatelessWidget {
  const SaDepartmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    const departments = [['Human Resources', 'Head: Arko Deo - 120 Employees'], ['Finance', 'Head: Sarah Wilson - 95 Employees'], ['Information Technology', 'Head: Michael Brown - 210 Employees'], ['Sales & Marketing', 'Head: Jessica Park - 160 Employees'], ['Production', 'Head: David Lee - 110 Employees'], ['Infrastructure', 'Head: Emily Clark - 60 Employees']];
    return SaScreen(
      title: 'Department Management',
      trailing: Icon(Icons.add_rounded, color: c.primary),
      child: saList([
        saSearch(context, 'Search department...'),
        const SizedBox(height: 12),
        ...departments.map((d) => SaInfoTile(icon: Icons.apartment_rounded, title: d[0], subtitle: d[1], color: c.teal)),
      ]),
    );
  }
}
