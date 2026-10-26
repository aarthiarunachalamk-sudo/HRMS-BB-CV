// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/logout_exit_dialog.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/user_notification_settings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_models.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientVisits/client_visit_screens.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientVisits/client_visit_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_projects_flow_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Management/team_member_allocation_screen.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';

class ManagerDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const ManagerDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<EmployeeDashboardData> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late Future<Map<String, dynamic>> _projectsFuture;
  int _tabIndex = 0;
  Timer? _refreshTimer;
  int _unreadCount = 0;

  static const Color pmPrimary = Color(0xFF0BA360);
  static const Color pmSecondary = Color(0xFF3CBA92);
  static const Color pmAccent = Color(0xFF11998E);

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (_) => _loadAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadAll() {
    if (!mounted) return;
    setState(() {
      _dashboardFuture = EmployeeService().fetchDashboard(widget.userId, widget.email);
      _notificationsFuture = _fetchNotifications();
      _projectsFuture = _fetchProjectsSummary();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final uri = ApiConfig.uri(
        '/notifications/?user_id=${Uri.encodeQueryComponent(widget.userId)}&role=manager',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map && decoded['notifications'] is List) {
          final list = (decoded['notifications'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (mounted) {
            setState(() {
              _unreadCount = list.where((n) => n['is_read'] != true).length;
            });
          }
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> _fetchProjectsSummary() async {
    try {
      final uri = ApiConfig.uri(
        '/ceo/projects-flow/?user_id=${Uri.encodeQueryComponent(widget.userId)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map && decoded['success'] == true) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}
    return {
      'summary': {'total': 3, 'active': 3, 'average_progress': 72},
      'projects': [
        {
          'name': 'HRMS Mobile App v1.69',
          'code': 'PRJ-HRMS',
          'status': 'in_progress',
          'progress': 85,
          'department': 'Mobile Development',
        },
        {
          'name': 'Client Visit Live Tracking',
          'code': 'PRJ-CVT',
          'status': 'in_progress',
          'progress': 90,
          'department': 'Operations',
        },
        {
          'name': 'ERP Enterprise Integration',
          'code': 'PRJ-ERP',
          'status': 'in_progress',
          'progress': 45,
          'department': 'Cloud Ops',
        },
      ],
    };
  }

  void _logout() {
    _refreshTimer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openClientVisitCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientVisitCreateScreen(
          userId: widget.userId,
          service: ClientVisitService(),
          requesterRole: 'manager',
          roleLabel: 'Project Manager',
          initialTeam: 'project_management',
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openClientVisitDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Client Visits Dashboard'),
            backgroundColor: pmPrimary,
            foregroundColor: Colors.white,
          ),
          body: ClientVisitDashboardScreen(
            userId: widget.userId,
            reviewerMode: true,
            allowCreate: true,
          ),
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openProjectsFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CeoProjectsFlowScreen(userId: widget.userId),
      ),
    ).then((_) => _loadAll());
  }

  void _openTeamAllocation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamMemberAllocationScreen(
          userRole: 'pm',
          userName: widget.firstName,
          userEmail: widget.email,
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserNotificationSettingsScreen(userId: widget.userId),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserPersonalInformationScreen(userId: widget.userId),
      ),
    );
  }

  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          employeeId: widget.userId,
          otc: '',
          recoveryMode: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tabIndex != 0) {
          setState(() => _tabIndex = 0);
        } else {
          showLogoutExitConfirmation(context: context, onLogout: _logout);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(textPrimary, cardBg, textSecondary),
          body: ConstellationBackground(
            accentColor: pmPrimary,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(textPrimary, isDark),
                  Expanded(
                    child: IndexedStack(
                      index: _tabIndex,
                      children: [
                        _buildOverviewTab(textPrimary, textSecondary, cardBg, cardBorder),
                        _buildProjectsTab(),
                        _buildClientVisitsTab(),
                        _buildApprovalsTab(textPrimary, textSecondary, cardBg, cardBorder),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(cardBg, cardBorder, textSecondary),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            padding: EdgeInsets.zero,
            tooltip: 'Menu',
            icon: Icon(Icons.menu_rounded, color: textPrimary, size: 26),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
          const BitByteLogo(compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppGreeting.current().label}, ${widget.firstName.isEmpty ? 'Jai' : widget.firstName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [pmPrimary, pmSecondary]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Project Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.userId,
                      style: const TextStyle(
                        color: pmPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined, color: pmPrimary, size: 24),
                onPressed: () => setState(() => _tabIndex = 3),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: pmPrimary,
              size: 22,
            ),
            onPressed: () {
              MyApp.themeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return FutureBuilder<EmployeeDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final data = snapshot.data?.toJson() ?? <String, dynamic>{};
        final profile = data['profile'] is Map
            ? Map<String, dynamic>.from(data['profile'] as Map)
            : <String, dynamic>{};
        final attendance = data['attendance'] is Map
            ? Map<String, dynamic>.from(data['attendance'] as Map)
            : <String, dynamic>{};
        final tasks = data['tasks'] is List
            ? (data['tasks'] as List)
            : <dynamic>[];

        final dept = '${profile['department'] ?? 'Project Management'}';
        final desig = '${profile['designation'] ?? 'Project Manager'}';
        final status = '${attendance['status'] ?? 'Present (On-Site)'}';
        final totalTasks = tasks.length;
        final doneTasks = tasks
            .where(
              (t) =>
                  '${(t as Map?)?['status'] ?? ''}'.toLowerCase() ==
                  'completed',
            )
            .length;

        return RefreshIndicator(
          onRefresh: () async => _loadAll(),
          color: pmPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(dept, desig),
                const SizedBox(height: 18),
                _buildMetricCards(
                  totalTasks: totalTasks,
                  doneTasks: doneTasks,
                  attendanceStatus: status,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  tp: textPrimary,
                  ts: textSecondary,
                ),
                const SizedBox(height: 20),
                _buildQuickActionsRow(textPrimary),
                const SizedBox(height: 22),
                _buildTLApprovalsSection(textPrimary, textSecondary, cardBg, cardBorder),
                const SizedBox(height: 22),
                _buildProjectsSection(textPrimary, textSecondary, cardBg, cardBorder),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(String dept, String desig) {
    final displayName = widget.firstName.isEmpty ? 'Jai Ramachandran' : widget.firstName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [pmPrimary, pmSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: pmPrimary.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                'JR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Project Manager • $dept',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Operations & Approvals Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards({
    required int totalTasks,
    required int doneTasks,
    required String attendanceStatus,
    required Color cardBg,
    required Color cardBorder,
    required Color tp,
    required Color ts,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _projectsFuture,
      builder: (context, projSnapshot) {
        final summary = projSnapshot.data?['summary'] as Map? ?? {};
        final totalProjects = summary['total'] ?? 3;
        final activeProjects = summary['active'] ?? 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _kpiCard(
              title: 'Active Projects',
              value: '$activeProjects',
              sub: 'Total $totalProjects ongoing',
              icon: Icons.folder_special_rounded,
              accent: const Color(0xFF0BA360),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            _kpiCard(
              title: 'Client Visits',
              value: 'Active',
              sub: 'Review & Live GPS',
              icon: Icons.add_location_alt_rounded,
              accent: const Color(0xFF38EF7D),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
              onTap: () => setState(() => _tabIndex = 2),
            ),
            _kpiCard(
              title: 'Team Tasks',
              value: '$totalTasks',
              sub: '$doneTasks completed',
              icon: Icons.assignment_turned_in_rounded,
              accent: const Color(0xFF4FACFE),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
            ),
            _kpiCard(
              title: 'TL Approvals',
              value: '$_unreadCount',
              sub: 'Leaves & Requests',
              icon: Icons.approval_rounded,
              accent: const Color(0xFFFA709A),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
              onTap: () => setState(() => _tabIndex = 3),
            ),
            _kpiCard(
              title: 'Team Resources',
              value: '12 Active',
              sub: 'TLs & Associates',
              icon: Icons.groups_rounded,
              accent: const Color(0xFFF6D365),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
            ),
            _kpiCard(
              title: 'Attendance',
              value: attendanceStatus.isEmpty ? 'Present' : attendanceStatus,
              sub: 'Today • On-site',
              icon: Icons.how_to_reg_rounded,
              accent: const Color(0xFF11998E),
              cardBg: cardBg,
              cardBorder: cardBorder,
              tp: tp,
              ts: ts,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color accent,
    required Color cardBg,
    required Color cardBorder,
    required Color tp,
    required Color ts,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accent, size: 26),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, color: ts, size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tp,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tp,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ts, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _actionChip(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Team & TL Allocation',
                color: const Color(0xFF00C6FF),
                onTap: _openTeamAllocation,
              ),
              const SizedBox(width: 10),
              _actionChip(
                icon: Icons.add_circle_outline_rounded,
                label: 'New Client Visit',
                color: pmPrimary,
                onTap: _openClientVisitCreate,
              ),
              const SizedBox(width: 10),
              _actionChip(
                icon: Icons.map_rounded,
                label: 'Visits Dashboard',
                color: const Color(0xFF38EF7D),
                onTap: _openClientVisitDashboard,
              ),
              const SizedBox(width: 10),
              _actionChip(
                icon: Icons.folder_open_rounded,
                label: 'Projects Flow',
                color: const Color(0xFF4FACFE),
                onTap: _openProjectsFlow,
              ),
              const SizedBox(width: 10),
              _actionChip(
                icon: Icons.checklist_rounded,
                label: 'TL Approvals',
                color: const Color(0xFFFA709A),
                onTap: () => setState(() => _tabIndex = 3),
              ),
              const SizedBox(width: 10),
              _actionChip(
                icon: Icons.tune_rounded,
                label: 'Settings',
                color: Colors.orangeAccent,
                onTap: _openNotificationSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTLApprovalsSection(
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: pmPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Team Lead Approvals & Alerts',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _tabIndex = 3),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationsFuture,
          builder: (context, notifSnapshot) {
            final list = notifSnapshot.data ?? [];
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: pmPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Clear • No Pending Alerts',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'When Team Leads approve leaves or client visits, alerts appear here instantly.',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: list.take(3).map((item) {
                final title = '${item['title'] ?? 'TL Approval Alert'}';
                final message = '${item['message'] ?? ''}';
                final isVisit = title.toLowerCase().contains('visit');
                final isLeave = title.toLowerCase().contains('leave');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isVisit
                                  ? const Color(0xFF38EF7D)
                                  : isLeave
                                      ? pmPrimary
                                      : Colors.amber)
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isVisit
                              ? Icons.location_on_rounded
                              : isLeave
                                  ? Icons.event_available_rounded
                                  : Icons.notifications_active_rounded,
                          color: isVisit
                              ? const Color(0xFF38EF7D)
                              : isLeave
                                  ? pmPrimary
                                  : Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProjectsSection(
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_copy_rounded, color: pmPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ongoing Projects',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _tabIndex = 1),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, dynamic>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            final projects = (snapshot.data?['projects'] as List?)
                    ?.whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                [];

            return Column(
              children: projects.take(3).map((p) {
                final name = '${p['name'] ?? 'Project'}';
                final code = '${p['code'] ?? 'PRJ'}';
                final progress = int.tryParse('${p['progress'] ?? 0}') ?? 50;

                return InkWell(
                  onTap: _openProjectsFlow,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: pmPrimary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$progress%',
                                style: const TextStyle(
                                  color: pmPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$code • ${p['department'] ?? 'Operations'}',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            color: pmPrimary,
                            backgroundColor: pmPrimary.withAlpha(30),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    return CeoProjectsFlowScreen(userId: widget.userId);
  }

  Widget _buildClientVisitsTab() {
    return ClientVisitDashboardScreen(
      userId: widget.userId,
      reviewerMode: true,
      allowCreate: true,
    );
  }

  Widget _buildApprovalsTab(
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return RefreshIndicator(
      onRefresh: () async => _loadAll(),
      color: pmPrimary,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: pmPrimary));
          }
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt_rounded, color: pmPrimary, size: 56),
                  const SizedBox(height: 14),
                  Text(
                    'No Approvals Pending',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All Team Lead decisions and employee requests have been handled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final title = '${item['title'] ?? 'TL Approval'}';
              final message = '${item['message'] ?? ''}';
              final time = '${item['created_at'] ?? ''}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: pmPrimary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        time.length > 16 ? time.substring(0, 16) : time,
                        style: TextStyle(color: textSecondary.withAlpha(150), fontSize: 10),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(Color cardBg, Color cardBorder, Color ts) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: cardBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        selectedItemColor: pmPrimary,
        unselectedItemColor: ts,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_rounded),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location_alt_rounded),
            label: 'Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval_rounded),
            label: 'Approvals',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(Color textPrimary, Color cardBg, Color textSecondary) {
    final displayName = widget.firstName.isEmpty ? 'Jai Ramachandran' : widget.firstName;
    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [pmPrimary, pmSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Text(
                      'JR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Project Manager • Project Management',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded, color: pmPrimary),
                    title: Text('Overview', style: TextStyle(color: textPrimary)),
                    selected: _tabIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _tabIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_special_rounded, color: pmPrimary),
                    title: Text('Project Management', style: TextStyle(color: textPrimary)),
                    selected: _tabIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _tabIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00C6FF)),
                    title: Text('Team & TL Allocation', style: TextStyle(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _openTeamAllocation();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_rounded, color: pmPrimary),
                    title: Text('Client Visit Dashboard', style: TextStyle(color: textPrimary)),
                    selected: _tabIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _tabIndex = 2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded, color: pmPrimary),
                    title: Text('New Client Visit', style: TextStyle(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _openClientVisitCreate();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.approval_rounded, color: pmPrimary),
                    title: Text('TL Approvals Feed', style: TextStyle(color: textPrimary)),
                    selected: _tabIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _tabIndex = 3);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded, color: pmPrimary),
                    title: Text('Notification Settings', style: TextStyle(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _openNotificationSettings();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_rounded, color: pmPrimary),
                    title: Text('Personal Profile', style: TextStyle(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _openProfile();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: pmPrimary),
                    title: Text('Change Password', style: TextStyle(color: textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _openChangePassword();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showLogoutExitConfirmation(
                  context: context,
                  onLogout: _logout,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
