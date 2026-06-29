import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaAttendanceMonitoringScreen extends StatelessWidget {
  const SaAttendanceMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Attendance Monitoring',
      trailing: Icon(Icons.calendar_month_rounded, color: c.text),
      child: saList([
        SaCard(child: Column(children: [const SizedBox(height: 10), SizedBox(width: 136, height: 136, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: 0.85, strokeWidth: 14, color: c.primary, backgroundColor: c.border), Column(mainAxisSize: MainAxisSize.min, children: [saTitle(context, '85%', 28), saMuted(context, 'Total Attendance', 11)])])), const SizedBox(height: 16), _Legend('Present', '1,002 (85%)', c.primary), _Legend('Absent', '120 (10%)', c.danger), _Legend('Late', '66 (5.3%)', c.warning), _Legend('On Leave', '48 (3.8%)', c.purple)])),
        const SizedBox(height: 12),
        SaMetricGrid(metrics: [SaMetric('Live Tracking', '123', Icons.location_on_outlined, c.teal), SaMetric('Selfie Verified', '1,021', Icons.groups_2_outlined, c.blue), SaMetric('Location Verified', '1,251', Icons.pin_drop_outlined, c.primary), SaMetric('Overtime', '21', Icons.timer_outlined, c.purple)]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Legend(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [CircleAvatar(radius: 4, backgroundColor: color), const SizedBox(width: 8), Expanded(child: saTitle(context, label, 12)), saMuted(context, value, 12)]));
}
