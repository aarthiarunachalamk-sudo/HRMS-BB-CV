import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/logout_exit_dialog.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_attendance_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_documents_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_employee_directory_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_employees_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_leave_requests_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_meetings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_onboarding_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_payroll_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_performance_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_profile_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_recruitment_pipeline_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_recruitment_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_schedule_interview_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_shared.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_tasks_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_training_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/register_employees.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_dashboard.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientVisits/client_visit_screens.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

class HrDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const HrDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<Map<String, dynamic>> _future;
  int _index = 0;
  final List<int> _navigationHistory = [];
  String _role = 'HR';
  File? _profileImage;
  Map<String, dynamic> _latestData = const {};

  @override
  void initState() {
    super.initState();
    _future = HrService().fetchDashboard(widget.userId);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _toggleTheme() {
    MyApp.themeNotifier.value = MyApp.themeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() {});
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  void _refreshDashboard() {
    setState(() {
      _future = HrService().fetchDashboard(widget.userId);
    });
  }

  void _switchRole(String role) {
    if (role == 'Employee') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeDashboard(
            email: widget.email,
            firstName: widget.firstName,
            userId: widget.userId,
            roleSwitchLabel: 'HR',
            roleSwitchBuilder: (_) => HrDashboard(
              email: widget.email,
              firstName: widget.firstName,
              userId: widget.userId,
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navigationHistory.isNotEmpty) {
          _setIndex(_navigationHistory.removeLast(), remember: false);
        } else if (_index != 0) {
          _setIndex(0, remember: false);
        } else {
          showLogoutExitConfirmation(context: context, onLogout: _logout);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: c.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            if (snapshot.hasData) _latestData = snapshot.data!;
            final pages = [
              _HrHome(
                data: data,
                name: widget.firstName,
                email: widget.email,
                profileImage: _profileImage,
                onProfileTap: _pickProfileImage,
                onOpen: _setIndex,
                onNotificationTap: _openNotification,
              ),
              const RegisterEmployeesPage(),
              HrEmployeesScreen(data: data),
              HrAttendanceScreen(data: data),
              HrLeaveRequestsScreen(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
              ),
              HrRecruitmentScreen(
                data: data,
                onPipeline: () => _setIndex(7),
                onSchedule: () => _setIndex(8),
              ),
              HrMeetingsScreen(userId: widget.userId),
              HrRecruitmentPipelineScreen(data: data),
              HrScheduleInterviewScreen(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
              ),
              HrOnboardingScreen(data: data),
              HrDocumentsScreen(userId: widget.userId),
              HrPerformanceScreen(data: data),
              HrPayrollScreen(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
              ),
              HrTrainingScreen(data: data),
              HrTasksScreen(data: data),
              HrProfileScreen(
                userId: widget.userId,
                email: widget.email,
                name: widget.firstName,
                onLogout: () =>
                    showLogoutConfirmation(context: context, onLogout: _logout),
              ),
            ];

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: c.bg,
              drawer: _HrDrawer(
                data: data,
                email: widget.email,
                onTap: _setIndex,
                onLogout: () =>
                    showLogoutConfirmation(context: context, onLogout: _logout),
                onClientVisits: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Client Visits')),
                        body: ClientVisitDashboardScreen(
                          userId: widget.userId,
                          reviewerMode: true,
                          requesterRole: 'hr',
                        ),
                      ),
                    ),
                  );
                },
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.bg, c.bgAlt],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        colors: c,
                        title: _titles[_index],
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onTheme: _toggleTheme,
                      ),
                      if (_index == 0)
                        _HrRoleDropdown(
                          colors: c,
                          value: _role,
                          onChanged: _switchRole,
                        ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        LinearProgressIndicator(
                          minHeight: 2,
                          color: c.primary,
                          backgroundColor: Colors.transparent,
                        ),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Unable to load data. Please try again.',
                            style: TextStyle(
                              color: c.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      Expanded(child: pages[_index]),
                      _BottomNav(colors: c, index: _index, onTap: _setIndex),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _setIndex(int value, {bool remember = true}) {
    if (value < 0 || value >= _titles.length) return;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    if (value == _index) return;
    setState(() {
      if (remember) _navigationHistory.add(_index);
      _index = value;
    });
  }

  void _openNotification(Map<String, dynamic> item) {
    final module = '${item['module'] ?? ''}'.toLowerCase();
    final title = '${item['title'] ?? ''}'.toLowerCase();
    final subtitle = '${item['subtitle'] ?? item['message'] ?? ''}'
        .toLowerCase();
    if (module == 'client_visit' || module == 'client-visit') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Client Visits')),
            body: ClientVisitDashboardScreen(
              userId: widget.userId,
              reviewerMode: true,
              requesterRole: 'hr',
            ),
          ),
        ),
      );
      return;
    }
    if (module.startsWith('attendance')) {
      final referenceId = '${item['reference_id'] ?? ''}';
      var employeeId = referenceId.split(':').first.trim();
      if (employeeId.isEmpty) {
        final match = RegExp(r'\(([^()]+)\)').firstMatch(subtitle);
        employeeId = match?.group(1)?.trim() ?? '';
      }
      final records = hrList(_latestData, 'attendance_records');
      Map<String, dynamic>? record;
      for (final candidate in records) {
        final candidateId =
            '${candidate['employee_id'] ?? candidate['id'] ?? ''}'.trim();
        if (candidateId == employeeId) {
          record = candidate;
          break;
        }
      }
      if (record != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HrAttendanceDetailScreen(record: record!),
          ),
        );
      } else {
        _setIndex(3);
      }
      return;
    }
    if (module == 'leave' ||
        title.contains('leave') ||
        subtitle.contains('leave')) {
      _setIndex(4);
      return;
    }
    if (module == 'meeting' ||
        title.contains('meeting') ||
        subtitle.contains('meeting')) {
      _setIndex(6);
      return;
    }
    if (module == 'documents' ||
        title.contains('document') ||
        subtitle.contains('document')) {
      _setIndex(1);
      return;
    }
    if (module == 'recruitment' ||
        title.contains('resume') ||
        title.contains('interview') ||
        subtitle.contains('candidate')) {
      _setIndex(5);
      return;
    }
    _setIndex(14);
  }
}

class _HrHome extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final String email;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final ValueChanged<int> onOpen;
  final ValueChanged<Map<String, dynamic>> onNotificationTap;

  const _HrHome({
    required this.data,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.onProfileTap,
    required this.onOpen,
    required this.onNotificationTap,
  });

  String _notificationHeading(List<Map<String, dynamic>> notifications) {
    final modules = notifications
        .map((item) => '${item['module'] ?? ''}'.toLowerCase())
        .toSet();
    if (modules.isNotEmpty &&
        modules.every((m) => m.startsWith('attendance'))) {
      return 'Attendance Notifications';
    }
    if (modules.length == 1 && modules.first == 'meeting') {
      return 'Meeting Notifications';
    }
    return 'Recent Notifications';
  }

  IconData _notificationIcon(Map<String, dynamic> item) {
    final module = '${item['module'] ?? ''}'.toLowerCase();
    final message = '${item['subtitle'] ?? item['message'] ?? ''}'
        .toLowerCase();
    if (module.startsWith('attendance') && message.contains('checked out')) {
      return Icons.logout_rounded;
    }
    if (module.startsWith('attendance')) return Icons.login_rounded;
    if (module == 'meeting') return Icons.event_rounded;
    if (module == 'leave') return Icons.beach_access_rounded;
    if (module == 'documents') return Icons.description_rounded;
    if (module == 'tasks') return Icons.task_alt_rounded;
    if (module == 'recruitment') return Icons.work_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _notificationColor(Map<String, dynamic> item, HrPalette c) {
    final module = '${item['module'] ?? ''}'.toLowerCase();
    final message = '${item['subtitle'] ?? item['message'] ?? ''}'
        .toLowerCase();
    if (module.startsWith('attendance') && message.contains('checked out')) {
      return c.primary;
    }
    if (module.startsWith('attendance')) return c.teal;
    if (module == 'leave') return c.purple;
    if (module == 'meeting') return c.warning;
    if (module == 'documents') return c.primary;
    if (module == 'tasks') return c.success;
    if (module == 'recruitment') return c.purple;
    return c.warning;
  }

  void _showStatDetail(
    BuildContext context,
    HrPalette c,
    String title,
    List<Map<String, dynamic>> employees,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Text(
                      '${employees.length}',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, color: c.muted, size: 44),
                          const SizedBox(height: 10),
                          Text(
                            'No employees',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                      itemCount: employees.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: c.border, height: 1),
                      itemBuilder: (_, i) {
                        final emp = employees[i];
                        final initials = '${emp['name'] ?? '?'}'.isNotEmpty
                            ? '${emp['name']}'[0].toUpperCase()
                            : '?';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withAlpha(30),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${emp['name'] ?? ''}',
                                      style: TextStyle(
                                        color: c.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${emp['subtitle'] ?? ''}',
                                      style: TextStyle(
                                        color: c.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${emp['trailing'] ?? ''}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            _HrProfileAvatar(
              image: profileImage,
              radius: 28,
              onTap: onProfileTap,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppGreeting.current().label},',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    name.trim().isEmpty ? 'HR Manager' : name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            HrMetricCard(
              title: 'Total Employees',
              value: hrText(data, 'total_employees'),
              icon: Icons.groups_rounded,
              color: c.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HrEmployeeDirectoryScreen(
                    employees: hrList(data, 'total_employees_list'),
                  ),
                ),
              ),
            ),
            HrMetricCard(
              title: 'Present Today',
              value: hrText(data, 'present_today'),
              icon: Icons.verified_user_rounded,
              color: c.success,
              onTap: () => _showStatDetail(
                context,
                c,
                'Present Today',
                hrList(data, 'present_today_list'),
                c.success,
              ),
            ),
            HrMetricCard(
              title: 'Absent Today',
              value: hrText(data, 'absent_today'),
              icon: Icons.person_off_rounded,
              color: c.danger,
              onTap: () => _showStatDetail(
                context,
                c,
                'Absent Today',
                hrList(data, 'absent_today_list'),
                c.danger,
              ),
            ),
            HrMetricCard(
              title: 'On Leave',
              value: hrText(data, 'on_leave'),
              icon: Icons.beach_access_rounded,
              color: c.purple,
              onTap: () => _showStatDetail(
                context,
                c,
                'On Leave',
                hrList(data, 'on_leave_list'),
                c.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Quick Actions',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Action(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Create',
              color: c.primary,
              onTap: () => onOpen(1),
            ),
            _Action(
              icon: Icons.event_available_rounded,
              label: 'Approve Leave',
              color: c.warning,
              onTap: () => onOpen(4),
            ),
            _Action(
              icon: Icons.calendar_month_rounded,
              label: 'Attendance',
              color: c.success,
              onTap: () => onOpen(3),
            ),
            _Action(
              icon: Icons.work_outline_rounded,
              label: 'Recruitment',
              color: c.purple,
              onTap: () => onOpen(5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Upcoming',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...hrList(data, 'upcoming').map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.event_note_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['time']}',
              color: c.primary,
            ),
          ),
        ),
        if (hrList(data, 'notifications').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _notificationHeading(hrList(data, 'notifications')),
            style: TextStyle(
              color: c.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...hrList(data, 'notifications').map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(
                icon: _notificationIcon(item),
                title: '${item['title']}',
                subtitle: '${item['subtitle'] ?? item['message'] ?? ''}',
                trailing: '${item['time'] ?? item['trailing'] ?? ''}',
                color: _notificationColor(item, c),
                onTap: () => onNotificationTap(item),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 72,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 7),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HrProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _HrProfileAvatar({
    required this.image,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: c.primary.withAlpha(30),
        backgroundImage: image == null ? null : FileImage(image!),
        child: image == null
            ? Icon(Icons.person_rounded, color: c.primary, size: radius)
            : null,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final HrPalette colors;
  final String title;
  final VoidCallback onMenu;
  final VoidCallback onTheme;

  const _TopBar({
    required this.colors,
    required this.title,
    required this.onMenu,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.headerPadding,
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: Icon(Icons.menu_rounded, color: colors.text, size: 26),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 2),
          const BitByteLogo(compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onTheme,
            icon: Icon(
              colors.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HrRoleDropdown extends StatelessWidget {
  final HrPalette colors;
  final String value;
  final ValueChanged<String> onChanged;

  const _HrRoleDropdown({
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenGutter,
        0,
        AppLayout.screenGutter,
        AppLayout.compactGap,
      ),
      child: Container(
        height: AppLayout.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: colors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.primary,
            ),
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            selectedItemBuilder: (context) {
              return ['Employee', 'HR'].map((_) {
                return Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: colors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Role Based',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              }).toList();
            },
            items: const [
              DropdownMenuItem(
                value: 'Employee',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Employee'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'HR',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('HR'),
                  ],
                ),
              ),
            ],
            onChanged: (role) {
              if (role != null) onChanged(role);
            },
          ),
        ),
      ),
    );
  }
}

class _HrDrawer extends StatelessWidget {
  final Map<String, dynamic> data;
  final String email;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;
  final VoidCallback onClientVisits;

  const _HrDrawer({
    required this.data,
    required this.email,
    required this.onTap,
    required this.onLogout,
    required this.onClientVisits,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const BitByteLogo(compact: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HR Manager',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.add_location_alt_rounded,
                      color: c.primary,
                      size: 19,
                    ),
                    title: Text(
                      'Client Visits',
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: onClientVisits,
                  ),
                  ...List.generate(_titles.length, (index) {
                    return ListTile(
                    leading: Icon(_icons[index], color: c.primary, size: 19),
                    title: Text(
                      _titles[index],
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => onTap(index),
                    );
                  }),
                ],
              ),
            ),
            Divider(color: c.border),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final HrPalette colors;
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.colors,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [0, 2, 3, 10, 15];
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
      child: Row(
        children: items.map((itemIndex) {
          final selected = index == itemIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(itemIndex),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[itemIndex],
                      color: selected ? colors.primary : colors.muted,
                      size: 18,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        _titles[itemIndex],
                        style: TextStyle(
                          color: selected ? colors.primary : colors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

const _titles = [
  'Dashboard',
  'Registered Employee',
  'Employees',
  'Employee Attendance',
  'Leave Requests',
  'Recruitment',
  'Meetings',
  'Recruitment Pipeline',
  'Schedule Interview',
  'Onboarding',
  'Documents',
  'Performance',
  'Payroll',
  'Training',
  'Tasks',
  'Profile',
];

const _icons = [
  Icons.dashboard_rounded,
  Icons.person_add_alt_1_rounded,
  Icons.groups_rounded,
  Icons.calendar_month_rounded,
  Icons.beach_access_rounded,
  Icons.work_outline_rounded,
  Icons.event_rounded,
  Icons.filter_alt_rounded,
  Icons.video_call_rounded,
  Icons.assignment_ind_rounded,
  Icons.folder_rounded,
  Icons.insights_rounded,
  Icons.payments_rounded,
  Icons.school_rounded,
  Icons.task_alt_rounded,
  Icons.account_circle_rounded,
];
