import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

/// Standalone dashboard screen used as one of the SuperAdmin bottom-nav tabs.
/// All metric values and analytics data are fetched live from [SaService].
class SaDashboardScreen extends StatelessWidget {
  final String email;
  final VoidCallback? onCreateUser;

  const SaDashboardScreen({super.key, required this.email, this.onCreateUser});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SaScreen(
            title: 'Dashboard',
            trailing: Icon(Icons.notifications_none_rounded, color: c.text),
            child: Center(
              child: saMuted(
                context,
                'Could not load dashboard data',
                13,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return SaScreen(
            title: 'Dashboard',
            trailing: Icon(Icons.notifications_none_rounded, color: c.text),
            child: Center(child: CircularProgressIndicator(color: c.primary)),
          );
        }

        final data = snapshot.data!;
        return SaScreen(
          title: 'Dashboard',
          trailing: Icon(Icons.notifications_none_rounded, color: c.text),
          child: saList([
            SaCard(
              child: Row(
                children: [
                  SaIconBox(
                    icon: Icons.admin_panel_settings_rounded,
                    color: c.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        saMuted(context, '${AppGreeting.current().label},', 12),
                        saTitle(context, 'Super Admin', 18),
                        saMuted(context, email, 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SaMetricGrid(
              metrics: [
                SaMetric(
                  'Total Employees',
                  '${data['total_employees'] ?? '--'}',
                  Icons.groups_rounded,
                  c.primary,
                ),
                SaMetric(
                  'Total Departments',
                  '${data['total_departments'] ?? '--'}',
                  Icons.apartment_rounded,
                  c.blue,
                ),
                SaMetric(
                  'Active Users',
                  '${data['active_users'] ?? '--'}',
                  Icons.verified_user_outlined,
                  c.success,
                ),
                SaMetric(
                  'Attendance',
                  '${data['attendance'] ?? '--'}',
                  Icons.calendar_month_outlined,
                  c.teal,
                ),
                SaMetric(
                  'Pending Leaves',
                  '${data['pending_leaves'] ?? '--'}',
                  Icons.event_busy_outlined,
                  c.warning,
                ),
                SaMetric(
                  'Open Tasks',
                  '${data['open_tasks'] ?? '--'}',
                  Icons.task_alt_rounded,
                  c.danger,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AnalyticsOverview(colors: c, data: data),
          ]),
        );
      },
    );
  }
}

class _AnalyticsOverview extends StatelessWidget {
  final SaPalette colors;
  final Map<String, dynamic> data;

  const _AnalyticsOverview({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    // Use API-provided chart bars if available, otherwise render empty state
    final rawBars = data['attendance_chart'];
    final bars = rawBars is List && rawBars.isNotEmpty
        ? rawBars.map((v) => (v as num).toDouble()).toList()
        : <double>[];

    final present = '${data['present_today'] ?? '--'}';
    final absent = '${data['absent_today'] ?? '--'}';
    final late = '${data['late_today'] ?? '--'}';

    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: saTitle(context, 'Analytics Overview', 14)),
              Text(
                'Live',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Mini(present, 'Present', colors.success)),
              const SizedBox(width: 8),
              Expanded(child: _Mini(absent, 'Absent', colors.danger)),
              const SizedBox(width: 8),
              Expanded(child: _Mini(late, 'Late', colors.warning)),
            ],
          ),
          if (bars.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 86,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map(
                      (h) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: h > 70 ? colors.primary : colors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String value;
  final String title;
  final Color color;

  const _Mini(this.value, this.title, this.color);

  @override
  Widget build(BuildContext context) => SaCard(
        color: color.withAlpha(SaPalette.of(context).isDark ? 28 : 14),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            saTitle(context, value, 13),
          ],
        ),
      );
}
