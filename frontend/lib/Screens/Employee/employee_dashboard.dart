import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Services/push_notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'employee_attendance_screen.dart';
import 'employee_approvals_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_home_screen.dart';
import 'employee_leave_screen.dart';
import 'employee_meetings_screen.dart';
import 'employee_models.dart';
import 'employee_more_screen.dart';
import 'employee_notifications_screen.dart';
import 'employee_payslip_screen.dart';
import 'employee_service.dart';
import 'employee_shared.dart';
import 'employee_tasks_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;
  final String? roleSwitchLabel;
  final WidgetBuilder? roleSwitchBuilder;

  const EmployeeDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
    this.roleSwitchLabel,
    this.roleSwitchBuilder,
  });

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EmployeeService _service = EmployeeService();
  final ImagePicker _imagePicker = ImagePicker();
  late EmployeeDashboardData _data;
  int _selectedIndex = 0;
  final List<int> _tabHistory = [];
  bool _loading = true;
  String? _profileImagePath;
  Timer? _refreshTimer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data = EmployeeDashboardData.fallback(
      email: widget.email,
      firstName: widget.firstName,
      userId: widget.userId,
    );
    _load();
    unawaited(_registerForNotifications());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDashboardSilently(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_registerForNotifications());
      _refreshDashboardSilently();
    }
  }

  Future<void> _registerForNotifications() {
    return PushNotificationService.instance.registerForUser(
      widget.userId,
      'employee',
    );
  }

  Future<void> _refreshDashboardSilently() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final data = await _service.fetchDashboard(widget.userId, widget.email);
      if (!mounted) return;
      final existingIds = _data.notifications
          .map((item) => '${item['id'] ?? ''}')
          .toSet();
      Map<String, dynamic>? newApprovalNotification;
      for (final item in data.notifications) {
        if ('${item['module'] ?? ''}'.toLowerCase() == 'approval' &&
            item['is_read'] != true &&
            !existingIds.contains('${item['id'] ?? ''}')) {
          newApprovalNotification = item;
          break;
        }
      }
      setState(() => _data = data);
      if (newApprovalNotification != null && mounted) {
        final notification = newApprovalNotification;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notification['message'] ?? notification['title'] ?? 'Approval updated'}',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _openNotification(notification),
            ),
          ),
        );
      }
    } catch (_) {
      // Keep current dashboard data and retry on the next lifecycle/poll event.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var data = await _service.fetchDashboard(widget.userId, widget.email);
      final dashboardCheckIn = '${data.attendance['check_in'] ?? ''}'.trim();
      final dashboardHasAttendance =
          dashboardCheckIn.isNotEmpty &&
          dashboardCheckIn != '--' &&
          dashboardCheckIn != '--:--' &&
          dashboardCheckIn.toLowerCase() != 'null';
      if (!dashboardHasAttendance) {
        try {
          final today = DateTime.now();
          final history = await _service.fetchAttendanceHistory(
            widget.userId,
            today,
            today,
          );
          if (history.isNotEmpty) {
            final persistedAttendance = history.firstWhere(
              (record) => '${record['date'] ?? ''}' == _dateParam(today),
              orElse: () => history.first,
            );
            data = EmployeeDashboardData(
              profile: data.profile,
              attendance: persistedAttendance,
              leaveBalances: data.leaveBalances,
              leaves: data.leaves,
              notifications: data.notifications,
              meetings: data.meetings,
              tasks: data.tasks,
              payslip: data.payslip,
              documents: data.documents,
            );
          }
        } catch (_) {
          // Keep the dashboard response when attendance history is unavailable.
        }
      }
      if (mounted) {
        final backendPhoto = '${data.profile['doc_passport_photo'] ?? ''}'
            .trim();
        setState(() {
          _data = data;
          if ((_profileImagePath == null || _profileImagePath!.isEmpty) &&
              backendPhoto.isNotEmpty &&
              backendPhoto != 'null') {
            _profileImagePath = backendPhoto;
          }
        });
      }
    } catch (_) {
      // Fallback data keeps the employee screens usable while the backend is offline.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateParam(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _updateAttendance(Map<String, dynamic> result) {
    final attendance = Map<String, dynamic>.from(_data.attendance);
    attendance.addAll({
      if (result['status'] != null) 'status': result['status'],
      if (result['date'] != null) 'date': result['date'],
      if (result['check_in'] != null) 'check_in': result['check_in'],
      if (result['check_out'] != null) 'check_out': result['check_out'],
      if (result['working_hours'] != null)
        'working_hours': result['working_hours'],
      if (result['late_entry'] != null) 'late_entry': result['late_entry'],
      if (result['late_minutes'] != null)
        'late_minutes': result['late_minutes'],
      if (result['overtime'] != null) 'overtime': result['overtime'],
      if (result['overtime_minutes'] != null)
        'overtime_minutes': result['overtime_minutes'],
      if (result['regular_hours'] != null)
        'regular_hours': result['regular_hours'],
      if (result['shift_time'] != null) 'shift_time': result['shift_time'],
      if (result['lunch_time'] != null) 'lunch_time': result['lunch_time'],
      if (result['grace_time'] != null) 'grace_time': result['grace_time'],
      if (result['latitude'] != null) 'latitude': result['latitude'],
      if (result['longitude'] != null) 'longitude': result['longitude'],
      if (result['accuracy'] != null) 'accuracy': result['accuracy'],
      if (result['work_mode'] != null) 'work_mode': result['work_mode'],
      if (result['work_mode_label'] != null)
        'work_mode_label': result['work_mode_label'],
      if (result['selfie_file'] != null) 'selfie_file': result['selfie_file'],
    });

    setState(() {
      _data = EmployeeDashboardData(
        profile: _data.profile,
        attendance: attendance,
        leaveBalances: _data.leaveBalances,
        leaves: _data.leaves,
        notifications: _data.notifications,
        meetings: _data.meetings,
        tasks: _data.tasks,
        payslip: _data.payslip,
        documents: _data.documents,
      );
    });
  }

  void _logout() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );

  void _selectTab(int index, {bool remember = true}) {
    if (index == _selectedIndex) return;
    setState(() {
      if (remember) _tabHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  void _handleMobileBack() {
    if (_tabHistory.isNotEmpty) {
      _selectTab(_tabHistory.removeLast(), remember: false);
    } else if (_selectedIndex != 0) {
      _selectTab(0, remember: false);
    }
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _profileImagePath = image.path);
  }

  void _switchRole(String role) {
    final builder = widget.roleSwitchBuilder;
    if (role == widget.roleSwitchLabel && builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: builder));
    }
  }

  Future<void> _markNotificationRead(Map<String, dynamic> notification) async {
    final id = notification['id'];
    if (id == null || notification['is_read'] == true) return;
    try {
      await _service.markNotificationRead(widget.userId, id);
      await _refreshDashboardSilently();
    } catch (_) {
      // Opening the destination must remain available during a network retry.
    }
  }

  Future<void> _markAllNotificationsRead() async {
    final unread = _data.notifications
        .where((item) => item['is_read'] != true && item['id'] != null)
        .toList();
    await Future.wait(unread.map(_markNotificationRead));
    await _refreshDashboardSilently();
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    await _markNotificationRead(notification);
    if (!mounted) return;
    final module = '${notification['module'] ?? ''}'.toLowerCase();
    final title = '${notification['title'] ?? ''}'.toLowerCase();
    final message = '${notification['message'] ?? ''}'.toLowerCase();
    final text = '$module $title $message';

    if (text.contains('meeting')) {
      final meeting = _meetingForNotification(notification);
      if (meeting != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const AppBarLogoTitle(title: 'Meeting Details'),
              ),
              body: EmployeeMeetingDetailsScreen(meeting: meeting),
            ),
          ),
        );
        return;
      }
      _selectTab(4);
      return;
    }
    if (text.contains('leave')) {
      _selectTab(2);
      return;
    }
    if (text.contains('task')) {
      _openTasks();
      return;
    }
    if (text.contains('attendance') || text.contains('check in')) {
      _selectTab(1);
      return;
    }
    if (text.contains('approval')) {
      _selectTab(3);
      return;
    }
    _selectTab(4);
  }

  void _openEmployeeScreen(String title, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: AppBarLogoTitle(title: title)),
          body: screen,
        ),
      ),
    );
  }

  void _openNotifications() async {
    await _refreshDashboardSilently();
    if (!mounted) return;
    _openEmployeeScreen(
      'Notifications',
      EmployeeNotificationsScreen(
        data: _data,
        onMarkAllRead: _markAllNotificationsRead,
        onNotificationTap: (item) {
          Navigator.of(context).pop();
          _openNotification(item);
        },
      ),
    );
  }

  void _openMeetings() {
    _openEmployeeScreen(
      'Meetings',
      EmployeeMeetingsScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
      ),
    );
  }

  void _openTasks() {
    _openEmployeeScreen(
      'Tasks',
      EmployeeTasksScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
        onChanged: _load,
      ),
    );
  }

  void _openPayslip() {
    _openEmployeeScreen(
      'Payslip',
      EmployeePayslipScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
      ),
    );
  }

  void _openDocuments() {
    _openEmployeeScreen(
      'Documents',
      EmployeeDocumentsScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
        onUploaded: _load,
      ),
    );
  }

  Map<String, dynamic>? _meetingForNotification(
    Map<String, dynamic> notification,
  ) {
    final ref = '${notification['reference_id'] ?? notification['id'] ?? ''}'
        .trim();
    if (ref.isNotEmpty) {
      for (final meeting in _data.meetings) {
        if ('${meeting['id'] ?? ''}' == ref) return meeting;
      }
    }
    final message =
        '${notification['message'] ?? notification['subtitle'] ?? notification['title'] ?? ''}'
            .toLowerCase();
    for (final meeting in _data.meetings) {
      final title = '${meeting['title'] ?? ''}'.toLowerCase();
      if (title.isNotEmpty && message.contains(title)) return meeting;
    }
    return _data.meetings.isNotEmpty ? _data.meetings.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EmployeeHomeScreen(
        data: _data,
        onTabSelected: _selectTab,
        onNotificationTap: _openNotification,
        onOpenNotifications: _openNotifications,
        onOpenMeetings: _openMeetings,
        onOpenTasks: _openTasks,
        onOpenPayslip: _openPayslip,
        onOpenDocuments: _openDocuments,
        profileImagePath: _profileImagePath,
        onPickProfileImage: _pickProfileImage,
      ),
      EmployeeAttendanceScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
        onAttendanceMarked: _updateAttendance,
        profileImagePath: _profileImagePath,
      ),
      EmployeeLeaveScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
      ),
      EmployeeApprovalsScreen(userId: widget.userId, service: _service),
      EmployeeMoreScreen(
        userId: widget.userId,
        data: _data,
        service: _service,
        onLogout: _logout,
        onNotificationTap: _openNotification,
        onDocumentsChanged: _load,
      ),
    ];

    final profile = _data.profile;
    final employeeName = '${profile['name'] ?? widget.firstName}'.trim();
    final employeeId = '${profile['employee_id'] ?? widget.userId}'.trim();
    final designation = '${profile['designation'] ?? 'Employee'}'.trim();
    final department = '${profile['department'] ?? ''}'.trim();
    return PopScope<Object?>(
      canPop: _selectedIndex == 0 && _tabHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleMobileBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _EmployeeDrawer(
          name: employeeName.isEmpty ? 'Employee' : employeeName,
          employeeId: employeeId,
          designation: designation,
          department: department,
          profileImagePath: _profileImagePath,
          onPickProfileImage: _pickProfileImage,
          onSelect: (index) {
            Navigator.of(context).pop();
            _selectTab(index);
            if (index == 0) _load();
          },
          onLogout: _logout,
        ),
        body: ConstellationBackground(
          accentColor: EmployeeColors.blue,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 14, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        icon: Icon(
                          Icons.menu_rounded,
                          color: ThemeConfig.getTextPrimary(context),
                          size: 26,
                        ),
                        tooltip: 'Menu',
                      ),
                      const SizedBox(width: 2),
                      const BitByteLogo(compact: true),
                      const SizedBox(width: 10),
                      Text(
                        'HRMS',
                        style: TextStyle(
                          color: ThemeConfig.getTextPrimary(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      IconButton(
                        tooltip: 'Toggle Theme',
                        icon: Icon(
                          ThemeConfig.isDark(context)
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: EmployeeColors.blue,
                        ),
                        onPressed: () {
                          MyApp.themeNotifier.value =
                              MyApp.themeNotifier.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                if (widget.roleSwitchLabel != null &&
                    widget.roleSwitchBuilder != null)
                  _EmployeeRoleDropdown(
                    value: 'Employee',
                    alternateRole: widget.roleSwitchLabel!,
                    onChanged: _switchRole,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: pages[_selectedIndex],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withAlpha(80),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          _navItem(
                            0,
                            Icons.dashboard_outlined,
                            Icons.dashboard_rounded,
                            'Dashboard',
                          ),
                          _navItem(
                            1,
                            Icons.access_time_outlined,
                            Icons.access_time_filled_rounded,
                            'Attendance',
                          ),
                          _navItem(
                            2,
                            Icons.beach_access_outlined,
                            Icons.beach_access_rounded,
                            'Leave',
                          ),
                          _navItem(
                            3,
                            Icons.approval_outlined,
                            Icons.approval_rounded,
                            'Approvals',
                          ),
                          _navItem(
                            4,
                            Icons.more_horiz_rounded,
                            Icons.more_rounded,
                            'More',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          _selectTab(index);
          if (index == 0) _load();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? EmployeeColors.blue : Colors.grey,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeRoleDropdown extends StatelessWidget {
  final String value;
  final String alternateRole;
  final ValueChanged<String> onChanged;

  const _EmployeeRoleDropdown({
    required this.value,
    required this.alternateRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: cardBg,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: EmployeeColors.blue,
            ),
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            selectedItemBuilder: (context) {
              return [value, alternateRole].map((_) {
                return Row(
                  children: [
                    const Icon(
                      Icons.manage_accounts_outlined,
                      color: EmployeeColors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Role Based',
                      style: TextStyle(
                        color: textSecondary,
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
            items: [
              const DropdownMenuItem(
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
                value: alternateRole,
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(alternateRole),
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

class _EmployeeDrawer extends StatelessWidget {
  final String name;
  final String employeeId;
  final String designation;
  final String department;
  final String? profileImagePath;
  final VoidCallback onPickProfileImage;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _EmployeeDrawer({
    required this.name,
    required this.employeeId,
    required this.designation,
    required this.department,
    required this.profileImagePath,
    required this.onPickProfileImage,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final drawerBg = ThemeConfig.getCardBg(context);
    final borderColor = ThemeConfig.getCardBorder(context);
    final avatarBg = isDark ? const Color(0xFF0A3359) : const Color(0xFFEAF7FF);
    final menuTextColor = isDark ? Colors.white : const Color(0xFF1F3654);
    final mutedTextColor = isDark ? Colors.white70 : const Color(0xFF607086);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: drawerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: menuTextColor),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png', width: 58, height: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'HRMS',
                        style: TextStyle(
                          color: menuTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: mutedTextColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    InkWell(
                      onTap: onPickProfileImage,
                      borderRadius: BorderRadius.circular(34),
                      child: Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(2.5),
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
                            color: avatarBg,
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
                              profileImagePath == null ||
                                  profileImagePath!.isEmpty
                              ? const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: EmployeeColors.blue,
                                  size: 22,
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: menuTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employeeId,
                            style: const TextStyle(
                              color: EmployeeColors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                          if (department.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              department,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: borderColor),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      _DrawerItem(
                        icon: Icons.home_rounded,
                        title: 'Dashboard',
                        color: EmployeeColors.blue,
                        selected: true,
                        onTap: () => onSelect(0),
                      ),
                      _DrawerItem(
                        icon: Icons.access_time_rounded,
                        title: 'Attendance',
                        color: EmployeeColors.red,
                        onTap: () => onSelect(1),
                      ),
                      _DrawerItem(
                        icon: Icons.beach_access_rounded,
                        title: 'Leave',
                        color: EmployeeColors.blue,
                        onTap: () => onSelect(2),
                      ),
                      _DrawerItem(
                        icon: Icons.approval_rounded,
                        title: 'Approvals',
                        color: EmployeeColors.purple,
                        onTap: () => onSelect(3),
                      ),
                      _DrawerItem(
                        icon: Icons.payments_rounded,
                        title: 'Payslip',
                        color: EmployeeColors.purple,
                        onTap: () => onSelect(4),
                      ),
                      _DrawerItem(
                        icon: Icons.description_rounded,
                        title: 'Documents',
                        color: EmployeeColors.gold,
                        onTap: () => onSelect(4),
                      ),
                      _DrawerItem(
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        color: EmployeeColors.blue,
                        onTap: () => onSelect(4),
                      ),
                      const SizedBox(height: 6),
                      Divider(color: borderColor),
                      _DrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        color: EmployeeColors.red,
                        danger: true,
                        onTap: onLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'App Version 1.0.0',
                  style: TextStyle(color: mutedTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.selected = false,
    this.danger = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F3654);
    final selectedBg = isDark ? color.withAlpha(42) : const Color(0xFFF5FAFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedBg : null,
            borderRadius: BorderRadius.circular(10),
            border: selected && !isDark
                ? Border.all(color: color.withAlpha(42))
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 4 : 0,
                height: 24,
                margin: EdgeInsets.only(right: selected ? 10 : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(
                  selected ? (isDark ? 48 : 28) : (isDark ? 30 : 18),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: danger ? EmployeeColors.red : textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: EmployeeColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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
