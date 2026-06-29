import 'package:flutter/material.dart';
import 'sa_shared.dart';

class SaDashboardScreen extends StatelessWidget {
  final String email;
  final VoidCallback? onCreateUser;

  const SaDashboardScreen({super.key, required this.email, this.onCreateUser});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Dashboard',
      trailing: Icon(Icons.notifications_none_rounded, color: c.text),
      child: saList([
        SaCard(child: Row(children: [SaIconBox(icon: Icons.admin_panel_settings_rounded, color: c.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [saMuted(context, 'Welcome Back,', 12), saTitle(context, 'Super Admin', 18), saMuted(context, email, 11)]))])),
        const SizedBox(height: 12),
        SaMetricGrid(metrics: [
          SaMetric('Total Employees', '1,248', Icons.groups_rounded, c.primary),
          SaMetric('Total Departments', '24', Icons.apartment_rounded, c.blue),
          SaMetric('Active Users', '1,156', Icons.verified_user_outlined, c.success),
          SaMetric('Attendance', '85%', Icons.calendar_month_outlined, c.teal),
          SaMetric('Pending Leaves', '63', Icons.event_busy_outlined, c.warning),
          SaMetric('Open Tasks', '18', Icons.task_alt_rounded, c.danger),
        ]),
        const SizedBox(height: 14),
        _AnalyticsOverview(colors: c),
      ]),
    );
  }
}

class _AnalyticsOverview extends StatelessWidget {
  final SaPalette colors;

  const _AnalyticsOverview({required this.colors});

  @override
  Widget build(BuildContext context) {
    const bars = [34.0, 72.0, 46.0, 88.0, 52.0, 28.0, 78.0, 40.0, 64.0, 92.0, 32.0, 58.0];
    return SaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: saTitle(context, 'Analytics Overview', 14)), Text('View All', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Mini('Present', '1,002', colors.success)),
          const SizedBox(width: 8),
          Expanded(child: _Mini('Absent', '120', colors.danger)),
          const SizedBox(width: 8),
          Expanded(child: _Mini('Late', '66', colors.warning)),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 86, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: bars.map((h) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Container(height: h, decoration: BoxDecoration(color: h > 70 ? colors.primary : colors.warning, borderRadius: BorderRadius.circular(4)))))).toList())),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _Mini(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) => SaCard(color: color.withAlpha(SaPalette.of(context).isDark ? 28 : 14), padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)), const SizedBox(height: 4), saTitle(context, value, 13)]));
}
