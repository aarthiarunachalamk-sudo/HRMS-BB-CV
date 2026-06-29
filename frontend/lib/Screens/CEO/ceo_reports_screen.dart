import 'package:flutter/material.dart';

import 'ceo_report_details_screen.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoReportsScreen extends StatelessWidget {
  final String userId;

  const CeoReportsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoFutureBody(
      future: CeoService().fetchReports(userId),
      builder: (data) {
        final reports = data['reports'] is List ? data['reports'] as List : const [];
        return pageList(reports.map((item) {
          final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
          return CeoListTile(
            icon: Icons.assignment_rounded,
            titleText: '${map['title'] ?? 'Report'}',
            subtitle: '${map['subtitle'] ?? 'View report'}',
            color: CeoColors.green,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CeoReportDetailsScreen(userId: userId))),
          );
        }).toList());
      },
    );
  }
}
