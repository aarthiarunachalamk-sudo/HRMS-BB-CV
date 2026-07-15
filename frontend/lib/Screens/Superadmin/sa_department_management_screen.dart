import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaDepartmentManagementScreen extends StatelessWidget {
  const SaDepartmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Department Management',
      trailing: Icon(Icons.add_rounded, color: c.primary),
      child: saList([
        saSearch(context, 'Search department...'),
        const SizedBox(height: 12),
        SaCard(
          child: Center(
            child: saMuted(context, 'No departments found', 12),
          ),
        ),
      ]),
    );
  }
}
