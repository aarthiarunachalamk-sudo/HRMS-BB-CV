import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrRecruitmentScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onPipeline;
  final VoidCallback onSchedule;

  const HrRecruitmentScreen({
    super.key,
    required this.data,
    required this.onPipeline,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final openings = hrList(data, 'open_positions');
    final candidates = hrList(data, 'candidates');
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
              title: 'Open Positions',
              value: hrText(data, 'open_positions_count'),
              icon: Icons.work_rounded,
              color: c.primary,
            ),
            HrMetricCard(
              title: 'Candidates',
              value: hrText(data, 'candidates_count'),
              icon: Icons.groups_rounded,
              color: c.success,
            ),
            HrMetricCard(
              title: 'Interviews',
              value: hrText(data, 'interviews_count'),
              icon: Icons.video_call_rounded,
              color: c.warning,
            ),
            HrMetricCard(
              title: 'Offers',
              value: hrText(data, 'offers_count'),
              icon: Icons.workspace_premium_rounded,
              color: c.purple,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPipeline,
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text('Pipeline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Schedule'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Open Positions',
          style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (openings.isEmpty)
          HrCard(
            child: Text(
              'No open positions. New job openings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ),
        ...openings.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.business_center_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['count']}',
              color: c.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Recent Candidates',
          style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (candidates.isEmpty)
          HrCard(
            child: Text(
              'No candidate applications received yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ),
        ...candidates.take(5).map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.person_search_rounded,
              title: '${candidate['name'] ?? 'Candidate'}',
              subtitle:
                  '${candidate['job_title'] ?? 'General Application'} • ${candidate['stage_label'] ?? candidate['stage'] ?? ''}',
              trailing: '${candidate['experience'] ?? ''}',
              color: c.success,
              onTap: onPipeline,
            ),
          ),
        ),
      ],
    );
  }
}
