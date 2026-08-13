import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/logout_exit_dialog.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/user_notification_settings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_module_tabs.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_dashboard.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientVisits/client_visit_screens.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_approvals_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/TL/tl_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/TL/tl_shared.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

class TLDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const TLDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<TLDashboard> createState() => _TLDashboardState();
}

class _TLDashboardState extends State<TLDashboard> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<Map<String, dynamic>> _future;
  int _index = 0;
  final List<int> _navigationHistory = [];
  String _role = 'Team Lead';
  Map<String, dynamic> _selected = {};
  File? _profileImage;
  Timer? _notificationRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = TlService().fetchDashboard(widget.userId);
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDashboard(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDashboard();
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  void _openDetail(int index, Map<String, dynamic> item) {
    setState(() {
      if (index != _index) _navigationHistory.add(_index);
      _selected = item;
      _index = index;
    });
  }

  void _refreshDashboard() {
    if (!mounted) return;
    setState(() {
      _future = TlService().fetchDashboard(widget.userId);
    });
  }

  void _openBackendSection(int index) {
    setState(() {
      _future = TlService().fetchDashboard(widget.userId);
      if (index != _index) _navigationHistory.add(_index);
      _index = index;
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
            roleSwitchLabel: 'Team Lead',
            roleSwitchBuilder: (_) => TLDashboard(
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

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
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
            final failed = snapshot.hasError;
            final pages = [
              _Dashboard(
                data: data,
                name: widget.firstName,
                email: widget.email,
                userId: widget.userId,
                profileImage: _profileImage,
                onProfileTap: _pickProfileImage,
                open: _openBackendSection,
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                retry: _refreshDashboard,
                onChanged: _refreshDashboard,
              ),
              _Team(data: data, open: (item) => _openDetail(18, item)),
              _Tasks(
                data: data,
                open: (item) => _openDetail(14, item),
                create: () => _setIndex(15),
              ),
              _Projects(data: data, open: (item) => _openDetail(16, item)),
              _Attendance(
                data: data,
                openSelfie: () => _setIndex(5),
                openReport: () => _setIndex(11),
              ),
              _Selfie(openNext: () => _setIndex(6)),
              _GeoLocation(data: data, openNext: () => _setIndex(7)),
              _ConfirmAttendance(data: data, openNext: () => _setIndex(8)),
              _AttendanceMarked(data: data, openAttendance: () => _setIndex(4)),
              _Leave(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
              ),
              _Meetings(
                data: data,
                userId: widget.userId,
                email: widget.email,
                open: (item) => _openDetail(18, item),
                scheduled: _refreshDashboard,
              ),
              _Reports(
                data: data,
                open: (item) => _openDetail(18, item),
                menu: () => _scaffoldKey.currentState?.openDrawer(),
                theme: _toggleTheme,
              ),
              _Approvals(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
              ),
              _Notifications(
                data: data,
                userId: widget.userId,
                onChanged: _refreshDashboard,
                openApprovals: () => _setIndex(12),
              ),
              _TaskDetails(item: _selected, update: () => _setIndex(2)),
              _CreateTask(
                data: data,
                userId: widget.userId,
                onBack: () => _setIndex(2),
                onTheme: _toggleTheme,
                onCreated: () {
                  _refreshDashboard();
                  _setIndex(2);
                },
              ),
              _ProjectDetails(item: _selected, openTasks: () => _setIndex(2)),
              _TeamPerformance(data: data),
              _SmartDetails(item: _selected),
              _Profile(
                userId: widget.userId,
                email: widget.email,
                name: widget.firstName,
                profileImage: _profileImage,
                onProfileTap: _pickProfileImage,
                logout: () =>
                    showLogoutConfirmation(context: context, onLogout: _logout),
              ),
              ClientVisitDashboardScreen(
                userId: widget.userId,
                reviewerMode: true,
                requesterRole: 'tl',
              ),
            ];
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: c.bg,
              drawer: _Drawer(
                email: widget.email,
                name: widget.firstName,
                select: _setIndex,
                logout: () =>
                    showLogoutConfirmation(context: context, onLogout: _logout),
                openClientVisits: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClientVisitModuleScreen(
                        userId: widget.userId,
                        roleLabel: 'Team Lead · Create & Approve',
                        reviewerMode: true,
                        requesterRole: 'tl',
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
                      if (_index != 15 && _index != 11)
                        _TopBar(
                          c: c,
                          title: _titles[_index],
                          menu: () => _scaffoldKey.currentState?.openDrawer(),
                          theme: _toggleTheme,
                        ),
                      if (_index == 0)
                        _TlRoleDropdown(
                          c: c,
                          value: _role,
                          onChanged: _switchRole,
                        ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        LinearProgressIndicator(
                          minHeight: 2,
                          color: c.primary,
                          backgroundColor: Colors.transparent,
                        ),
                      if (failed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                          child: TlCard(
                            child: Text(
                              'Unable to load data. Please try again.',
                              style: TextStyle(
                                color: c.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      Expanded(child: pages[_index]),
                      _BottomNav(c: c, index: _index, select: _setIndex),
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
}

class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final String email;
  final String userId;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final ValueChanged<int> open;
  final bool loading;
  final Object? error;
  final VoidCallback retry;
  final VoidCallback onChanged;

  const _Dashboard({
    required this.data,
    required this.name,
    required this.email,
    required this.userId,
    required this.profileImage,
    required this.onProfileTap,
    required this.open,
    required this.loading,
    required this.error,
    required this.retry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final meetings = tlList(data, 'meetings');
    final unreadNotifications = tlList(
      data,
      'notifications',
    ).where((item) => item['is_read'] != true).toList();
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        if (loading)
          TlCard(
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Loading TL backend data...',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (error != null)
          TlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TL backend not reachable',
                  style: TextStyle(
                    color: c.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (loading || error != null) const SizedBox(height: 12),
        Row(
          children: [
            _ProfileAvatar(
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
                    name.trim(),
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
        const SizedBox(height: 14),
        _CompactApprovalInbox(
          data: data,
          userId: userId,
          unreadCount: unreadNotifications.length,
          openAll: () => open(12),
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _Metric(
              'My Tasks',
              tlText(data, 'my_tasks'),
              c.primary,
              Icons.task_alt_rounded,
              () => open(2),
            ),
            _Metric(
              'Total Employees',
              tlText(data, 'total_employees'),
              c.success,
              Icons.groups_rounded,
              () => open(1),
            ),
            _Metric(
              'Projects',
              tlText(data, 'projects_count'),
              c.purple,
              Icons.work_rounded,
              () => open(3),
            ),
            _Metric(
              'Pending Approvals',
              tlText(data, 'pending_approvals'),
              c.danger,
              Icons.approval_rounded,
              () => open(12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Quick Actions',
          style: TextStyle(
            color: c.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _DashboardQuickAction(
              icon: Icons.groups_rounded,
              label: 'Team',
              color: c.success,
              onTap: () => open(1),
            ),
            _DashboardQuickAction(
              icon: Icons.task_alt_rounded,
              label: 'Tasks',
              color: c.primary,
              onTap: () => open(2),
            ),
            _DashboardQuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Attendance',
              color: c.warning,
              onTap: () => open(4),
            ),
            _DashboardQuickAction(
              icon: Icons.approval_rounded,
              label: 'Approvals',
              color: c.danger,
              onTap: () => open(12),
            ),
            _DashboardQuickAction(
              icon: Icons.add_location_alt_rounded,
              label: 'Client Visits',
              color: c.purple,
              onTap: () => open(20),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (meetings.isNotEmpty) ...[
          _Section(
            title: 'Meetings',
            action: 'View All',
            onTap: () => open(10),
          ),
          ...meetings.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TlListTile(
                icon: Icons.event_rounded,
                title: '${item['title'] ?? 'Meeting'}',
                subtitle: '${item['subtitle'] ?? item['description'] ?? ''}',
                trailing: '${item['time'] ?? item['date_label'] ?? ''}',
                color: c.warning,
                onTap: () => open(10),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 14),
        _Section(
          title: 'Tasks Overview',
          action: 'View All',
          onTap: () => open(2),
        ),
        _ProgressCard(
          value: tlPercent(data, 'tasks_progress'),
          label:
              '${tlText(data, 'tasks_done')} done / ${tlText(data, 'tasks_total')} assigned',
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Team Performance',
          action: 'View',
          onTap: () => open(17),
        ),
        _ProgressCard(
          value: tlPercent(data, 'team_progress'),
          label:
              '${tlText(data, 'on_track')} employee(s) on track by task completion',
        ),
      ],
    );
  }
}

class _DashboardQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}

class _CompactApprovalInbox extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;
  final int unreadCount;
  final VoidCallback openAll;
  final VoidCallback onChanged;

  const _CompactApprovalInbox({
    required this.data,
    required this.userId,
    required this.unreadCount,
    required this.openAll,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final approvals = tlList(data, 'approvals');
    return TlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.inbox_rounded, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Inbox',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${approvals.length} awaiting action${unreadCount > 0 ? ' · $unreadCount unread' : ''}',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: openAll, child: const Text('View all')),
            ],
          ),
          if (approvals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'No employee requests need your action.',
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            ...approvals.take(3).map((item) {
              final approvalType = '${item['approval_type'] ?? ''}';
              final label = switch (approvalType) {
                'daily_report' => 'Daily Report',
                'social_media_post' => 'Social Media Post',
                'leave_request' => 'Leave Request',
                _ => '${item['leave_type'] ?? 'Employee Request'}',
              };
              return InkWell(
                onTap: approvalType.isEmpty
                    ? openAll
                    : () => _openTlApprovalNotification(context, data, userId, {
                        'reference_id': '${item['id'] ?? ''}',
                        'module': 'approval',
                      }, onChanged),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: c.warning.withAlpha(25),
                        child: Icon(
                          Icons.description_outlined,
                          color: c.warning,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['title'] ?? item['name'] ?? 'Approval request'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$label · ${item['employee_id'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.muted),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ApprovalBoard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback open;
  final String userId;
  final VoidCallback onChanged;

  const _ApprovalBoard({
    required this.data,
    required this.open,
    required this.userId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final pending = tlList(data, 'approvals');
    final approved = tlList(data, 'leaves_approved');
    final rejected = tlList(data, 'leaves_rejected');
    final urgent = pending.where((item) => _approvalIsUrgent(item)).toList();
    final items = pending.take(4).toList();
    return TlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Leave Approvals',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.warning,
                  side: BorderSide(color: c.warning),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 40),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: open,
                child: const Text('View All Approvals'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ApprovalMini(
                  'Pending',
                  '${pending.length}',
                  'Needs Action',
                  c.warning,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ApprovalMini(
                  'Urgent',
                  '${urgent.length}',
                  'Due Soon',
                  c.danger,
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ApprovalMini(
                  'Approved Today',
                  '${approved.length}',
                  'Good Job!',
                  c.success,
                  Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ApprovalMini(
                  'Rejected Today',
                  '${rejected.length}',
                  'No Rejections',
                  c.purple,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No approvals need your action',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            ...items.map(
              (item) => _ApprovalCompactRow(
                item: item,
                onViewAll: open,
                userId: userId,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaveDetailPage extends StatefulWidget {
  final Map<String, dynamic> leave;
  final String userId;
  final VoidCallback onChanged;

  const _LeaveDetailPage({
    required this.leave,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<_LeaveDetailPage> {
  late Map<String, dynamic> _leave;
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _leave = widget.leave;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = int.tryParse('${_leave['id'] ?? ''}');
    if (id == null) return;
    try {
      final response = await TlService().fetchLeaveRequest(id);
      final detail = response['leave'];
      if (mounted && detail is Map) {
        setState(() => _leave = Map<String, dynamic>.from(detail));
      }
    } catch (_) {}
  }

  Future<void> _decide(String status, {String rejectionReason = ''}) async {
    final id = int.tryParse('${_leave['id'] ?? ''}');
    if (id == null || _savingId != null) return;
    setState(() => _savingId = id);
    try {
      await TlService().updateLeaveRequest(
        id,
        status,
        widget.userId,
        rejectionReason: rejectionReason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave ${status == 'approved' ? 'approved' : 'rejected'} by TL',
          ),
        ),
      );
      widget.onChanged();
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  Future<void> _confirmApprove() async {
    final approved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveConfirmation(leave: _leave),
    );
    if (approved == true) await _decide('approved');
  }

  Future<void> _confirmReject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectRequestDialog(leave: _leave),
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await _decide('rejected', rejectionReason: reason.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final saving = _savingId != null;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: _ApprovalDetails(
          leave: _leave,
          saving: saving,
          back: () => Navigator.of(context).pop(),
          approve: _confirmApprove,
          reject: _confirmReject,
        ),
      ),
    );
  }
}

class _ApprovalMini extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  const _ApprovalMini(
    this.title,
    this.value,
    this.caption,
    this.color,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ApprovalCompactRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onViewAll;
  final String userId;
  final VoidCallback onChanged;

  const _ApprovalCompactRow({
    required this.item,
    required this.onViewAll,
    required this.userId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final urgent = _approvalIsUrgent(item);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _LeaveDetailPage(
            leave: item,
            userId: userId,
            onChanged: onChanged,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _InitialAvatar(text: '${item['initials'] ?? ''}', size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['name'] ?? 'Employee'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${item['employee_id'] ?? ''}',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '${item['leave_type'] ?? 'Leave Request'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (urgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: c.danger.withAlpha(24),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c.danger.withAlpha(80)),
                ),
                child: Text(
                  'Urgent',
                  style: TextStyle(
                    color: c.danger,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Team extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;

  const _Team({required this.data, required this.open});

  @override
  State<_Team> createState() => _TeamState();
}

class _TeamState extends State<_Team> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = tlList(widget.data, 'team');
    final query = _search.text.trim().toLowerCase();
    final visible = team
        .where(
          (item) =>
              '${item['title'] ?? item['name'] ?? ''} ${item['designation'] ?? item['subtitle'] ?? ''}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactOverviewTile(
                icon: Icons.groups_2_rounded,
                label: 'Team Members',
                value: '${team.length}',
                color: c.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactOverviewTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Active',
                value:
                    '${team.where((item) => !'${item['status'] ?? ''}'.toLowerCase().contains('inactive')).length}',
                color: c.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.text, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search employees...',
            hintStyle: TextStyle(color: c.muted),
            prefixIcon: Icon(Icons.search_rounded, color: c.muted),
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          TlCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  query.isEmpty
                      ? 'No employees are assigned under this TL yet.'
                      : 'No matching employees found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
        else
          ...visible.map(
            (item) => TlListTile(
              icon: Icons.person_rounded,
              title: '${item['title'] ?? item['name']}',
              subtitle: '${item['designation'] ?? item['subtitle'] ?? ''}',
              trailing: '${item['trailing'] ?? item['status'] ?? ''}',
              color: c.primary,
              onTap: () => widget.open(item),
            ),
          ),
      ],
    );
  }
}

class _Tasks extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback create;

  const _Tasks({required this.data, required this.open, required this.create});

  @override
  State<_Tasks> createState() => _TasksState();
}

class _TasksState extends State<_Tasks> {
  String _filter = 'All';
  String _priorityFilter = 'All';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final tasks = tlList(widget.data, 'tasks');
    final inProgress = tasks
        .where((item) => _taskStatus(item) == 'in progress')
        .length;
    final today = DateTime.now();
    final todayText =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final dueToday = tasks
        .where((item) => '${item['due'] ?? ''}'.startsWith(todayText))
        .length;
    final query = _search.text.trim().toLowerCase();
    final visible = tasks.where((item) {
      final status = _taskStatus(item);
      final matchesTab =
          _filter == 'All' ||
          (_filter == 'Assigned' && status != 'completed') ||
          (_filter == 'Completed' && status == 'completed');
      final matchesSearch =
          query.isEmpty ||
          '${item['title'] ?? ''} ${item['assignee'] ?? ''} ${item['project'] ?? ''}'
              .toLowerCase()
              .contains(query);
      final priority = '${item['priority'] ?? item['trailing'] ?? ''}';
      final matchesPriority =
          _priorityFilter == 'All' ||
          priority.toLowerCase() == _priorityFilter.toLowerCase();
      return matchesTab && matchesSearch && matchesPriority;
    }).toList();
    final priorities = <String>{
      'All',
      ...tasks
          .map((item) => '${item['priority'] ?? item['trailing'] ?? ''}'.trim())
          .where((value) => value.isNotEmpty),
    }.toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 86),
          children: [
            Row(
              children: [
                Expanded(
                  child: _TaskCount(
                    label: 'Total',
                    value: tasks.length,
                    color: c.primary,
                    icon: Icons.assignment_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TaskCount(
                    label: 'In Progress',
                    value: inProgress,
                    color: c.success,
                    icon: Icons.donut_large_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TaskCount(
                    label: 'Due Today',
                    value: dueToday,
                    color: c.purple,
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: c.text, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search tasks or employees...',
                hintStyle: TextStyle(color: c.muted),
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                suffixIcon: query.isEmpty
                    ? PopupMenuButton<String>(
                        tooltip: 'Filter task priority',
                        icon: Icon(Icons.tune_rounded, color: c.muted),
                        onSelected: (value) =>
                            setState(() => _priorityFilter = value),
                        itemBuilder: (_) => priorities
                            .map(
                              (value) => PopupMenuItem(
                                value: value,
                                child: Row(
                                  children: [
                                    if (_priorityFilter == value)
                                      Icon(
                                        Icons.check_rounded,
                                        color: c.primary,
                                        size: 17,
                                      )
                                    else
                                      const SizedBox(width: 17),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(value)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_priorityFilter != 'All') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('Priority: $_priorityFilter'),
                  onDeleted: () => setState(() => _priorityFilter = 'All'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: ['All', 'Assigned', 'Completed'].map((label) {
                final selected = _filter == label;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _filter = label),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? c.primary : c.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? c.primary : c.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              TlCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: c.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_add,
                          color: c.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        query.isNotEmpty
                            ? 'No matching tasks'
                            : (_filter == 'All'
                                  ? 'No tasks assigned yet'
                                  : 'No $_filter tasks'),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assign a task to an employee reporting to you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: widget.create,
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Assign First Task'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...visible.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TlTaskCard(
                    item: item,
                    onTap: () => widget.open(item),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: FloatingActionButton(
            onPressed: widget.create,
            backgroundColor: c.primary,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  String _taskStatus(Map<String, dynamic> item) =>
      '${item['status'] ?? 'Pending'}'.trim().toLowerCase().replaceAll(
        '_',
        ' ',
      );
}

class _TaskCount extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _TaskCount({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Text(
                '$value',
                style: TextStyle(
                  color: c.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TlTaskCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _TlTaskCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final priority = '${item['priority'] ?? item['trailing'] ?? 'Medium'}';
    final status = '${item['status'] ?? 'Pending'}';
    final priorityColor =
        priority.toLowerCase() == 'urgent' || priority.toLowerCase() == 'high'
        ? c.danger
        : priority.toLowerCase() == 'low'
        ? c.success
        : c.warning;
    final assignee = '${item['assignee'] ?? 'Unassigned'}';
    final progress = status.toLowerCase().contains('complete')
        ? 1.0
        : status.toLowerCase().contains('progress')
        ? .5
        : .2;

    return TlCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item['title'] ?? 'Untitled Task'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if ('${item['project'] ?? item['subtitle'] ?? ''}'
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '${item['project'] ?? item['subtitle']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: c.primary.withAlpha(25),
                child: Text(
                  assignee.isEmpty ? '?' : assignee[0].toUpperCase(),
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  assignee,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: c.muted, size: 13),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Due: ${item['due'] ?? 'No due date'}',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: c.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 82,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    color: c.primary,
                    backgroundColor: c.border,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Projects extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;

  const _Projects({required this.data, required this.open});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(
      title: 'Project Portfolio',
      items: tlList(data, 'projects'),
      icon: Icons.work_rounded,
      color: c.primary,
      onTap: open,
    );
  }
}

class _Attendance extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback openSelfie;
  final VoidCallback openReport;

  const _Attendance({
    required this.data,
    required this.openSelfie,
    required this.openReport,
  });

  @override
  State<_Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<_Attendance> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = tlList(widget.data, 'team');
    final query = _search.text.trim().toLowerCase();
    final visible = team.where((item) {
      if (query.isEmpty) return true;
      return '${item['title'] ?? ''} ${item['id'] ?? ''} ${item['department'] ?? ''} ${item['designation'] ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final present = team.fold<int>(
      0,
      (sum, item) =>
          sum + (int.tryParse('${_summary(item)['present'] ?? 0}') ?? 0),
    );
    final late = team.fold<int>(
      0,
      (sum, item) =>
          sum + (int.tryParse('${_summary(item)['late'] ?? 0}') ?? 0),
    );
    final absent = team.fold<int>(
      0,
      (sum, item) =>
          sum + (int.tryParse('${_summary(item)['absent'] ?? 0}') ?? 0),
    );
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                'Present',
                '$present',
                c.success,
                Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                'Late',
                '$late',
                c.warning,
                Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                'Absent',
                '$absent',
                c.danger,
                Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Attendance',
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tlText(widget.data, 'check_in'),
                style: TextStyle(
                  color: c.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                tlText(widget.data, 'location'),
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.text, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search employee attendance...',
            hintStyle: TextStyle(color: c.muted),
            prefixIcon: Icon(Icons.search_rounded, color: c.muted),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          TlCard(
            child: Center(
              child: Text(
                team.isEmpty
                    ? 'No employees are assigned under this TL yet.'
                    : 'No matching attendance data.',
                style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
              ),
            ),
          )
        else
          ...visible.map((item) => _attendanceEmployeeTile(context, item)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: widget.openSelfie,
                child: const Text('My Check-In / Out'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.openReport,
                child: const Text('View Full Report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _summary(Map<String, dynamic> item) =>
      item['attendance_summary'] is Map
      ? Map<String, dynamic>.from(item['attendance_summary'] as Map)
      : <String, dynamic>{};

  Widget _attendanceEmployeeTile(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final c = TlPalette.of(context);
    final summary = _summary(item);
    final recent = item['recent_attendance'] is List
        ? (item['recent_attendance'] as List)
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList()
        : <Map<String, dynamic>>[];
    final latest = recent.isNotEmpty ? recent.first : <String, dynamic>{};
    final status = '${latest['status'] ?? 'No data'}';
    final statusColor = status.toLowerCase().contains('late')
        ? c.warning
        : status.toLowerCase().contains('absent')
        ? c.danger
        : status == 'No data'
        ? c.muted
        : c.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TlCard(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withAlpha(30),
                  child: Icon(Icons.person_rounded, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['title'] ?? item['name'] ?? 'Employee'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${item['id'] ?? item['trailing'] ?? ''} • ${item['designation'] ?? item['subtitle'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TinyMetric(
                    'Present',
                    '${summary['present'] ?? 0}',
                    c.success,
                  ),
                ),
                Expanded(
                  child: _TinyMetric(
                    'Late',
                    '${summary['late'] ?? 0}',
                    c.warning,
                  ),
                ),
                Expanded(
                  child: _TinyMetric(
                    'Absent',
                    '${summary['absent'] ?? 0}',
                    c.danger,
                  ),
                ),
              ],
            ),
            if (latest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${latest['date'] ?? ''} • In: ${latest['check_in'] ?? '--'} • Out: ${latest['check_out'] ?? '--'}',
                style: TextStyle(
                  color: c.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Selfie extends StatelessWidget {
  final VoidCallback openNext;
  const _Selfie({required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: c.primary.withAlpha(30),
                child: Icon(Icons.face_rounded, color: c.primary, size: 70),
              ),
              const SizedBox(height: 12),
              Text(
                'Please ensure your face is clearly visible',
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: openNext,
          child: const Text('Capture Photo'),
        ),
      ],
    );
  }
}

class _GeoLocation extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openNext;
  const _GeoLocation({required this.data, required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            children: [
              Container(
                height: 190,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.row,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: c.primary,
                  size: 54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tlText(data, 'location'),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w900),
              ),
              Text(
                'Accuracy: ${tlText(data, 'accuracy')}',
                style: TextStyle(color: c.success, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: openNext,
          child: const Text('Confirm Location'),
        ),
      ],
    );
  }
}

class _ConfirmAttendance extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openNext;
  const _ConfirmAttendance({required this.data, required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Info('Check In Time', tlText(data, 'check_in')),
              _Info('Location', tlText(data, 'location')),
              _Info('Work Type', tlText(data, 'work_type')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: openNext,
          child: const Text('Confirm Check-In'),
        ),
      ],
    );
  }
}

class _AttendanceMarked extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openAttendance;
  const _AttendanceMarked({required this.data, required this.openAttendance});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: c.success,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Checked In Successfully!',
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                tlText(data, 'location'),
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: openAttendance,
          child: const Text('View Attendance'),
        ),
      ],
    );
  }
}

class _Leave extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;
  const _Leave({
    required this.data,
    required this.userId,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return _LeaveApprovalList(
      pending: tlList(data, 'leaves'),
      approved: tlList(data, 'leaves_approved'),
      rejected: tlList(data, 'leaves_rejected'),
      userId: userId,
      onChanged: onChanged,
    );
  }
}

class _Meetings extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final String email;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback scheduled;
  const _Meetings({
    required this.data,
    required this.userId,
    required this.email,
    required this.open,
    required this.scheduled,
  });

  @override
  State<_Meetings> createState() => _MeetingsState();
}

class _MeetingsState extends State<_Meetings> {
  final _title = TextEditingController();
  final _link = TextEditingController();
  final _agenda = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _duration = '30 Minutes';
  String _platform = 'Zoom';
  String? _employeeId;
  bool _inviteEmail = true;
  bool _inviteSms = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    _agenda.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _schedule() async {
    final employee = _selectedEmployee;
    if (_title.text.trim().isEmpty ||
        employee == null ||
        _agenda.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter title, attendee, and agenda.'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (!scheduledAt.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting date and time must be in the future.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final link = _link.text.trim().isEmpty
          ? _generatedMeetingLink
          : _link.text.trim();
      await TlService().scheduleMeeting({
        'title': _title.text.trim(),
        'platform': _platform,
        'meeting_type': _platform,
        'meeting_link': link,
        'location': link,
        'description': _agenda.text.trim(),
        'date_label':
            '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}',
        'time_label': _time.format(context),
        'duration': _duration,
        'status': 'upcoming',
        'participants': [employee],
        'agenda': _agendaItems,
        'invite_email': _inviteEmail,
        'invite_sms': _inviteSms,
        'created_by': widget.userId.isNotEmpty ? widget.userId : widget.email,
      });
      _title.clear();
      _link.clear();
      _agenda.clear();
      _employeeId = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting scheduled and invitations sent'),
          ),
        );
        widget.scheduled();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = _uniqueTeam(tlList(widget.data, 'team'));
    final selectedEmployeeId =
        team.any((item) => _employeeKey(item) == _employeeId)
        ? _employeeId
        : null;
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        _MeetingInputCard(
          title: 'Meeting Title',
          isRequired: true,
          child: _MeetingTextField(
            controller: _title,
            hint: 'Enter meeting title',
            icon: Icons.edit_square,
            color: c.purple,
          ),
        ),
        _MeetingInputCard(
          title: 'Add Attendees',
          isRequired: true,
          footer: '${selectedEmployeeId == null ? 0 : 1} attendee selected',
          child: Row(
            children: [
              Expanded(
                child: AppDropdownButtonFormField<String>(
                  value: selectedEmployeeId,
                  isExpanded: true,
                  dropdownColor: c.surface,
                  hint: Text(
                    team.isEmpty
                        ? 'No employees under you'
                        : 'Select employees under you',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  items: team
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: _employeeKey(item),
                          child: Text(
                            _employeeName(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (_) => team
                      .map(
                        (item) => Text(
                          _employeeName(item),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _employeeId = value),
                  decoration: _meetingFieldDecoration(
                    context,
                    Icons.group_add_rounded,
                    c.purple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _MeetingIconButton(
                icon: Icons.person_add_alt_1_rounded,
                color: c.muted,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _MeetingInputCard(
                title: 'Date',
                isRequired: true,
                child: _MeetingSelectButton(
                  icon: Icons.calendar_month_rounded,
                  color: c.purple,
                  text: _meetingDateLabel(_date),
                  onTap: _pickDate,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MeetingInputCard(
                title: 'Time',
                isRequired: true,
                child: _MeetingSelectButton(
                  icon: Icons.schedule_rounded,
                  color: c.purple,
                  text: _time.format(context),
                  onTap: _pickTime,
                ),
              ),
            ),
          ],
        ),
        _MeetingInputCard(
          title: 'Duration',
          isRequired: true,
          child: AppDropdownButtonFormField<String>(
            value: _duration,
            dropdownColor: c.surface,
            items: _durationOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => _duration = value ?? _duration),
            decoration: _meetingFieldDecoration(
              context,
              Icons.schedule_rounded,
              c.purple,
            ),
          ),
        ),
        _MeetingInputCard(
          title: 'Meeting Platform',
          isRequired: true,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.75,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: _platforms
                .map(
                  (item) => _PlatformTile(
                    item: item,
                    active: _platform == item.label,
                    onTap: () => setState(() => _platform = item.label),
                  ),
                )
                .toList(),
          ),
        ),
        _MeetingInputCard(
          title: 'Meeting Link',
          child: _MeetingTextField(
            controller: _link,
            hint: 'Meeting link (optional)',
            icon: Icons.link_rounded,
            color: c.purple,
            helper:
                'Add link if already created. Otherwise it will be generated.',
          ),
        ),
        _MeetingInputCard(
          title: 'Agenda',
          isRequired: true,
          child: _MeetingTextField(
            controller: _agenda,
            hint: 'Add agenda points...',
            icon: Icons.format_list_bulleted_rounded,
            color: c.purple,
            maxLines: 4,
            maxLength: 500,
          ),
        ),
        _MeetingInputCard(
          title: 'Send Meeting Invitation',
          isRequired: true,
          subtitle: 'Choose how you want to send the meeting invite',
          child: Column(
            children: [
              _InviteToggle(
                icon: Icons.email_rounded,
                color: c.primary,
                title: 'Email',
                subtitle: 'Invitation will be sent to all attendees via email',
                value: _inviteEmail,
                onChanged: (value) => setState(() => _inviteEmail = value),
              ),
              const SizedBox(height: 10),
              _InviteToggle(
                icon: Icons.sms_rounded,
                color: c.success,
                title: 'Text Message (SMS)',
                subtitle: 'Invitation will be sent to all attendees via SMS',
                value: _inviteSms,
                onChanged: (value) => setState(() => _inviteSms = value),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.purple.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.purple.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: c.purple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Invitations will include meeting details, agenda, date, time and join link.',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: c.primary.withAlpha(70),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: _saving ? null : _schedule,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.event_available_rounded),
            label: Text(
              _saving ? 'Scheduling...' : 'Schedule Meeting & Send Invitations',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (tlList(widget.data, 'meetings').isEmpty)
          TlCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No scheduled meetings found in backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
        else
          ...tlList(widget.data, 'meetings').map(
            (item) => TlListTile(
              icon: Icons.event_note_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              trailing: '${item['time']}',
              color: c.primary,
              onTap: () => widget.open(item),
            ),
          ),
      ],
    );
  }

  Map<String, dynamic>? get _selectedEmployee {
    final id = _employeeId;
    if (id == null) return null;
    for (final item in _uniqueTeam(tlList(widget.data, 'team'))) {
      if (_employeeKey(item) == id) return item;
    }
    return null;
  }

  List<String> get _agendaItems {
    return _agenda.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String get _generatedMeetingLink {
    switch (_platform) {
      case 'Google Meet':
        return 'https://meet.google.com/new';
      case 'Microsoft Teams':
        return 'https://teams.microsoft.com/';
      case 'Zoom':
      default:
        return 'https://zoom.us/join';
    }
  }

  List<Map<String, dynamic>> _uniqueTeam(List<Map<String, dynamic>> team) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final item in team) {
      final key = _employeeKey(item);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(item);
    }
    return unique;
  }

  String _employeeKey(Map<String, dynamic> item) {
    return '${item['id'] ?? item['trailing'] ?? item['email'] ?? item['title'] ?? ''}';
  }

  String _employeeName(Map<String, dynamic> item) {
    final name = '${item['title'] ?? item['name'] ?? ''}'.trim();
    return name.isEmpty ? 'Employee' : name;
  }

  String _employeeMeta(Map<String, dynamic> item) {
    final id = '${item['id'] ?? item['trailing'] ?? ''}'.trim();
    final role = '${item['subtitle'] ?? item['designation'] ?? ''}'.trim();
    final department = '${item['department'] ?? ''}'.trim();
    return [
      id,
      role,
      department,
    ].where((value) => value.isNotEmpty).join(' - ');
  }

  String _meetingDateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_shortMonth(date.month)} ${date.year}';
  }

  String _shortMonth(int month) {
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
}

const _durationOptions = [
  '15 Minutes',
  '30 Minutes',
  '45 Minutes',
  '1 Hour',
  '2 Hours',
];

const _platforms = [
  _MeetingPlatform('Zoom', Icons.videocam_rounded, Color(0xFF3B82F6)),
  _MeetingPlatform('Google Meet', Icons.video_call_rounded, Color(0xFF22C55E)),
  _MeetingPlatform(
    'Microsoft Teams',
    Icons.groups_2_rounded,
    Color(0xFF6366F1),
  ),
];

class _MeetingPlatform {
  final String label;
  final IconData icon;
  final Color color;

  const _MeetingPlatform(this.label, this.icon, this.color);
}

class _MeetingInputCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? footer;
  final bool isRequired;
  final Widget child;

  const _MeetingInputCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TlCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: title,
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: c.danger),
                    ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            child,
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeetingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color color;
  final String? helper;
  final int maxLines;
  final int? maxLength;

  const _MeetingTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.color,
    this.helper,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        color: c.text,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      decoration: _meetingFieldDecoration(context, icon, color).copyWith(
        hintText: hint,
        helperText: helper,
        hintStyle: TextStyle(
          color: c.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: TextStyle(
          color: c.muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MeetingSelectButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _MeetingSelectButton({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: c.text, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MeetingIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MeetingIconButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: c.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final _MeetingPlatform item;
  final bool active;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? c.primary.withAlpha(24) : c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? c.primary : c.border,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(item.icon, color: item.color, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: active ? c.primary : c.muted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InviteToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              activeColor: c.purple,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _meetingFieldDecoration(
  BuildContext context,
  IconData icon,
  Color color,
) {
  final c = TlPalette.of(context);
  return InputDecoration(
    filled: true,
    fillColor: c.row,
    prefixIcon: Icon(icon, color: color),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.primary, width: 1.4),
    ),
  );
}

class _Reports extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback menu;
  final VoidCallback theme;
  const _Reports({
    required this.data,
    required this.open,
    required this.menu,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) =>
      _TlReportsDashboard(data: data, open: open, menu: menu, theme: theme);
}

class _TlReportsDashboard extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback menu;
  final VoidCallback theme;

  const _TlReportsDashboard({
    required this.data,
    required this.open,
    required this.menu,
    required this.theme,
  });

  @override
  State<_TlReportsDashboard> createState() => _TlReportsDashboardState();
}

class _TlReportsDashboardState extends State<_TlReportsDashboard> {
  String _range = 'This Week';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = tlList(widget.data, 'team');
    final tasks = tlList(widget.data, 'tasks');
    final meetings = tlList(widget.data, 'meetings');
    final pendingLeaves = tlList(widget.data, 'leaves');
    final pendingApprovals = _intValue(
      widget.data['pending_approvals'],
      fallback: pendingLeaves.length,
    );
    final members = _intValue(
      widget.data['members_count'],
      fallback: team.length,
    );
    final presentToday = _presentToday(team);
    final completedPercent = _intValue(
      widget.data['tasks_progress'],
      fallback: _completionPercent(tasks),
    );
    final chartValues = _chartValues(team, completedPercent);
    final categories =
        _categories(
          members: members,
          pendingApprovals: pendingApprovals,
          meetings: meetings.length,
          tasksDue: tasks.where((item) => _taskIsOpen(item)).length,
        ).where((item) {
          final haystack =
              '${item['title']} ${item['subtitle']} ${item['badge']}'
                  .toLowerCase();
          return _query.isEmpty || haystack.contains(_query.toLowerCase());
        }).toList();

    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        _ReportsHeader(c: c, menu: widget.menu, theme: widget.theme),
        const SizedBox(height: 14),
        _RangeSelector(
          value: _range,
          onChanged: (value) => setState(() => _range = value),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.82,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _ReportMetricCard(
              icon: Icons.groups_2_outlined,
              label: 'Team Members',
              value: '$members',
              foot: '${_activeTeamCount(team)} active',
              color: c.primary,
            ),
            _ReportMetricCard(
              icon: Icons.person_pin_circle_outlined,
              label: 'Present Today',
              value: '$presentToday',
              foot: members == 0
                  ? '0% of team'
                  : '${((presentToday / members) * 100).round()}% of team',
              color: c.success,
            ),
            _ReportMetricCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pending Reviews',
              value: '$pendingApprovals',
              foot: pendingApprovals == 0 ? 'All clear' : 'Needs your action',
              color: c.warning,
            ),
            _ReportMetricCard(
              icon: Icons.track_changes_rounded,
              label: 'Tasks Completed',
              value: '$completedPercent%',
              foot:
                  '${_intValue(widget.data['tasks_done'])}/${_intValue(widget.data['tasks_total'], fallback: tasks.length)} tasks done',
              color: c.purple,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PerformanceChartCard(values: chartValues),
        const SizedBox(height: 14),
        _ReportsSearch(
          query: _query,
          onChanged: (value) => setState(() => _query = value),
          onFilter: _showFilterSheet,
        ),
        const SizedBox(height: 16),
        Text(
          'Report Categories',
          style: TextStyle(
            color: c.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          TlCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'No matching reports found.',
                  style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        else
          ...categories.map(
            (item) => _ReportCategoryTile(
              icon: item['icon'] as IconData,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              badge: '${item['badge']}',
              color: item['color'] as Color,
              onTap: () => widget.open(item),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet() {
    final c = TlPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter reports',
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ...['This Week', 'This Month', 'Custom'].map(
                (value) => RadioListTile<String>(
                  value: value,
                  groupValue: _range,
                  activeColor: c.primary,
                  title: Text(value, style: TextStyle(color: c.text)),
                  onChanged: (next) {
                    if (next == null) return;
                    setState(() => _range = next);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse('$value'.replaceAll('%', '').trim()) ?? fallback;
  }

  static bool _taskIsOpen(Map<String, dynamic> item) {
    final status = '${item['status'] ?? ''}'.toLowerCase();
    return !status.contains('complete') && !status.contains('done');
  }

  static int _completionPercent(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((item) => !_taskIsOpen(item)).length;
    return ((done / tasks.length) * 100).round();
  }

  static int _presentToday(List<Map<String, dynamic>> team) {
    if (team.isEmpty) return 0;
    return team.where((item) {
      final attendance = item['attendance_summary'] is Map
          ? Map<String, dynamic>.from(item['attendance_summary'] as Map)
          : <String, dynamic>{};
      return _intValue(attendance['present']) > 0 ||
          '${item['status'] ?? ''}'.toLowerCase().contains('active');
    }).length;
  }

  static int _activeTeamCount(List<Map<String, dynamic>> team) {
    return team
        .where(
          (item) =>
              !'${item['status'] ?? ''}'.toLowerCase().contains('inactive'),
        )
        .length;
  }

  static List<double> _chartValues(
    List<Map<String, dynamic>> team,
    int completedPercent,
  ) {
    final scores = team
        .map((item) => _intValue(item['score'], fallback: completedPercent))
        .where((value) => value > 0)
        .take(7)
        .map((value) => (value / 100).clamp(0.0, 1.0).toDouble())
        .toList();
    if (scores.length >= 7) return scores;
    if (scores.isNotEmpty) {
      return List<double>.generate(7, (index) => scores[index % scores.length]);
    }
    final base = (completedPercent / 100).clamp(0.0, 1.0).toDouble();
    return List<double>.filled(7, base);
  }

  List<Map<String, Object>> _categories({
    required int members,
    required int pendingApprovals,
    required int meetings,
    required int tasksDue,
  }) {
    final c = TlPalette.of(context);
    return [
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Team Summary',
        'subtitle': 'Attendance, productivity & workload',
        'badge': '$members members',
        'color': c.primary,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Leave & Attendance',
        'subtitle': '$pendingApprovals pending TL reviews',
        'badge': pendingApprovals == 0 ? 'Updated' : 'Action needed',
        'color': c.warning,
      },
      {
        'icon': Icons.assignment_turned_in_outlined,
        'title': 'Meetings & Tasks',
        'subtitle': '$meetings meetings • $tasksDue tasks due',
        'badge': 'Live',
        'color': c.primary,
      },
    ];
  }
}

class _ReportsHeader extends StatelessWidget {
  final TlPalette c;
  final VoidCallback menu;
  final VoidCallback theme;

  const _ReportsHeader({
    required this.c,
    required this.menu,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: menu,
          icon: Icon(Icons.menu_rounded, color: c.text, size: 31),
          tooltip: 'Menu',
        ),
        const SizedBox(width: 4),
        const BitByteLogo(compact: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  color: c.text,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Team performance & insights',
                style: TextStyle(
                  color: c.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, color: c.text, size: 28),
              Positioned(
                right: 2,
                top: 1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: theme,
          icon: Icon(
            c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: c.muted,
            size: 30,
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RangeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    const items = ['This Week', 'This Month', 'Custom'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: items.map((item) {
          final selected = value == item;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? c.primary.withAlpha(34)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: c.primary)
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: selected ? c.primary : c.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? c.text : c.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
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

class _ReportMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String foot;
  final Color color;

  const _ReportMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.foot,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface.withAlpha(c.isDark ? 230 : 255),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(c.isDark ? 110 : 80)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(c.isDark ? 20 : 12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withAlpha(90)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  foot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChartCard extends StatelessWidget {
  final List<double> values;

  const _PerformanceChartCard({required this.values});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Team Performance',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'View analytics',
                style: TextStyle(
                  color: c.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _ReportsLinePainter(
                values: values,
                line: c.primary,
                grid: c.border,
                label: c.muted,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsLinePainter extends CustomPainter {
  final List<double> values;
  final Color line;
  final Color grid;
  final Color label;

  const _ReportsLinePainter({
    required this.values,
    required this.line,
    required this.grid,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const bottom = 24.0;
    const top = 8.0;
    final chartWidth = size.width - left - 4;
    final chartHeight = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = grid.withAlpha(150)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 4; i++) {
      final y = top + (chartHeight / 4) * i;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final labelText = '${(100 - (i * 25))}%';
      textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(
          color: label,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 7));
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final points = <Offset>[];
    final safeValues = values.isEmpty ? List<double>.filled(7, .0) : values;
    for (var i = 0; i < days.length; i++) {
      final x = left + (chartWidth / (days.length - 1)) * i;
      final value = safeValues[i % safeValues.length]
          .clamp(0.0, 1.0)
          .toDouble();
      final y = top + chartHeight - (value * chartHeight);
      points.add(Offset(x, y));
      textPainter.text = TextSpan(
        text: days[i],
        style: TextStyle(
          color: label,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 17),
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
    final pointPaint = Paint()..color = line;
    for (final point in points) {
      canvas.drawCircle(point, 4.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReportsLinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid ||
      oldDelegate.label != label;
}

class _ReportsSearch extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  const _ReportsSearch({
    required this.query,
    required this.onChanged,
    required this.onFilter,
  });

  @override
  State<_ReportsSearch> createState() => _ReportsSearchState();
}

class _ReportsSearchState extends State<_ReportsSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _ReportsSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyle(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search reports...',
        hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
        prefixIcon: Icon(Icons.search_rounded, color: c.muted, size: 26),
        suffixIcon: widget.query.isEmpty
            ? IconButton(
                onPressed: widget.onFilter,
                icon: Icon(Icons.tune_rounded, color: c.muted, size: 25),
              )
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: Icon(Icons.close_rounded, color: c.muted),
              ),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary),
        ),
      ),
    );
  }
}

class _ReportCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _ReportCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withAlpha(90)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(65)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.text, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Approvals extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;

  const _Approvals({
    required this.data,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_Approvals> createState() => _ApprovalsState();
}

class _ApprovalsState extends State<_Approvals> {
  List<Map<String, dynamic>> _pending = const [];
  List<Map<String, dynamic>> _approved = const [];
  List<Map<String, dynamic>> _rejected = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Seed with dashboard data immediately so the list is usable at once.
    _pending = tlList(widget.data, 'approvals');
    _approved = tlList(widget.data, 'leaves_approved');
    _rejected = tlList(widget.data, 'leaves_rejected');
    _pending = [..._pending, ...tlList(widget.data, 'checkout_permissions')];
    _approved = [
      ..._approved,
      ...tlList(widget.data, 'checkout_permissions_approved'),
    ];
    _rejected = [
      ..._rejected,
      ...tlList(widget.data, 'checkout_permissions_rejected'),
    ];
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await TlService().fetchApprovals(widget.userId);
      if (!mounted) return;
      setState(() {
        _pending = [
          ..._asList(result['pending']),
          ..._asList(result['checkout_permissions']),
        ];
        _approved = [
          ..._asList(result['approved']),
          ..._asList(result['checkout_permissions_approved']),
        ];
        _rejected = [
          ..._asList(result['rejected']),
          ..._asList(result['checkout_permissions_rejected']),
        ];
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _refresh() {
    _loadApprovals();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Column(
      children: [
        if (_loading)
          LinearProgressIndicator(
            minHeight: 2,
            color: c.primary,
            backgroundColor: Colors.transparent,
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: TlCard(
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: c.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not refresh: $_error',
                      style: TextStyle(
                        color: c.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadApprovals,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _LeaveApprovalList(
            pending: _pending,
            approved: _approved,
            rejected: _rejected,
            userId: widget.userId,
            onChanged: _refresh,
            onRefresh: _loadApprovals,
          ),
        ),
      ],
    );
  }
}

class _LeaveApprovalList extends StatefulWidget {
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> approved;
  final List<Map<String, dynamic>> rejected;
  final String userId;
  final VoidCallback onChanged;
  final VoidCallback? onRefresh;

  const _LeaveApprovalList({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.userId,
    required this.onChanged,
    this.onRefresh,
  });

  @override
  State<_LeaveApprovalList> createState() => _LeaveApprovalListState();
}

class _LeaveApprovalListState extends State<_LeaveApprovalList> {
  int? _savingId;
  String _tab = 'pending';
  String _query = '';
  DateTime? _historyDate;
  Map<String, dynamic>? _selected;

  DateTime? _itemHistoryDate(Map<String, dynamic> item) {
    for (final key in const [
      'reviewed_at',
      'updated_at',
      'date',
      'from_date',
      'created_at',
    ]) {
      final parsed = DateTime.tryParse('${item[key] ?? ''}'.trim());
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _selectHistoryDate() async {
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _historyDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _historyDate = selected);
  }

  Future<void> _decide(
    Map<String, dynamic> leave,
    String status, {
    String rejectionReason = '',
  }) async {
    final id = int.tryParse('${leave['id'] ?? ''}');
    if (id == null || _savingId != null) return;
    setState(() => _savingId = id);
    try {
      if (leave['approval_type'] == 'early_checkout') {
        await TlService().updateCheckoutPermission(
          id,
          status,
          widget.userId,
          rejectionReason: rejectionReason,
        );
      } else {
        await TlService().updateLeaveRequest(
          id,
          status,
          widget.userId,
          rejectionReason: rejectionReason,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave ${status == 'approved' ? 'approved' : 'rejected'} by TL',
          ),
        ),
      );
      setState(() => _selected = null);
      widget.onChanged();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  Future<void> _openDetails(Map<String, dynamic> leave) async {
    if (const {
      'daily_report',
      'social_media_post',
      'leave_request',
    }.contains(leave['approval_type'])) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmployeeApprovalDetailScreen(
            item: leave,
            userId: widget.userId,
            service: EmployeeService(),
            received:
                '${leave['status'] ?? ''}'.toLowerCase() == 'requested' &&
                '${leave['current_stage'] ?? ''}' == '0',
          ),
        ),
      );
      if (changed == true) {
        widget.onChanged();
        widget.onRefresh?.call();
      }
      return;
    }
    final id = int.tryParse('${leave['id'] ?? ''}');
    setState(() => _selected = leave);
    if (id == null || leave['approval_type'] == 'early_checkout') return;
    try {
      final response = await TlService().fetchLeaveRequest(id);
      final detail = response['leave'];
      if (mounted && detail is Map) {
        setState(() => _selected = Map<String, dynamic>.from(detail));
      }
    } catch (_) {
      // The list payload already has enough data to render the details screen.
    }
  }

  Future<void> _confirmApprove(Map<String, dynamic> leave) async {
    final approved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveConfirmation(leave: leave),
    );
    if (approved == true) {
      await _decide(leave, 'approved');
    }
  }

  Future<void> _confirmReject(Map<String, dynamic> leave) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectRequestDialog(leave: leave),
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await _decide(leave, 'rejected', rejectionReason: reason.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final selected = _selected;
    if (selected != null) {
      return _ApprovalDetails(
        leave: selected,
        saving: _savingId == int.tryParse('${selected['id'] ?? ''}'),
        back: () => setState(() => _selected = null),
        approve: () => _confirmApprove(selected),
        reject: () => _confirmReject(selected),
      );
    }
    final urgent = widget.pending
        .where((item) => _approvalIsUrgent(item))
        .toList();
    final leaves = switch (_tab) {
      'approved' => widget.approved,
      'rejected' => widget.rejected,
      'urgent' => urgent,
      _ => widget.pending,
    };
    final filtered = leaves.where((leave) {
      if ((_tab == 'approved' || _tab == 'rejected') && _historyDate != null) {
        final date = _itemHistoryDate(leave);
        if (date == null || !_sameDate(date, _historyDate!)) return false;
      }
      final haystack =
          '${leave['name']} ${leave['employee_id']} ${leave['leave_type']} ${leave['reason']}'
              .toLowerCase();
      return haystack.contains(_query.toLowerCase().trim());
    }).toList();
    final emptyMessage = switch (_tab) {
      'approved' => 'No approved leave requests yet',
      'rejected' => 'No rejected leave requests yet',
      'urgent' => 'No urgent approvals right now',
      _ => 'No leave requests pending TL review',
    };
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration:
                    _fieldDecoration(
                      context,
                      'Search by name, type or ID...',
                    ).copyWith(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: c.muted,
                        size: 18,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Filter approvals',
              onSelected: (value) => setState(() => _tab = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pending', child: Text('Pending')),
                PopupMenuItem(value: 'urgent', child: Text('Urgent')),
                PopupMenuItem(value: 'approved', child: Text('Approved')),
                PopupMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Icon(Icons.filter_list_rounded, color: c.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tab == 'approved' || _tab == 'rejected') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectHistoryDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    _historyDate == null
                        ? 'Approval history: All dates'
                        : 'History: ${_dateLabel(_historyDate!)}',
                  ),
                ),
              ),
              if (_historyDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Show all dates',
                  onPressed: () => setState(() => _historyDate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        AppModuleTabs<String>(
          tabs: [
            AppModuleTab('pending', 'Pending (${widget.pending.length})'),
            AppModuleTab('urgent', 'Urgent (${urgent.length})'),
            AppModuleTab('approved', 'Approved (${widget.approved.length})'),
            AppModuleTab('rejected', 'Rejected (${widget.rejected.length})'),
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          TlCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ...filtered.map(
          (leave) => _ApprovalRequestCard(
            leave: leave,
            urgent: _approvalIsUrgent(leave),
            onTap: () => _openDetails(leave),
          ),
        ),
      ],
    );
  }
}

class _ApprovalRequestCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  final bool urgent;
  final VoidCallback onTap;

  const _ApprovalRequestCard({
    required this.leave,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final approvalType = '${leave['approval_type'] ?? ''}';
    final isTemplateApproval = const {
      'daily_report',
      'social_media_post',
      'leave_request',
    }.contains(approvalType);
    final session = '${leave['session'] ?? ''}'.toLowerCase();
    final badgeLabel = switch (approvalType) {
      'daily_report' =>
        session.contains('after') ? 'Evening Report' : 'Morning Report',
      'social_media_post' => 'Social Media Poster',
      'leave_request' => '${leave['leave_type'] ?? 'Leave Request'}',
      _ => '${leave['leave_type'] ?? 'Leave Request'}',
    };
    final dateLine = isTemplateApproval
        ? '${leave['date'] ?? ''}${approvalType == 'daily_report' ? ' · ${leave['session'] ?? ''}' : ''}'
        : '${leave['from_date'] ?? ''} to ${leave['to_date'] ?? ''} (${leave['days'] ?? ''})';
    final detailsLine = isTemplateApproval
        ? '${leave['task_details'] ?? leave['platforms'] ?? ''}'
        : '${leave['reason'] ?? ''}';
    final submittedLine = isTemplateApproval
        ? '${leave['created_at'] ?? ''}'
        : '${leave['submitted_on'] ?? leave['applied_on'] ?? ''}';
    final workflowStatus = _approvalWorkflowLabel(leave, urgent: urgent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TlCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InitialAvatar(text: '${leave['initials'] ?? ''}', size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${leave['name'] ?? 'Employee'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        workflowStatus,
                        style: TextStyle(
                          color: workflowStatus == 'Rejected'
                              ? c.danger
                              : workflowStatus == 'Approved'
                              ? c.success
                              : c.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${leave['employee_id'] ?? ''}',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ApprovalPill(label: badgeLabel, color: c.success),
                  const SizedBox(height: 8),
                  _TinyIconLine(
                    icon: Icons.calendar_today_rounded,
                    text: dateLine,
                  ),
                  const SizedBox(height: 5),
                  _TinyIconLine(
                    icon: Icons.device_hub_rounded,
                    text: detailsLine,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submitted on $submittedLine',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _ApprovalDetails extends StatelessWidget {
  final Map<String, dynamic> leave;
  final bool saving;
  final VoidCallback back;
  final VoidCallback approve;
  final VoidCallback reject;

  const _ApprovalDetails({
    required this.leave,
    required this.saving,
    required this.back,
    required this.approve,
    required this.reject,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final isPending = '${leave['tl_status'] ?? ''}'.toLowerCase() == 'pending';
    final hasAttachment =
        '${leave['medical_certificate'] ?? leave['document_name'] ?? ''}'
            .trim()
            .isNotEmpty;
    final leaveBalance = '${leave['leave_balance'] ?? ''}';
    final afterBalance = '${leave['after_request_balance'] ?? ''}';
    final hasBalance = leaveBalance.isNotEmpty && leaveBalance != '0.0';
    final requestId =
        '${leave['request_id'] ?? 'LEV-${leave['id'] ?? ''}'.toUpperCase()}';
    final submittedOn = '${leave['submitted_on'] ?? leave['applied_on'] ?? ''}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppLayout.pagePadding,
            children: [
              // ── Header ────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: back,
                    icon: Icon(Icons.arrow_back_rounded, color: c.primary),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      'Approval Details',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Leave type badge + request ID + status ────────────
              TlCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ApprovalPill(
                          label: '${leave['leave_type'] ?? 'Leave Request'}',
                          color: c.success,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.warning.withAlpha(24),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: c.warning.withAlpha(70)),
                          ),
                          child: Text(
                            '${leave['status'] ?? 'Pending'}',
                            style: TextStyle(
                              color: c.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request ID: $requestId',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Divider(color: c.border, height: 24),
                    // Employee info
                    Row(
                      children: [
                        _InitialAvatar(
                          text: '${leave['initials'] ?? ''}',
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${leave['name'] ?? 'Employee'}',
                                style: TextStyle(
                                  color: c.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${leave['employee_id'] ?? ''}',
                                style: TextStyle(
                                  color: c.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ('${leave['designation'] ?? ''}'.isNotEmpty ||
                            '${leave['department'] ?? ''}'.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if ('${leave['designation'] ?? ''}'.isNotEmpty)
                                Text(
                                  '${leave['designation']}',
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if ('${leave['department'] ?? ''}'.isNotEmpty)
                                Text(
                                  '${leave['department']}',
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Request Details ───────────────────────────────────
              TlCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      'Leave Type',
                      '${leave['leave_type'] ?? ''}',
                      accent: c.success,
                    ),
                    _DetailRow(
                      'From Date',
                      '${leave['from_date_label'] ?? leave['from_date'] ?? ''}',
                    ),
                    _DetailRow(
                      'To Date',
                      '${leave['to_date_label'] ?? leave['to_date'] ?? ''}',
                    ),
                    _DetailRow(
                      'Duration',
                      '${leave['duration'] ?? leave['days'] ?? ''}',
                      accent: c.primary,
                    ),
                    _DetailRow('Session', '${leave['session'] ?? 'Full Day'}'),
                    _DetailRow('Reason', '${leave['reason'] ?? ''}'),
                    _DetailRow('Submitted On', submittedOn),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Leave Balance ─────────────────────────────────────
              if (hasBalance)
                TlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Balance',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceColumn(
                              label:
                                  '${leave['leave_type'] ?? 'Leave'} Balance',
                              value: '$leaveBalance Days',
                              color: c.text,
                            ),
                          ),
                          Container(width: 1, height: 44, color: c.border),
                          Expanded(
                            child: _BalanceColumn(
                              label: 'After this request',
                              value: '$afterBalance Days',
                              color:
                                  afterBalance == '0.0' || afterBalance == '0'
                                  ? c.danger
                                  : c.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (hasBalance) const SizedBox(height: 12),

              // ── Attachments ───────────────────────────────────────
              if (hasAttachment)
                TlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachments',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.row,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: c.danger,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${leave['medical_certificate'] ?? leave['document_name'] ?? 'Medical Certificate'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if ('${leave['attachment_size'] ?? ''}'
                                      .isNotEmpty)
                                    Text(
                                      '${leave['attachment_size']}',
                                      style: TextStyle(
                                        color: c.muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.download_rounded,
                              color: c.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasAttachment) const SizedBox(height: 12),

              // ── Approval History ──────────────────────────────────
              TlCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval History',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ApprovalHistoryRow(
                      initials: '${leave['initials'] ?? ''}',
                      actor: '${leave['name'] ?? 'Employee'}',
                      action: 'Submitted Request',
                      time: submittedOn,
                      color: c.primary,
                    ),
                    if ('${leave['tl_approved_by'] ?? ''}'.isNotEmpty &&
                        leave['tl_status']?.toString().toLowerCase() !=
                            'pending') ...[
                      const SizedBox(height: 8),
                      _ApprovalHistoryRow(
                        initials: _tlInitials(leave['tl_approved_by']),
                        actor: '${leave['tl_approved_by']}',
                        action:
                            '${leave['tl_status']?.toString().toLowerCase() == 'approved' ? 'TL Approved' : 'TL Rejected'}',
                        time: '${leave['tl_reviewed_at'] ?? ''}',
                        color:
                            '${leave['tl_status']}'.toLowerCase() == 'approved'
                            ? c.success
                            : c.danger,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Action buttons ────────────────────────────────────────
        if (isPending)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DecisionButton(
                    label: 'Reject',
                    color: c.danger,
                    saving: saving,
                    icon: Icons.cancel_outlined,
                    onTap: saving ? null : reject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DecisionButton(
                    label: 'Approve',
                    color: c.success,
                    saving: saving,
                    icon: Icons.check_circle_outline_rounded,
                    onTap: saving ? null : approve,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _tlInitials(Object? value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty) return 'TL';
    final parts = text.split(' ').where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

// ─── Approval History Row ─────────────────────────────────────────────────────
class _ApprovalHistoryRow extends StatelessWidget {
  final String initials;
  final String actor;
  final String action;
  final String time;
  final Color color;

  const _ApprovalHistoryRow({
    required this.initials,
    required this.actor,
    required this.action,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialAvatar(text: initials, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actor,
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                action,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (time.isNotEmpty)
          Text(
            time,
            style: TextStyle(
              color: c.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ─── Balance Column ───────────────────────────────────────────────────────────
class _BalanceColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RejectRequestDialog extends StatefulWidget {
  final Map<String, dynamic> leave;

  const _RejectRequestDialog({required this.leave});

  @override
  State<_RejectRequestDialog> createState() => _RejectRequestDialogState();
}

class _RejectRequestDialogState extends State<_RejectRequestDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reject Request',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.muted),
                ),
              ],
            ),
            TlCard(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _InitialAvatar(
                    text: '${widget.leave['initials'] ?? ''}',
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.leave['name'] ?? 'Employee'}',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${widget.leave['employee_id'] ?? ''}',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ApprovalPill(label: 'Leave Request', color: c.success),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Reason for Rejection *',
              style: TextStyle(
                color: c.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              maxLines: 4,
              maxLength: 250,
              style: TextStyle(
                color: c.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: _fieldDecoration(
                context,
                'Please provide reason for rejection...',
              ),
            ),
            Text(
              'This request will be moved to Rejected.',
              style: TextStyle(
                color: c.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_reason.text.trim().isEmpty) return;
                      Navigator.pop(context, _reason.text.trim());
                    },
                    child: const Text('Reject Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApproveConfirmation extends StatelessWidget {
  final Map<String, dynamic> leave;

  const _ApproveConfirmation({required this.leave});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TlCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: c.success,
                size: 70,
              ),
              const SizedBox(height: 12),
              Text(
                'Approve Request?',
                style: TextStyle(
                  color: c.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are about to approve this leave request.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TlCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _InitialAvatar(
                      text: '${leave['initials'] ?? ''}',
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${leave['name'] ?? 'Employee'} (${leave['employee_id'] ?? ''})',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _ApprovalPill(label: 'Leave Request', color: c.success),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes, Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ApprovalPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyIconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyIconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Row(
      children: [
        Icon(icon, color: c.muted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _DetailRow(this.label, this.value, {this.accent});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent ?? c.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String text;
  final double size;

  const _InitialAvatar({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final label = text.trim().isEmpty ? 'AS' : text.trim().toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.row, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(
          color: c.text,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool saving;
  final IconData? icon;
  final VoidCallback? onTap;

  const _DecisionButton({
    required this.label,
    required this.color,
    this.saving = false,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withAlpha(22),
          side: BorderSide(color: color.withAlpha(105)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        onPressed: onTap,
        child: saving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17),
                    const SizedBox(width: 7),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;
  final VoidCallback openApprovals;

  const _Notifications({
    required this.data,
    required this.userId,
    required this.onChanged,
    required this.openApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(
      title: 'Notifications',
      items: tlList(data, 'notifications'),
      icon: Icons.notifications_rounded,
      color: c.danger,
      onTap: (item) async {
        if (_isClientVisitNotification(item)) {
          final notificationId = int.tryParse('${item['id'] ?? ''}');
          if (notificationId != null && item['is_read'] != true) {
            try {
              await TlService().markNotificationRead(userId, notificationId);
              onChanged();
            } catch (_) {
              // The visit can still open if read-state synchronization fails.
            }
          }
          if (!context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientVisitModuleScreen(
                userId: userId,
                roleLabel: 'Team Lead - My Visits',
                reviewerMode: true,
                requesterRole: 'tl',
                initialVisitId: int.tryParse('${item['reference_id'] ?? ''}'),
              ),
            ),
          );
        } else if (item['module'] == 'approval') {
          _openTlApprovalNotification(context, data, userId, item, onChanged);
        } else if (_isLeaveNotification(item)) {
          openApprovals();
        }
      },
    );
  }
}

Future<void> _openTlApprovalNotification(
  BuildContext context,
  Map<String, dynamic> dashboardData,
  String userId,
  Map<String, dynamic> notification,
  VoidCallback onChanged,
) async {
  final referenceId = '${notification['reference_id'] ?? ''}';
  Map<String, dynamic>? approval;
  for (final item in tlList(dashboardData, 'approvals')) {
    if ('${item['id'] ?? ''}' == referenceId && item['approval_type'] != null) {
      approval = item;
      break;
    }
  }
  if (approval == null) {
    try {
      final result = await TlService().fetchApprovals(userId);
      for (final key in ['pending', 'approved', 'rejected']) {
        final values = result[key];
        if (values is! List) continue;
        for (final raw in values.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          if ('${item['id'] ?? ''}' == referenceId &&
              item['approval_type'] != null) {
            approval = item;
            break;
          }
        }
        if (approval != null) break;
      }
    } catch (_) {
      // The approvals page remains available if this notification is stale.
    }
  }
  if (approval == null && referenceId.isNotEmpty) {
    try {
      final result = await EmployeeService().fetchApproval(userId, referenceId);
      final value = result['approval'];
      if (value is Map) {
        approval = Map<String, dynamic>.from(value);
      }
    } catch (_) {
      // A deleted or inaccessible request is handled below.
    }
  }
  if (!context.mounted) return;
  if (approval == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This approval is no longer awaiting your action.'),
      ),
    );
    return;
  }
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EmployeeApprovalDetailScreen(
        item: approval!,
        userId: userId,
        service: EmployeeService(),
        received:
            '${approval!['status'] ?? ''}'.toLowerCase() == 'requested' &&
            '${approval!['current_stage'] ?? ''}' == '0',
      ),
    ),
  );
  if (changed == true) onChanged();
}

class _TaskDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback update;
  const _TaskDetails({required this.item, required this.update});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['title'] ?? 'Task Details'}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _Info('Project', '${item['project'] ?? item['subtitle'] ?? ''}'),
              _Info('Assigned To', '${item['assignee'] ?? ''}'),
              _Info('Priority', '${item['priority'] ?? ''}'),
              _Info('Due Date', '${item['due'] ?? ''}'),
              _Info('Status', '${item['status'] ?? item['trailing'] ?? ''}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: update,
          child: const Text('Update Status'),
        ),
      ],
    );
  }
}

class _CreateTask extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onBack;
  final VoidCallback onTheme;
  final VoidCallback onCreated;
  const _CreateTask({
    required this.data,
    required this.userId,
    required this.onBack,
    required this.onTheme,
    required this.onCreated,
  });

  @override
  State<_CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<_CreateTask> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _assigneeId;
  String? _project;
  String _priority = 'Medium';
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _dueTime = const TimeOfDay(hour: 18, minute: 0);
  String _taskType = 'Individual';
  bool _notifyAssignee = true;
  bool _saving = false;
  bool _reviewing = false;

  // Checklist items: each map has 'text' (String) and 'done' (bool).
  final List<Map<String, dynamic>> _checklistItems = [];
  // Attached files selected via file_selector.
  final List<XFile> _attachedFiles = [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  Future<void> _createTask() async {
    final assignee = _selectedAssignee;
    if (_title.text.trim().isEmpty || assignee == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter title, assignee, and due date.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await TlService().createTask({
        'title': _title.text.trim(),
        'project': _project ?? '',
        'assignee_id': assignee['id'] ?? assignee['trailing'] ?? '',
        'assignee_name': assignee['title'] ?? assignee['name'] ?? '',
        'assignee_email': assignee['email'] ?? '',
        'priority': _priority,
        'due_date': '${_formatDate(_dueDate!)} ${_dueTime.format(context)}',
        'description': _description.text.trim(),
        'created_by': widget.userId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned successfully.')),
      );
      widget.onCreated();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStartDate() async {
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (selected != null) setState(() => _startDate = selected);
  }

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _dueTime,
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startTime = selected;
      } else {
        _dueTime = selected;
      }
    });
  }

  void _reviewTask() {
    if (_title.text.trim().isEmpty ||
        _selectedAssignee == null ||
        _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter title, assignee, and due date.'),
        ),
      );
      return;
    }
    setState(() => _reviewing = true);
  }

  Future<void> _openChecklist() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ChecklistSheet(
        items: _checklistItems,
        onChanged: (updated) => setState(() {
          _checklistItems
            ..clear()
            ..addAll(updated);
        }),
      ),
    );
  }

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Documents & Images',
      extensions: [
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        'pdf', 'doc', 'docx', 'xls', 'xlsx',
        'ppt', 'pptx', 'txt', 'csv', 'zip',
      ],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty || !mounted) return;

    // Guard: reject files > 10 MB each.
    final tooBig = <String>[];
    final valid = <XFile>[];
    for (final f in files) {
      final length = await f.length();
      if (length > 10 * 1024 * 1024) {
        tooBig.add(f.name);
      } else {
        valid.add(f);
      }
    }
    if (tooBig.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Skipped ${tooBig.join(', ')} — each file must be 10 MB or smaller.',
          ),
        ),
      );
    }
    if (valid.isEmpty) return;
    setState(() => _attachedFiles.addAll(valid));
  }

  void _removeAttachment(int index) {
    setState(() => _attachedFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = _uniqueTeam(tlList(widget.data, 'team'));
    final projects = _projectNames(tlList(widget.data, 'projects'));
    if (_project != null && !projects.contains(_project)) {
      _project = null;
    }
    if (_reviewing) return _buildReview(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: Icon(Icons.arrow_back_rounded, color: c.text),
            ),
            Expanded(
              child: Text(
                'Assign Task',
                style: TextStyle(
                  color: c.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onTheme,
              icon: Icon(
                c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: c.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _title,
          decoration: _fieldDecoration(
            context,
            'Task Title *',
          ).copyWith(hintText: 'Enter task title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _description,
          maxLines: 3,
          decoration: _fieldDecoration(
            context,
            'Description',
          ).copyWith(hintText: 'Enter task description...'),
        ),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          TlCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No backend projects found. Task can be assigned without a project.',
              style: TextStyle(
                color: c.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          AppDropdownButtonFormField<String>(
            value: _project,
            items: projects
                .map(
                  (project) =>
                      DropdownMenuItem(value: project, child: Text(project)),
                )
                .toList(),
            onChanged: (value) => setState(() => _project = value),
            decoration: _fieldDecoration(
              context,
              'Select Project',
            ).copyWith(hintText: 'Choose project'),
          ),
        const SizedBox(height: 12),
        Text(
          'Assign To',
          style: TextStyle(
            color: c.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: c.row,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              if (_selectedAssignee != null) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: c.primary.withAlpha(30),
                  child: Text(
                    '${_selectedAssignee!['title'] ?? _selectedAssignee!['name'] ?? 'E'}'[0],
                    style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${_selectedAssignee!['title'] ?? _selectedAssignee!['name']}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _assigneeId = null),
                  icon: Icon(Icons.close_rounded, color: c.muted, size: 17),
                  visualDensity: VisualDensity.compact,
                ),
              ] else
                Expanded(
                  child: Text(
                    'Select an employee',
                    style: TextStyle(color: c.muted, fontSize: 11),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Add employee',
                onSelected: (value) => setState(() => _assigneeId = value),
                itemBuilder: (_) => team
                    .map(
                      (employee) => PopupMenuItem(
                        value: _employeeKey(employee),
                        child: Text('${employee['title'] ?? employee['name']}'),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.primary),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '+ Add',
                    style: TextStyle(
                      color: c.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Priority',
          style: TextStyle(
            color: c.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: ['Low', 'Medium', 'High', 'Urgent']
              .map(
                (value) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: _PriorityButton(
                      value: value,
                      selected: _priority == value,
                      onTap: () => setState(() => _priority = value),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TaskDateTimeBox(
                label: 'Start Date',
                value: _formatDate(_startDate),
                icon: Icons.calendar_today_rounded,
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _TaskDateTimeBox(
                label: 'Due Date *',
                value: _dueDate == null
                    ? 'Select date'
                    : _formatDate(_dueDate!),
                icon: Icons.calendar_today_rounded,
                onTap: _pickDueDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _TaskDateTimeBox(
                label: 'Start Time',
                value: _startTime.format(context),
                icon: Icons.schedule_rounded,
                onTap: () => _pickTime(start: true),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _TaskDateTimeBox(
                label: 'Due Time',
                value: _dueTime.format(context),
                icon: Icons.schedule_rounded,
                onTap: () => _pickTime(start: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          'Task Type',
          style: TextStyle(
            color: c.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _TaskTypeButton(
                label: 'Individual',
                icon: Icons.person_outline_rounded,
                selected: _taskType == 'Individual',
                onTap: () => setState(() => _taskType = 'Individual'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _TaskTypeButton(
                label: 'Team',
                icon: Icons.groups_outlined,
                selected: _taskType == 'Team',
                onTap: () => setState(() => _taskType = 'Team'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _TaskOptionRow(
          icon: Icons.playlist_add_check_rounded,
          title: 'Add Checklist',
          trailing: '${_checklistItems.where((i) => i['done'] == true).length}/${_checklistItems.length}',
          onTap: _openChecklist,
        ),
        const SizedBox(height: 5),
        _TaskOptionRow(
          icon: Icons.attach_file_rounded,
          title: 'Attach Files',
          trailing: '${_attachedFiles.length}',
          onTap: _pickFiles,
        ),
        if (_attachedFiles.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(_attachedFiles.length, (i) {
              final file = _attachedFiles[i];
              return Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => _removeAttachment(i),
              );
            }),
          ),
        ],
        const SizedBox(height: 5),
        const _TaskOptionRow(
          icon: Icons.alarm_add_rounded,
          title: 'Reminder',
          trailing: 'No reminder',
        ),
        const SizedBox(height: 5),
        _TaskOptionRow(
          icon: Icons.notifications_none_rounded,
          title: 'Notify Assignee',
          trailingWidget: Switch(
            value: _notifyAssignee,
            activeColor: c.primary,
            onChanged: (value) => setState(() => _notifyAssignee = value),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Draft saved on this device.')),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Save Draft'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ElevatedButton(
                onPressed: _reviewTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Assign Task'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final c = TlPalette.of(context);
    final assignee = _selectedAssignee ?? {};
    final assigneeName =
        '${assignee['title'] ?? assignee['name'] ?? 'Employee'}';
    final priorityColor = _priority == 'Urgent' || _priority == 'High'
        ? c.danger
        : _priority == 'Low'
        ? c.success
        : c.warning;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _reviewing = false),
              icon: Icon(Icons.arrow_back_rounded, color: c.text),
            ),
            Expanded(
              child: Text(
                'Review Task',
                style: TextStyle(
                  color: c.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onTheme,
              icon: Icon(
                c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: c.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title.text.trim(),
                style: TextStyle(
                  color: c.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.work_outline_rounded,
                      label: 'Project',
                      value: _project ?? 'No project selected',
                      color: c.primary,
                    ),
                  ),
                  Container(width: 1, height: 48, color: c.border),
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.flag_rounded,
                      label: 'Priority',
                      value: _priority,
                      color: priorityColor,
                    ),
                  ),
                ],
              ),
              Divider(height: 22, color: c.border),
              Row(
                children: [
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.calendar_month_rounded,
                      label: 'Due Date',
                      value:
                          '${_formatDate(_dueDate!)} ${_dueTime.format(context)}',
                      color: c.primary,
                    ),
                  ),
                  Container(width: 1, height: 48, color: c.border),
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.people_outline_rounded,
                      label: 'Assignees',
                      value: '1',
                      color: c.primary,
                    ),
                  ),
                ],
              ),
              Divider(height: 22, color: c.border),
              Row(
                children: [
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.check_box_outlined,
                      label: 'Checklist',
                      value: '${_checklistItems.where((i) => i['done'] == true).length}/${_checklistItems.length} items',
                      color: c.primary,
                    ),
                  ),
                  Container(width: 1, height: 48, color: c.border),
                  Expanded(
                    child: _ReviewValue(
                      icon: Icons.attach_file_rounded,
                      label: 'Attachments',
                      value: '${_attachedFiles.length} File${_attachedFiles.length == 1 ? '' : 's'}',
                      color: c.primary,
                    ),
                  ),
                ],
              ),
              Divider(height: 22, color: c.border),
              _ReviewValue(
                icon: Icons.notifications_none_rounded,
                label: 'Reminder',
                value: 'No reminder',
                color: c.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Employee',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: c.primary.withAlpha(25),
                    child: Text(
                      assigneeName.isEmpty
                          ? '?'
                          : assigneeName[0].toUpperCase(),
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assigneeName,
                          style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${assignee['designation'] ?? assignee['subtitle'] ?? assignee['email'] ?? ''}',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: c.success),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity & Instructions',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _description.text.trim().isEmpty
                    ? 'No additional instructions provided.'
                    : _description.text.trim(),
                style: TextStyle(
                  color: c.muted,
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: c.success.withAlpha(14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.success.withAlpha(100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: c.success,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Task Ready to Assign',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _reviewing = false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.assignment_turned_in_rounded),
                label: Text(_saving ? 'Assigning...' : 'Assign Task'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final c = TlPalette.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: c.row,
      labelStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.primary, width: 1.4),
      ),
    );
  }

  Map<String, dynamic>? get _selectedAssignee {
    final id = _assigneeId;
    if (id == null) return null;
    for (final employee in _uniqueTeam(tlList(widget.data, 'team'))) {
      if (_employeeKey(employee) == id) return employee;
    }
    return null;
  }

  List<Map<String, dynamic>> _uniqueTeam(List<Map<String, dynamic>> team) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final item in team) {
      final key = _employeeKey(item);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(item);
    }
    return unique;
  }

  String _employeeKey(Map<String, dynamic> item) {
    return '${item['id'] ?? item['employee_id'] ?? item['email'] ?? item['title'] ?? ''}';
  }

  List<String> _projectNames(List<Map<String, dynamic>> projects) {
    final names = projects
        .map((item) => '${item['title'] ?? ''}')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    return names;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ChecklistSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const _ChecklistSheet({required this.items, required this.onChanged});

  @override
  State<_ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends State<_ChecklistSheet> {
  late final List<Map<String, dynamic>> _items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(
      widget.items.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.add({'text': text, 'done': false}));
    _controller.clear();
    widget.onChanged(List.from(_items));
  }

  void _toggleItem(int index) {
    setState(() => _items[index]['done'] = !(_items[index]['done'] as bool));
    widget.onChanged(List.from(_items));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged(List.from(_items));
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final viewInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + viewInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Checklist',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(),
                  decoration: InputDecoration(
                    hintText: 'Add checklist item...',
                    filled: true,
                    fillColor: c.row,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No checklist items yet. Add one above.',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: c.border,
                ),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final done = item['done'] as bool;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: done,
                      activeColor: c.primary,
                      onChanged: (_) => _toggleItem(i),
                    ),
                    title: Text(
                      '${item['text']}',
                      style: TextStyle(
                        color: done ? c.muted : c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: c.danger, size: 20),
                      onPressed: () => _removeItem(i),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final color = value == 'Low'
        ? c.success
        : value == 'Medium'
        ? c.warning
        : value == 'High'
        ? c.danger
        : c.purple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 39,
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? c.text : c.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDateTimeBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _TaskDateTimeBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: c.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(icon, color: c.primary, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TaskTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? c.primary : c.muted,
        side: BorderSide(color: selected ? c.primary : c.border),
        minimumSize: const Size.fromHeight(42),
        backgroundColor: c.row,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _TaskOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  const _TaskOptionRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.trailingWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.primary, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: c.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailingWidget != null)
              trailingWidget!
            else ...[
              Text(
                trailing ?? '',
                style: TextStyle(color: c.muted, fontSize: 10),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right_rounded, color: c.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ReviewValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback openTasks;
  const _ProjectDetails({required this.item, required this.openTasks});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['title'] ?? 'Project Details'}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (double.tryParse('${item['progress'] ?? 0}') ?? 0) / 100,
                color: c.primary,
                backgroundColor: c.border,
              ),
              const SizedBox(height: 12),
              _Info('Status', '${item['status'] ?? ''}'),
              _Info('Description', '${item['subtitle'] ?? ''}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: openTasks,
          child: const Text('View Tasks'),
        ),
      ],
    );
  }
}

class _TeamPerformance extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TeamPerformance({required this.data});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: tlPercent(data, 'team_progress'),
                      strokeWidth: 9,
                      color: c.success,
                      backgroundColor: c.border,
                    ),
                  ),
                  Text(
                    '${(tlPercent(data, 'team_progress') * 100).round()}%',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...tlList(data, 'team').map((item) {
          final taskSummary = item['task_summary'] is Map
              ? Map<String, dynamic>.from(item['task_summary'] as Map)
              : <String, dynamic>{};
          final completed = taskSummary['completed'] ?? 0;
          final assigned = taskSummary['assigned'] ?? 0;
          final rate = taskSummary['completion_rate'] ?? item['score'] ?? 0;
          return TlListTile(
            icon: Icons.person_rounded,
            title: '${item['title']}',
            subtitle:
                '${item['subtitle']} • $completed/$assigned tasks completed',
            trailing: '$rate%',
            color: c.success,
          );
        }),
      ],
    );
  }
}

class _SmartDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SmartDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.containsKey('attendance_summary') ||
        item.containsKey('recent_attendance')) {
      return _EmployeeDetails(item: item);
    }
    return _GenericDetails(item: item);
  }
}

class _EmployeeDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  const _EmployeeDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final attendance = item['attendance_summary'] is Map
        ? Map<String, dynamic>.from(item['attendance_summary'] as Map)
        : <String, dynamic>{};
    final performance = item['performance'] is Map
        ? Map<String, dynamic>.from(item['performance'] as Map)
        : <String, dynamic>{};
    final taskSummary = item['task_summary'] is Map
        ? Map<String, dynamic>.from(item['task_summary'] as Map)
        : <String, dynamic>{};
    final recent = item['recent_attendance'] is List
        ? (item['recent_attendance'] as List)
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList()
        : <Map<String, dynamic>>[];
    final score =
        double.tryParse(
          '${performance['score'] ?? item['score'] ?? 0}'.replaceAll('%', ''),
        ) ??
        0;

    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Row(
            children: [
              EmployeeAvatar(
                name: '${item['title'] ?? 'Employee'}',
                photoUrl: '${item['doc_passport_photo'] ?? ''}',
                radius: 27,
                backgroundColor: c.primary.withAlpha(26),
                foregroundColor: c.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['title'] ?? 'Employee'}',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['designation'] ?? item['subtitle'] ?? ''}',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${item['id'] ?? item['trailing'] ?? ''}',
                      style: TextStyle(
                        color: c.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee Details',
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _Info('Email', '${item['email'] ?? '-'}'),
              _Info('Department', '${item['department'] ?? '-'}'),
              _Info(
                'Designation',
                '${item['designation'] ?? item['subtitle'] ?? '-'}',
              ),
              _Info('Date of Joining', '${item['date_of_joining'] ?? '-'}'),
              _Info('Employment Type', '${item['employment_type'] ?? '-'}'),
              _Info('Reporting TL', '${item['reporting_tl'] ?? '-'}'),
              _Info('Work Mode', '${item['work_location'] ?? '-'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MiniStat(
              'Present',
              '${attendance['present'] ?? 0}',
              c.success,
              Icons.check_circle_rounded,
            ),
            _MiniStat(
              'Late Entry',
              '${attendance['late'] ?? 0}',
              c.warning,
              Icons.schedule_rounded,
            ),
            _MiniStat(
              'Absent',
              '${attendance['absent'] ?? 0}',
              c.danger,
              Icons.cancel_rounded,
            ),
            _MiniStat(
              'Records',
              '${attendance['total_records'] ?? 0}',
              c.primary,
              Icons.event_note_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance',
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (score / 100).clamp(0, 1).toDouble(),
                color: c.success,
                backgroundColor: c.border,
              ),
              const SizedBox(height: 10),
              _Info('Score', '${score.round()}%'),
              _Info('Tasks', '${performance['tasks'] ?? '-'}'),
              _Info(
                'Task Completion',
                '${taskSummary['completed'] ?? 0}/${taskSummary['assigned'] ?? 0}',
              ),
              _Info('Attendance', '${performance['attendance'] ?? '-'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Attendance',
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                Text(
                  'No attendance records found',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                ...recent.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${record['date'] ?? '-'}',
                                style: TextStyle(
                                  color: c.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${record['check_in'] ?? '--'} - ${record['check_out'] ?? '--'}',
                                style: TextStyle(
                                  color: c.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${record['status'] ?? '-'}',
                          style: TextStyle(
                            color: _statusColor(c, '${record['status'] ?? ''}'),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(TlPalette c, String status) {
    final lower = status.toLowerCase();
    if (lower.contains('late')) return c.warning;
    if (lower.contains('absent') || lower.contains('reject')) return c.danger;
    return c.success;
  }
}

class _GenericDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GenericDetails({required this.item});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['title'] ?? 'Details'}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _Info('Summary', '${item['subtitle'] ?? ''}'),
              _Info('Status', '${item['trailing'] ?? item['status'] ?? ''}'),
              _Info('Time', '${item['time'] ?? ''}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  final String userId;
  final String email;
  final String name;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final VoidCallback logout;
  const _Profile({
    required this.userId,
    required this.email,
    required this.name,
    required this.profileImage,
    required this.onProfileTap,
    required this.logout,
  });
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        TlCard(
          child: Column(
            children: [
              _ProfileAvatar(
                image: profileImage,
                radius: 34,
                onTap: onProfileTap,
              ),
              const SizedBox(height: 10),
              Text(
                name.trim(),
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(email, style: TextStyle(color: c.muted, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TlListTile(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          subtitle: 'Profile and contact details',
          color: c.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserPersonalInformationScreen(userId: userId),
            ),
          ),
        ),
        TlListTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Security settings',
          color: c.purple,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(employeeId: userId, otc: ''),
            ),
          ),
        ),
        TlListTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notification Settings',
          subtitle: 'Alerts and reminders',
          color: c.warning,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserNotificationSettingsScreen(userId: userId),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: logout,
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.image,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
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

class _ListPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final Color color;
  final ValueChanged<Map<String, dynamic>> onTap;

  const _ListPage({
    this.title = 'Overview',
    required this.items,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<_ListPage> {
  final _search = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final query = _search.text.trim().toLowerCase();
    final visible = widget.items.where((item) {
      final status = '${item['status'] ?? item['trailing'] ?? ''}';
      final matchesStatus =
          _statusFilter == 'All' ||
          status.toLowerCase().contains(_statusFilter.toLowerCase());
      final matchesQuery =
          '${item['title'] ?? item['name'] ?? ''} ${item['subtitle'] ?? item['role'] ?? ''} ${item['trailing'] ?? ''}'
              .toLowerCase()
              .contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
    final statuses = <String>{
      'All',
      ...widget.items
          .map((item) => '${item['status'] ?? item['trailing'] ?? ''}'.trim())
          .where((value) => value.isNotEmpty),
    }.toList();
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactOverviewTile(
                icon: widget.icon,
                label: 'Total',
                value: '${widget.items.length}',
                color: widget.color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactOverviewTile(
                icon: Icons.schedule_rounded,
                label: 'Active',
                value:
                    '${widget.items.where((item) => !'${item['status'] ?? ''}'.toLowerCase().contains('complete')).length}',
                color: c.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.text, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search ${widget.title.toLowerCase()}...',
            hintStyle: TextStyle(color: c.muted),
            prefixIcon: Icon(Icons.search_rounded, color: c.muted, size: 20),
            suffixIcon: query.isEmpty
                ? PopupMenuButton<String>(
                    tooltip: 'Filter ${widget.title.toLowerCase()}',
                    icon: Icon(Icons.tune_rounded, color: c.muted, size: 19),
                    onSelected: (value) =>
                        setState(() => _statusFilter = value),
                    itemBuilder: (_) => statuses
                        .map(
                          (value) => PopupMenuItem(
                            value: value,
                            child: Row(
                              children: [
                                if (_statusFilter == value)
                                  Icon(
                                    Icons.check_rounded,
                                    color: c.primary,
                                    size: 17,
                                  )
                                else
                                  const SizedBox(width: 17),
                                const SizedBox(width: 8),
                                Expanded(child: Text(value)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  )
                : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        if (_statusFilter != 'All') ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('Filter: $_statusFilter'),
              onDeleted: () => setState(() => _statusFilter = 'All'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (visible.isEmpty)
          TlCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(widget.icon, color: widget.color, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    query.isEmpty
                        ? 'No ${widget.title.toLowerCase()} available'
                        : 'No matching results',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    query.isEmpty
                        ? 'New records will appear here.'
                        : 'Try a different search term.',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...visible.map(
            (item) => TlListTile(
              icon: widget.icon,
              title: '${item['title'] ?? item['name']}',
              subtitle: '${item['subtitle'] ?? item['role'] ?? ''}',
              trailing: '${item['trailing'] ?? item['status'] ?? ''}',
              color: widget.color,
              onTap: () => widget.onTap(item),
            ),
          ),
      ],
    );
  }
}

class _CompactOverviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CompactOverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isLeaveNotification(Map<String, dynamic> item) {
  final module = '${item['module'] ?? ''}'.toLowerCase();
  final title = '${item['title'] ?? ''}'.toLowerCase();
  final subtitle = '${item['subtitle'] ?? item['message'] ?? ''}'.toLowerCase();
  return module == 'leave' ||
      title.contains('leave') ||
      subtitle.contains('leave');
}

bool _isClientVisitNotification(Map<String, dynamic> item) {
  final module = '${item['module'] ?? ''}'.trim().toLowerCase();
  return module == 'client_visit' || module == 'client-visit';
}

bool _isMeetingNotification(Map<String, dynamic> item) {
  final module = '${item['module'] ?? ''}'.toLowerCase();
  final title = '${item['title'] ?? ''}'.toLowerCase();
  final subtitle = '${item['subtitle'] ?? item['message'] ?? ''}'.toLowerCase();
  return module == 'meeting' ||
      module == 'meetings' ||
      title.contains('meeting') ||
      subtitle.contains('meeting');
}

bool _approvalIsUrgent(Map<String, dynamic> item) {
  final reason = '${item['reason'] ?? ''}'.toLowerCase();
  final status = '${item['priority'] ?? item['status'] ?? ''}'.toLowerCase();
  final daysText = '${item['duration'] ?? item['days'] ?? '0'}'
      .split(' ')
      .first;
  final days = double.tryParse(daysText) ?? 0;
  return reason.contains('urgent') || status.contains('urgent') || days >= 2;
}

String _approvalWorkflowLabel(
  Map<String, dynamic> item, {
  bool urgent = false,
}) {
  final status = '${item['status'] ?? 'requested'}'.toLowerCase();
  if (status == 'approved') return 'Approved';
  if (status == 'rejected') return 'Rejected';
  if (status == 'cancelled') return 'Cancelled';

  final stage = int.tryParse('${item['current_stage'] ?? 0}') ?? 0;
  final rawApprovers = item['approvers'];
  final approvers = rawApprovers is List
      ? rawApprovers.map((value) => '$value'.trim()).toList()
      : const <String>[];
  if (stage >= 0 && stage < approvers.length && approvers[stage].isNotEmpty) {
    return 'Pending ${approvers[stage]} Approval';
  }
  if (stage == 1) return 'Pending CEO Approval';
  return urgent ? 'Urgent' : 'Pending TL Approval';
}

InputDecoration _fieldDecoration(BuildContext context, String label) {
  final c = TlPalette.of(context);
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: c.row,
    labelStyle: TextStyle(color: c.muted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.primary, width: 1.4),
    ),
  );
}

class _Calendar extends StatelessWidget {
  final String month;
  final String day;
  const _Calendar({required this.month, required this.day});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final now = DateTime.now();
    final activeDay = int.tryParse(day);
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final cells = leading + daysInMonth;
    return TlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  month.isEmpty ? '${now.month}/${now.year}' : month,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: cells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final date = index - leading + 1;
              final active = date == activeDay;
              return Center(
                child: active
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: c.primary,
                        child: Text(
                          '$date',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : Text(
                        '$date',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _Metric(this.title, this.value, this.color, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _Section({
    required this.title,
    required this.action,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: c.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double value;
  final String label;
  const _ProgressCard({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  color: c.primary,
                  backgroundColor: c.border,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TinyMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: c.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TlPalette c;
  final String title;
  final VoidCallback menu;
  final VoidCallback theme;
  const _TopBar({
    required this.c,
    required this.title,
    required this.menu,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.headerPadding,
      child: Row(
        children: [
          IconButton(
            onPressed: menu,
            icon: Icon(Icons.menu_rounded, color: c.text, size: 26),
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
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: theme,
            icon: Icon(
              c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: c.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TlRoleDropdown extends StatelessWidget {
  final TlPalette c;
  final String value;
  final ValueChanged<String> onChanged;

  const _TlRoleDropdown({
    required this.c,
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
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: c.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.primary),
            style: TextStyle(
              color: c.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            selectedItemBuilder: (context) {
              return ['Employee', 'Team Lead'].map((_) {
                return Row(
                  children: [
                    Icon(
                      Icons.manage_accounts_outlined,
                      color: c.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Role Based',
                      style: TextStyle(
                        color: c.muted,
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
                value: 'Team Lead',
                child: Row(
                  children: [
                    Icon(Icons.groups_2_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Team Lead'),
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

class _Drawer extends StatelessWidget {
  final String email;
  final String name;
  final ValueChanged<int> select;
  final VoidCallback logout;
  final VoidCallback openClientVisits;
  const _Drawer({
    required this.email,
    required this.name,
    required this.select,
    required this.logout,
    required this.openClientVisits,
  });
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final textPrimary = c.text;
    final textSecondary = c.muted;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            children: [
              // ── Logo + close ──────────────────────────────────
              Row(
                children: [
                  const BitByteLogo(compact: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'HRMS',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Profile section ───────────────────────────────
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [c.primary, c.success, c.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: c.isDark
                          ? const Color(0xFF0A2238)
                          : const Color(0xFFEEF6FF),
                      child: Icon(
                        Icons.person_rounded,
                        color: c.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.trim().isEmpty ? 'Team Lead' : name.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Team Lead',
                          style: TextStyle(
                            color: c.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: c.border),
              const SizedBox(height: 4),

              // ── Nav items ─────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                          fontSize: 14,
                        ),
                      ),
                      onTap: openClientVisits,
                    ),
                    ..._drawerItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(item.icon, color: c.primary, size: 19),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => select(item.index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Divider(color: c.border),

              // ── Logout ────────────────────────────────────────
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final TlPalette c;
  final int index;
  final ValueChanged<int> select;
  const _BottomNav({
    required this.c,
    required this.index,
    required this.select,
  });
  @override
  Widget build(BuildContext context) {
    const items = [0, 1, 2, 20, 3, 11];
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
      child: Row(
        children: items.map((itemIndex) {
          final selected =
              index == itemIndex ||
              (itemIndex == 2 && (index == 14 || index == 15));
          return Expanded(
            child: InkWell(
              onTap: () => select(itemIndex),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[itemIndex],
                      color: selected ? c.primary : c.muted,
                      size: 18,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        _titles[itemIndex],
                        style: TextStyle(
                          color: selected ? c.primary : c.muted,
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

class _DrawerItemData {
  final int index;
  final String title;
  final IconData icon;

  const _DrawerItemData(this.index, this.title, this.icon);
}

const _drawerItems = [
  _DrawerItemData(0, 'Dashboard', Icons.dashboard_rounded),
  _DrawerItemData(1, 'Team', Icons.groups_rounded),
  _DrawerItemData(2, 'Tasks', Icons.task_alt_rounded),
  _DrawerItemData(15, 'Assign Task', Icons.add_task_rounded),
  _DrawerItemData(3, 'Projects', Icons.work_rounded),
  _DrawerItemData(4, 'Attendance', Icons.calendar_month_rounded),
  _DrawerItemData(9, 'Leave', Icons.beach_access_rounded),
  _DrawerItemData(10, 'Meetings', Icons.event_rounded),
  _DrawerItemData(11, 'Reports', Icons.assessment_rounded),
  _DrawerItemData(12, 'Approvals', Icons.approval_rounded),
  _DrawerItemData(13, 'Notifications', Icons.notifications_rounded),
];

const _titles = [
  'Dashboard',
  'Team',
  'Tasks',
  'Projects',
  'Attendance',
  'Selfie Attendance',
  'Geo Location',
  'Confirm Attendance',
  'Attendance Marked',
  'Leave',
  'Meetings',
  'Reports',
  'Approvals',
  'Notifications',
  'Task Details',
  'Assign Task',
  'Project Details',
  'Team Performance',
  'Details',
  'Profile',
  'Client Visits',
];

const _icons = [
  Icons.dashboard_rounded,
  Icons.groups_rounded,
  Icons.task_alt_rounded,
  Icons.work_rounded,
  Icons.calendar_month_rounded,
  Icons.camera_alt_rounded,
  Icons.location_on_rounded,
  Icons.fact_check_rounded,
  Icons.check_circle_rounded,
  Icons.beach_access_rounded,
  Icons.event_rounded,
  Icons.assessment_rounded,
  Icons.approval_rounded,
  Icons.notifications_rounded,
  Icons.info_rounded,
  Icons.add_task_rounded,
  Icons.work_history_rounded,
  Icons.insights_rounded,
  Icons.description_rounded,
  Icons.account_circle_rounded,
  Icons.add_location_alt_rounded,
];
