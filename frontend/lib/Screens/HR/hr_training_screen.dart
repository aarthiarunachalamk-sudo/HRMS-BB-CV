import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrTrainingScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrTrainingScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Row(children: [
          Expanded(child: HrMetricCard(title: 'Upcoming', value: hrText(data, 'training_upcoming'), icon: Icons.school_rounded, color: c.primary)),
          const SizedBox(width: 10),
          Expanded(child: HrMetricCard(title: 'Completed', value: hrText(data, 'training_completed'), icon: Icons.check_circle_rounded, color: c.success)),
          const SizedBox(width: 10),
          Expanded(child: HrMetricCard(title: 'In Progress', value: hrText(data, 'training_progress'), icon: Icons.timelapse_rounded, color: c.danger)),
        ]),
        const SizedBox(height: 14),
        ...hrList(data, 'training').map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(icon: Icons.menu_book_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['time']}', color: c.primary),
            )),
      ],
    );
  }
}
