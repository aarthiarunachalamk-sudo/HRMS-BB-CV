import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_employee_detail_screen.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrAttendanceScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final records = hrList(data, 'attendance_records');
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Text(
          'Team Attendance Overview',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review employee attendance here. To mark your own attendance, switch to the Employee role.',
          style: TextStyle(color: c.muted, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: HrMetricCard(
                title: 'Present',
                value: hrText(data, 'present_today'),
                icon: Icons.verified_rounded,
                color: c.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HrMetricCard(
                title: 'Absent',
                value: hrText(data, 'absent_today'),
                icon: Icons.person_off_rounded,
                color: c.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HrMetricCard(
                title: 'On Leave',
                value: hrText(data, 'on_leave'),
                icon: Icons.beach_access_rounded,
                color: c.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HrMetricCard(
                title: 'Late Entry',
                value: hrText(data, 'late_entry'),
                icon: Icons.schedule_rounded,
                color: c.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HrMetricCard(
                title: 'WFH',
                value: hrText(data, 'wfh'),
                icon: Icons.home_work_rounded,
                color: c.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Recent Records',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...records.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.access_time_rounded,
              title: '${item['name']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['time']}',
              color: c.teal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HrAttendanceDetailScreen(record: item),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HrAttendanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> record;

  const HrAttendanceDetailScreen({super.key, required this.record});

  @override
  State<HrAttendanceDetailScreen> createState() => _HrAttendanceDetailScreenState();
}

class _HrAttendanceDetailScreenState extends State<HrAttendanceDetailScreen> {
  late Map<String, dynamic> record = Map<String, dynamic>.from(widget.record);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = int.tryParse('${record['attendance_id'] ?? ''}');
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final response = await HrService().fetchAttendanceDetails(id);
      final loaded = response['attendance'];
      if (mounted && loaded is Map) {
        setState(() => record = Map<String, dynamic>.from(loaded));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final status = '${record['attendance_status'] ?? record['status'] ?? '-'}';
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        title: const Text('Attendance Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          HrCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record['name'] ?? 'Employee'}',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record['employee_id'] ?? record['id'] ?? ''}',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow('Date', '${record['attendance_date'] ?? '-'}', c),
                _detailRow('Status', status, c),
                _detailRow('Check in', '${record['check_in'] ?? '-'}', c),
                _detailRow('Check out', '${record['check_out'] ?? '-'}', c),
                _detailRow(
                  'Working hours',
                  '${record['working_hours'] ?? '-'}',
                  c,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AttendanceSelfieCard(
            title: 'Check-in Image',
            time: '${record['check_in'] ?? '-'}',
            imageUrl: '${record['check_in_selfie'] ?? ''}',
            icon: Icons.login_rounded,
            color: c.teal,
          ),
          const SizedBox(height: 12),
          HrCard(
            child: Column(
              children: [
                _detailRow('Check-in location', _location('check_in'), c),
                _detailRow('Check-out location', _location('check_out'), c),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AttendanceSelfieCard(
            title: 'Check-out Image',
            time: '${record['check_out'] ?? '-'}',
            imageUrl: '${record['check_out_selfie'] ?? ''}',
            icon: Icons.logout_rounded,
            color: c.primary,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HrEmployeeDetailScreen(employee: record),
              ),
            ),
            icon: const Icon(Icons.person_rounded),
            label: const Text('View Employee Profile'),
          ),
        ],
      ),
    );
  }

  String _location(String prefix) {
    final latitude = '${record['${prefix}_latitude'] ?? ''}'.trim();
    final longitude = '${record['${prefix}_longitude'] ?? ''}'.trim();
    final accuracy = '${record['${prefix}_accuracy'] ?? ''}'.trim();
    if (latitude.isEmpty || longitude.isEmpty) return 'Not available';
    return '$latitude, $longitude${accuracy.isEmpty ? '' : ' (±$accuracy m)'}';
  }

  Widget _detailRow(String label, String value, HrPalette c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _AttendanceSelfieCard extends StatelessWidget {
  final String title;
  final String time;
  final String imageUrl;
  final IconData icon;
  final Color color;

  const _AttendanceSelfieCard({
    required this.title,
    required this.time,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return HrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(time, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isEmpty
                ? _missingImage(c)
                : Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _missingImage(c),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _missingImage(HrPalette c) => Container(
    width: double.infinity,
    height: 140,
    color: c.row,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_not_supported_outlined, color: c.muted, size: 32),
        const SizedBox(height: 6),
        Text('Image not available', style: TextStyle(color: c.muted, fontSize: 12)),
      ],
    ),
  );
}
