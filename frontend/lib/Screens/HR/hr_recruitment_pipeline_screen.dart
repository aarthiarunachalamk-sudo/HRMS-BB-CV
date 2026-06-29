import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrRecruitmentPipelineScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrRecruitmentPipelineScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final stages = hrList(data, 'pipeline');
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: stages.map((stage) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HrListTile(icon: Icons.filter_alt_rounded, title: '${stage['title']}', subtitle: '${stage['subtitle']}', color: c.purple),
        );
      }).toList(),
    );
  }
}
