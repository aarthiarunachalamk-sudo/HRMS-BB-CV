import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

/// Admin dashboard home tab.
/// Only surfaces admin-owned concerns: employees, attendance, leave, reports.
/// Tasks and meeting creation belong to TL / HR.
class AdminHomeScreen extends StatefulWidget {
  final String firstName;
  final String email;
  final String userId;
  final VoidCallback onOpenEmployees;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenLeaves;
  final VoidCallback onOpenMeetings;

  const AdminHomeScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.userId,
    required this.onOpenEmployees,
    required this.onOpenAttendance,
    required this.onOpenLeaves,
    required this.onOpenMeetings,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService().fetchDashboard(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final activity = data['recent_activity'] is List
            ? data['recent_activity'] as List
            : const [];
        return adminPageList([
          // ── Welcome card ────────────────────────────────────
          AdminCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: c.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: c.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      adminMuted('${AppGreeting.current().label},', 12, c),
                      adminTitle(
                        widget.firstName.isEmpty ? 'Admin' : widget.firstName,
                        17,
                        c,
                      ),
                      adminMuted(widget.email, 11, c),
                      if (widget.userId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        adminSmall(widget.userId, c.primary),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const AdminSectionTitle('Overview'),

          // ── Metric grid ──────────────────────────────────────
          AdminMetricGrid(
            cards: [
              AdminMetric(
                'Total Employees',
                '${data['total_employees'] ?? '--'}',
                '',
                Icons.groups_rounded,
                c.primary,
              ),
              AdminMetric(
                'Present Today',
                '${data['present_today'] ?? '--'}',
                '',
                Icons.how_to_reg_rounded,
                c.green,
              ),
              AdminMetric(
                'On Leave',
                '${data['on_leave'] ?? '--'}',
                '',
                Icons.beach_access_rounded,
                c.orange,
              ),
              AdminMetric(
                'Meetings Today',
                '${data['meetings_today'] ?? '--'}',
                '',
                Icons.event_rounded,
                c.purple,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Attendance trend ─────────────────────────────────
          AdminChartCard(
            title: 'Attendance Overview',
            subtitle: 'Last 6 days',
            trend: data['attendance_trend'] != null ? '${data['attendance_trend']}' : '',
            bars: () {
              final raw = data['attendance_bars'];
              if (raw is List && raw.isNotEmpty) {
                return raw.map((v) => (v as num).toDouble()).toList();
              }
              return const <double>[];
            }(),
            color: c.green,
          ),

          const SizedBox(height: 4),

          // ── Quick stats row ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  'Leave Requests',
                  '${data['pending_leaves'] ?? '0'}',
                  'Pending',
                  c.orange,
                  c,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  'Absent Today',
                  '${data['absent_today'] ?? '0'}',
                  'Employees',
                  c.red,
                  c,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  'New Joinings',
                  '${data['new_joinings'] ?? '0'}',
                  'This Month',
                  c.primary,
                  c,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const AdminSectionTitle('Quick Actions'),

          // ── Quick actions (admin-owned only) ─────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _QuickAction(
                Icons.people_rounded,
                'Employees',
                c.primary,
                widget.onOpenEmployees,
                c,
              ),
              _QuickAction(
                Icons.calendar_month_rounded,
                'Attendance',
                c.green,
                widget.onOpenAttendance,
                c,
              ),
              _QuickAction(
                Icons.beach_access_rounded,
                'Leave Requests',
                c.orange,
                widget.onOpenLeaves,
                c,
              ),
              _QuickAction(
                Icons.event_rounded,
                'Meetings',
                c.purple,
                widget.onOpenMeetings,
                c,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const AdminSectionTitle('Recent Activity'),

          // ── Dynamic recent activity from API ────────────────
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: adminMuted('No recent activity', 13, c),
              ),
            )
          else
            ...activity.map((item) {
              final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
              final type = '${m['type'] ?? ''}';
              IconData icon;
              Color color;
              switch (type) {
                case 'employee_added':
                  icon = Icons.person_add_rounded;
                  color = c.green;
                case 'leave_approved':
                  icon = Icons.beach_access_rounded;
                  color = c.orange;
                case 'meeting_scheduled':
                  icon = Icons.event_rounded;
                  color = c.purple;
                case 'attendance_updated':
                  icon = Icons.how_to_reg_rounded;
                  color = c.primary;
                default:
                  icon = Icons.info_outline_rounded;
                  color = c.primary;
              }
              return AdminListTile(
                icon: icon,
                titleText: '${m['title'] ?? type}',
                subtitle: '${m['subtitle'] ?? m['description'] ?? ''}',
                color: color,
              );
            }),
        ]);
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;
  final AdminPalette c;
  const _MiniStat(this.label, this.value, this.caption, this.color, this.c);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminMuted(label, 10, c),
          const SizedBox(height: 6),
          adminTitle(value, 18, c),
          const SizedBox(height: 2),
          adminSmall(caption, color),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final AdminPalette c;
  const _QuickAction(this.icon, this.label, this.color, this.onTap, this.c);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: c.shadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
