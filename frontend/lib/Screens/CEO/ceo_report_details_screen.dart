import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoReportDetailsScreen extends StatelessWidget {
  final String userId;

  const CeoReportDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'HR Summary Report',
      child: CeoFutureBody(
        future: CeoService().fetchDashboard(userId),
        builder: (data) => pageList([
          CeoMetricGrid(cards: [
            CeoMetric('Total Employees', '${data['total_employees']}', '', Icons.groups_rounded, CeoColors.cyan),
            const CeoMetric('New Joiners', '28', '', Icons.person_add_alt_1_rounded, CeoColors.green),
            const CeoMetric('Exit Employees', '8', '', Icons.person_remove_rounded, CeoColors.pink),
            CeoMetric('Active Employees', '${data['active_employees']}', '', Icons.verified_user_rounded, CeoColors.purple),
          ]),
          chartCard('Department Wise Employees', const [42, 70, 82, 74, 64], color: CeoColors.gold),
        ]),
      ),
    );
  }
}
