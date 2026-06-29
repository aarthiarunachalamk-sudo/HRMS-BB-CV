import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrOnboardingScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrOnboardingScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: hrList(data, 'onboarding').map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HrListTile(icon: Icons.assignment_ind_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', color: c.primary),
        );
      }).toList(),
    );
  }
}
