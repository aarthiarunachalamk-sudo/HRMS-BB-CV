import 'package:flutter/material.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

class AdminAttendanceScreen extends StatelessWidget {
  final String userId;
  const AdminAttendanceScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Attendance',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchAttendance(userId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final attendance = _attendanceRecords(data);
          return adminPageList([
            // Date header
            AdminCard(
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: c.primary, size: 18),
                const SizedBox(width: 10),
                adminTitle(_today(), 14, c),
                const Spacer(),
                AdminBadge('Live', color: c.green),
              ]),
            ),

            // Summary stats
            Row(children: [
              _AttStat('Present', '${data['present'] ?? '0'}', c.green, c),
              const SizedBox(width: 10),
              _AttStat('Absent', '${data['absent'] ?? '0'}', c.red, c),
              const SizedBox(width: 10),
              _AttStat('Late', '${data['late'] ?? '0'}', c.orange, c),
              const SizedBox(width: 10),
              _AttStat('Leave', '${data['on_leave'] ?? '0'}', c.purple, c),
            ]),

            const SizedBox(height: 8),
            const AdminSearchBox(hint: 'Search employee attendance...'),
            const SizedBox(height: 4),

            const AdminSectionTitle('Employee Attendance'),

            if (attendance.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No attendance records found', 12, c),
                ),
              ),
            ...attendance.map((a) => _AttendanceTile(att: a, c: c)),
          ]);
        },
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  List<Map<String, String>> _attendanceRecords(Map<String, dynamic> data) {
    final raw = data['records'] as List? ?? [];
    if (raw.isNotEmpty) {
      return raw.map((e) => e is Map ? Map<String, String>.from(e.map((k, v) => MapEntry('$k', '$v'))) : <String, String>{}).toList();
    }
    return const [];
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AdminPalette c;

  const _AttStat(this.label, this.value, this.color, this.c);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AdminCard(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          adminTitle(value, 18, c),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final Map<String, String> att;
  final AdminPalette c;

  const _AttendanceTile({required this.att, required this.c});

  @override
  Widget build(BuildContext context) {
    final status = att['status'] ?? 'Present';
    final Color statusColor;
    switch (status) {
      case 'Present':
        statusColor = c.green;
        break;
      case 'Absent':
        statusColor = c.red;
        break;
      case 'Late':
        statusColor = c.orange;
        break;
      default:
        statusColor = c.purple;
    }
    return AdminCard(
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: statusColor.withOpacity(0.14),
          child: Text(
            (att['name'] ?? 'E').substring(0, 1).toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminTitle(att['name'] ?? '', 13, c),
            adminMuted(att['id'] ?? '', 11, c),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AdminBadge(status, color: statusColor),
          const SizedBox(height: 4),
          adminSmall(att['checkin'] ?? '--', c.muted),
        ]),
      ]),
    );
  }
}
