import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrPerformanceScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrPerformanceScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            HrMetricCard(
              title: 'Pending Reviews',
              value: hrText(data, 'pending_reviews'),
              icon: Icons.pending_actions_rounded,
              color: c.primary,
            ),
            HrMetricCard(
              title: 'Completed',
              value: hrText(data, 'completed_reviews'),
              icon: Icons.check_circle_rounded,
              color: c.success,
            ),
            HrMetricCard(
              title: 'High Performers',
              value: hrText(data, 'high_performers'),
              icon: Icons.trending_up_rounded,
              color: c.purple,
            ),
            HrMetricCard(
              title: 'Low Performers',
              value: hrText(data, 'low_performers'),
              icon: Icons.trending_down_rounded,
              color: c.danger,
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...hrList(data, 'performers').map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.star_rounded,
              title: '${item['name']}',
              subtitle: '${item['subtitle']}',
              color: c.warning,
            ),
          ),
        ),
      ],
    );
  }
}
