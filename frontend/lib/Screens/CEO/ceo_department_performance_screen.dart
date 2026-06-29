import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoDepartmentPerformanceScreen extends StatelessWidget {
  final String userId;

  const CeoDepartmentPerformanceScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Department Performance',
      child: CeoFutureBody(
        future: CeoService().fetchDepartmentPerformance(userId),
        builder: (data) => pageList(
          (data['departments'] as List? ?? const []).map((item) {
            final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            return CeoListTile(icon: Icons.stacked_bar_chart_rounded, titleText: '${map['name']}', subtitle: '${map['score']}  ${map['trend']}', color: CeoColors.green);
          }).toList(),
        ),
      ),
    );
  }
}
