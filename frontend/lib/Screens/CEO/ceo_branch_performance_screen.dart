import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoBranchPerformanceScreen extends StatelessWidget {
  final String userId;

  const CeoBranchPerformanceScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Branch Performance',
      child: CeoFutureBody(
        future: CeoService().fetchBranchPerformance(userId),
        builder: (data) => pageList(
          (data['branches'] as List? ?? const []).map((item) {
            final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            return CeoListTile(icon: Icons.business_rounded, titleText: '${map['name']}', subtitle: '${map['score']}  ${map['trend']}  ${map['revenue']}', color: CeoColors.gold);
          }).toList(),
        ),
      ),
    );
  }
}
