import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrRecruitmentPipelineScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrRecruitmentPipelineScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final stages = hrList(data, 'pipeline');
    return ListView(
      padding: AppLayout.pagePadding,
      children: stages.map((stage) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HrListTile(
            icon: Icons.filter_alt_rounded,
            title: '${stage['title']}',
            subtitle: '${stage['subtitle']}',
            color: c.purple,
          ),
        );
      }).toList(),
    );
  }
}
