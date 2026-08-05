import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';

import 'employee_models.dart';
import 'employee_shared.dart';

class EmployeeHomeScreen extends StatelessWidget {
  final EmployeeDashboardData data;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<Map<String, dynamic>> onNotificationTap;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenMeetings;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenPayslip;
  final VoidCallback onOpenDocuments;
  final String? profileImagePath;
  final VoidCallback onPickProfileImage;

  const EmployeeHomeScreen({
    super.key,
    required this.data,
    required this.onTabSelected,
    required this.onNotificationTap,
    required this.onOpenNotifications,
    required this.onOpenMeetings,
    required this.onOpenTasks,
    required this.onOpenPayslip,
    required this.onOpenDocuments,
    required this.profileImagePath,
    required this.onPickProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final profile = data.profile;
    final attendance = data.attendance;
    final checkIn = '${attendance['check_in'] ?? '--:--'}';
    final checkOut = '${attendance['check_out'] ?? '--:--'}';
    final hasCheckIn = _hasAttendanceTime(checkIn);
    final attendanceCompleted = _isAttendanceCompleted(attendance, checkOut);
    final attendanceStatus = _dashboardAttendanceStatus(
      '${attendance['status'] ?? ''}',
      hasCheckIn: hasCheckIn,
      hasCheckOut: attendanceCompleted,
    );
    final attendanceStatusColor = employeeStatusColor(attendanceStatus);
    final primaryActionLabel = attendanceCompleted
        ? 'Attendance Completed'
        : hasCheckIn
        ? 'Check Out'
        : 'Check In';
    final workingHours = _displayWorkingHours(attendance, checkIn, checkOut);
    final circlePrimaryText = attendanceCompleted
        ? workingHours
        : attendanceStatus;
    final circleSecondaryText = attendanceCompleted ? 'Working Hours' : 'Today';
    final unreadNotifications = data.notifications
        .where((item) => item['is_read'] != true)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                InkWell(
                  onTap: onPickProfileImage,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF10C7F4),
                          Color(0xFF3EDC81),
                          Color(0xFF1C8BFF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeConfig.isDark(context)
                            ? const Color(0xFF0A3359)
                            : const Color(0xFFEAF7FF),
                        image:
                            profileImagePath == null ||
                                profileImagePath!.isEmpty
                            ? null
                            : DecorationImage(
                                image: employeeProfileImageProvider(
                                  profileImagePath,
                                )!,
                                fit: BoxFit.cover,
                              ),
                      ),
                      child:
                          profileImagePath == null || profileImagePath!.isEmpty
                          ? const Icon(
                              Icons.add_a_photo_rounded,
                              color: EmployeeColors.blue,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppGreeting.current().label}!',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${profile['name'] ?? 'Employee'}',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${profile['designation'] ?? 'Employee'} - ${profile['department'] ?? ''}',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: EmployeeColors.blue,
                      ),
                      onPressed: onOpenNotifications,
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: EmployeeColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Today's Attendance",
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          EmployeeCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _metric(context, 'Check In', checkIn)),
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: attendanceStatusColor,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$circlePrimaryText\n$circleSecondaryText',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: attendanceStatusColor,
                            fontSize: attendanceCompleted ? 12 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        'Check Out',
                        checkOut,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: attendanceCompleted
                          ? Colors.white.withAlpha(35)
                          : EmployeeColors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withAlpha(35),
                      disabledForegroundColor: Colors.white54,
                    ),
                    onPressed: attendanceCompleted
                        ? null
                        : () => onTabSelected(1),
                    child: Text(primaryActionLabel),
                  ),
                ),
                if (attendanceCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Working hours: $workingHours',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Quick Actions',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .95,
            children: [
              _action(
                context,
                Icons.access_time_rounded,
                'Attendance',
                EmployeeColors.red,
                () => onTabSelected(1),
              ),
              _action(
                context,
                Icons.beach_access_rounded,
                'Leave',
                EmployeeColors.blue,
                () => onTabSelected(2),
              ),
              _action(
                context,
                Icons.payments_rounded,
                'Payslip',
                EmployeeColors.purple,
                onOpenPayslip,
              ),
              _action(
                context,
                Icons.task_alt_rounded,
                'Tasks',
                EmployeeColors.green,
                onOpenTasks,
              ),
              _action(
                context,
                Icons.calendar_month_rounded,
                'Meetings',
                EmployeeColors.purple,
                onOpenMeetings,
              ),
              _action(
                context,
                Icons.description_rounded,
                'Documents',
                EmployeeColors.gold,
                onOpenDocuments,
              ),
              _action(
                context,
                Icons.person_rounded,
                'Profile',
                EmployeeColors.blue,
                () => onTabSelected(3),
              ),
              _action(
                context,
                Icons.settings_rounded,
                'More',
                EmployeeColors.pink,
                () => onTabSelected(4),
              ),
              _action(
                context,
                Icons.add_location_alt_rounded,
                'Client Visits',
                EmployeeColors.blue,
                () => onTabSelected(5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenNotifications,
                child: const Text('View All'),
              ),
            ],
          ),
          ...data.notifications
              .take(2)
              .map(
                (item) => EmployeeListTile(
                  icon: Icons.notifications_active_rounded,
                  title: '${item['title'] ?? ''}',
                  subtitle: '${item['message'] ?? ''}',
                  trailing: '${item['time'] ?? ''}',
                  color: employeeStatusColor('${item['type'] ?? ''}'),
                  onTap: () => onNotificationTap(item),
                ),
              ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ThemeConfig.getTextSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: ThemeConfig.getTextPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: EmployeeCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: ThemeConfig.getTextPrimary(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
  for (final key in const ['checkout', 'check_out_time', 'checkout_time']) {
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

String _dashboardAttendanceStatus(
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
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
  ).firstMatch(normalized);
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
