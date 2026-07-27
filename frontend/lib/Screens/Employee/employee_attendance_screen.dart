import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

import 'employee_attendance_history_screen.dart';
import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_selfie_attendance_screen.dart';
import 'employee_shared.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;
  final ValueChanged<Map<String, dynamic>> onAttendanceMarked;
  final String? profileImagePath;

  const EmployeeAttendanceScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
    required this.onAttendanceMarked,
    this.profileImagePath,
  });

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  Future<void> _openSelfieAttendance(EmployeeAttendanceAction action) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EmployeeSelfieAttendanceScreen(
          userId: widget.userId,
          service: widget.service,
          action: action,
        ),
      ),
    );
    if (!mounted || result == null) return;
    widget.onAttendanceMarked(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result['message'] ?? 'Attendance marked'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final attendance = widget.data.attendance;
    final checkIn = '${attendance['check_in'] ?? '--:--'}';
    final checkOut = '${attendance['check_out'] ?? '--:--'}';
    final hasCheckIn = _hasAttendanceTime(checkIn);
    final attendanceCompleted = _isAttendanceCompleted(attendance, checkOut);
    final workingHours = attendanceCompleted
        ? _displayWorkingHours(attendance, checkIn, checkOut)
        : '${attendance['working_hours'] ?? '--'}';
    final lateEntry = '${attendance['late_entry'] ?? '--'}';
    final overtime = '${attendance['overtime'] ?? '00h 00m'}';
    final date = _formatAttendanceDate('${attendance['date'] ?? ''}');
    final status = _attendanceDisplayStatus(
      '${attendance['status'] ?? ''}',
      hasCheckIn: hasCheckIn,
      hasCheckOut: attendanceCompleted,
    );
    final statusColor = employeeStatusColor(status);
    final needsCheckIn = !hasCheckIn;
    final nextAction = needsCheckIn
        ? EmployeeAttendanceAction.checkIn
        : EmployeeAttendanceAction.checkOut;
    final primaryButtonLabel = attendanceCompleted
        ? 'Attendance Completed'
        : needsCheckIn
        ? 'Check In'
        : 'Check Out';
    final centerTimeLabel = attendanceCompleted ? 'Checked Out' : 'Checked In';
    final centerTimeValue = attendanceCompleted ? checkOut : checkIn;
    final circlePrimaryText = attendanceCompleted ? workingHours : status;
    final circleLabel = attendanceCompleted ? 'Working Hours' : centerTimeLabel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Attendance",
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 178,
              height: 178,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    circlePrimaryText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    circleLabel,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  Text(
                    centerTimeValue,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _AttendanceMetric(
                  label: 'Working Hours',
                  value: workingHours,
                  color: EmployeeColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttendanceMetric(
                  label: 'Late Entry',
                  value: lateEntry,
                  color: EmployeeColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttendanceMetric(
                  label: 'Overtime',
                  value: overtime,
                  color: EmployeeColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: attendanceCompleted
                    ? Colors.white.withAlpha(35)
                    : EmployeeColors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withAlpha(35),
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              onPressed: attendanceCompleted
                  ? null
                  : () => _openSelfieAttendance(nextAction),
              child: Text(primaryButtonLabel),
            ),
          ),
          const SizedBox(height: 14),
          _HistoryTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeAttendanceHistoryScreen(
                  userId: widget.userId,
                  service: widget.service,
                  profile: widget.data.profile,
                  profileImagePath: widget.profileImagePath,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _PendingCard(
            action: nextAction,
            checkOut: checkOut,
            attendanceCompleted: attendanceCompleted,
            onCancel: () {},
            onConfirm: attendanceCompleted
                ? null
                : () => _openSelfieAttendance(nextAction),
          ),
        ],
      ),
    );
  }
}

bool _hasAttendanceTime(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty &&
      normalized != '--:--' &&
      normalized != '--' &&
      normalized != 'null';
}

bool _isAttendanceCompleted(Map<String, dynamic> attendance, String checkOut) {
  if (_hasAttendanceTime(checkOut)) return true;
  for (final key in const [
    'checkout',
    'check_out_time',
    'checkout_time',
  ]) {
    if (_hasAttendanceTime('${attendance[key] ?? ''}')) return true;
  }
  final status = '${attendance['status'] ?? ''}'.toLowerCase();
  if (status.contains('completed') ||
      status.contains('check-out') ||
      status.contains('checkout')) {
    return true;
  }
  return false;
}

String _attendanceDisplayStatus(
  String backendStatus, {
  required bool hasCheckIn,
  required bool hasCheckOut,
}) {
  if (!hasCheckIn) return 'Not Marked';
  if (hasCheckOut) return 'Completed';
  final normalized = backendStatus.trim();
  if (normalized.isEmpty ||
      normalized.toLowerCase() == 'not marked' ||
      normalized.toLowerCase() == 'half day') {
    return 'Checked In';
  }
  return normalized;
}

String _workingDuration(String checkIn, String checkOut) {
  final start = _timeOfDayToDateTime(checkIn);
  final end = _timeOfDayToDateTime(checkOut);
  if (start == null || end == null) return '--';
  final adjustedEnd = end.isBefore(start)
      ? end.add(const Duration(days: 1))
      : end;
  final duration = adjustedEnd.difference(start);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
}

String _displayWorkingHours(
  Map<String, dynamic> attendance,
  String checkIn,
  String checkOut,
) {
  final backendValue = '${attendance['working_hours'] ?? ''}'.trim();
  if (backendValue.isNotEmpty &&
      backendValue != '--' &&
      backendValue.toLowerCase() != 'null') {
    return backendValue;
  }
  return _workingDuration(checkIn, checkOut);
}

DateTime? _timeOfDayToDateTime(String value) {
  final normalized = value.trim().toUpperCase();
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  final meridiem = match.group(3);
  if (hour == null || minute == null || minute > 59) return null;
  if (meridiem != null) {
    if (hour < 1 || hour > 12) return null;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (meridiem == 'PM' && hour != 12) hour += 12;
  } else if (hour > 23) {
    return null;
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class _AttendanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: ThemeConfig.getTextSecondary(context),
          ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _HistoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Attendance History',
                style: TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final EmployeeAttendanceAction action;
  final String checkOut;
  final bool attendanceCompleted;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const _PendingCard({
    required this.action,
    required this.checkOut,
    required this.attendanceCompleted,
    required this.onCancel,
    required this.onConfirm,
  });

  bool get _isCheckIn => action == EmployeeAttendanceAction.checkIn;

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    late final String title;
    late final String body;
    if (_isCheckIn) {
      title = 'Check-In Required';
      body = 'Please check in with selfie and GPS to mark your attendance.';
    } else if (attendanceCompleted || _hasAttendanceTime(checkOut)) {
      title = 'Check-Out Completed';
      body = 'Your check-out has already been recorded.';
    } else {
      title = 'Check-Out Pending';
      body = 'You have not checked out yet. Do you want to check out now?';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: EmployeeColors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onConfirm,
                  child: Text(_isCheckIn ? 'Check In' : 'Check Out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatAttendanceDate(String rawDate) {
  final trimmed = rawDate.trim();
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return trimmed.isEmpty ? _formatDate(DateTime.now()) : trimmed;
  }
  return _formatDate(parsed);
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}, ${_weekdayName(date.weekday)}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[weekday - 1];
}
