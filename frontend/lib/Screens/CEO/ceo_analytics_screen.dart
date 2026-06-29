import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoAnalyticsScreen extends StatelessWidget {
  final String userId;

  const CeoAnalyticsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoFutureBody(
      future: CeoService().fetchAnalytics(userId),
      builder: (data) => pageList([
        Align(
          alignment: Alignment.centerRight,
          child: CeoCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: muted('This Month', 11)),
        ),
        chartCard('${data['revenue']}', data['bars'] is List ? data['bars'] as List : const [28, 38, 36, 52, 47, 60], subtitle: 'Revenue Overview', trend: '${data['revenue_trend']}', color: CeoColors.green),
        chartCard('Employee Growth', const [42, 68, 82, 54, 78, 72], trend: '${data['employee_growth']}', color: CeoColors.cyan),
        CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title('Department Performance', 15),
          const SizedBox(height: 12),
          _progress('HR', '28%', CeoColors.cyan),
          _progress('Finance', '25%', CeoColors.green),
          _progress('Sales', '20%', CeoColors.gold),
          _progress('IT', '17%', CeoColors.pink),
          _progress('Operations', '10%', CeoColors.purple),
        ])),
      ]),
    );
  }

  Widget _progress(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: muted(label, 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
