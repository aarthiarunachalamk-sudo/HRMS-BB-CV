import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_approval_category_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_leave_intelligence_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_payroll_overview_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_document_center_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_hiring_pipeline_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_projects_flow_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_performance_matrix_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_reports_flow_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_audit_flow_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_local_documents.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/create_admins.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_dashboard.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_approvals_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<Map<String, dynamic>> _criticalAlerts(dynamic value) {
  return _mapList(value);
}

class CeoDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const CeoDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<CeoDashboard> createState() => _CeoDashboardState();
}

class _CeoDashboardState extends State<CeoDashboard> {
  int _selectedIndex = 0;
  final List<int> _tabHistory = <int>[];
  String _dashboardRole = 'CEO';
  int _dashboardRefreshTick = 0;
  File? _profileImage;
  late Future<Map<String, dynamic>> _drawerProfileFuture;

  static const Color _card = Color(0xFF0F1B2E);
  static const Color _cardAlt = Color(0xFF0A121E);
  static const Color _border = Color(0xFF1E2E44);
  static const Color _gold = Color(0xFFD7932E);
  static const Color _cyan = Color(0xFF0072FF);
  static const Color _green = Color(0xFF13D989);
  static const Color _purple = Color(0xFF9F3BFF);
  static const Color _pink = Color(0xFFFF3D8F);
  static const Color _muted = Color(0xFF8E9CAE);

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.groups_2_outlined, Icons.groups_2_rounded, 'People'),
    _NavItem(Icons.approval_outlined, Icons.approval_rounded, 'Approvals'),
    _NavItem(Icons.more_horiz_outlined, Icons.more_horiz_rounded, 'More'),
  ];

  @override
  void initState() {
    super.initState();
    _drawerProfileFuture = CeoService().fetchProfile(widget.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingMemberCreationPopup();
    });
  }

  void _refreshDrawerProfile() {
    _drawerProfileFuture = CeoService().fetchProfile(widget.userId);
  }

  Future<void> _showPendingMemberCreationPopup() async {
    await AppGreetingSession.waitUntilDismissed();
    if (!mounted) return;
    final data = await CeoService().fetchNotifications(widget.userId);
    if (!mounted) return;

    final rawNotifications = data['notifications'];
    if (rawNotifications is! List) return;
    final pending = rawNotifications
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(
          (item) =>
              item['module'] == 'member_creation' && item['is_read'] != true,
        )
        .toList();
    if (pending.isEmpty) return;

    final latest = pending.first;
    final additionalCount = pending.length - 1;
    final message = _displayText(
      latest['message'],
      fallback: 'A new team member was created successfully.',
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppCelebrationDialog(
        title: _displayText(latest['title'], fallback: 'Team Member Created'),
        message: additionalCount > 0
            ? '$message\n\n$additionalCount more team member creation '
                  '${additionalCount == 1 ? 'notification' : 'notifications'}.'
            : message,
        icon: Icons.check_rounded,
        accent: _green,
        buttonLabel: 'OK',
      ),
    );

    for (final notification in pending) {
      final id = notification['id'];
      if (id is int) {
        await CeoService().markNotificationRead(id, widget.userId);
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openPage(Widget page) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted || result != true) return;
    setState(() {
      _selectedIndex = 0;
      _tabHistory.clear();
      _dashboardRefreshTick++;
      _refreshDrawerProfile();
    });
  }

  void _selectTab(int index, {bool remember = true}) {
    if (index == _selectedIndex) return;
    setState(() {
      if (remember) _tabHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  void _handleSystemBack() {
    if (_tabHistory.isNotEmpty) {
      setState(() => _selectedIndex = _tabHistory.removeLast());
      return;
    }
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    SystemNavigator.pop();
  }

  void _switchRole(String role) {
    if (role == 'Employee') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeDashboard(
            email: widget.email,
            firstName: widget.firstName,
            userId: widget.userId,
            roleSwitchLabel: 'CEO',
            roleSwitchBuilder: (_) => CeoDashboard(
              email: widget.email,
              firstName: widget.firstName,
              userId: widget.userId,
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _dashboardRole = role);
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  Widget _buildSideDrawer(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            children: [
              // â”€â”€ Header row with logo + close â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

              // â”€â”€ Profile section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              FutureBuilder<Map<String, dynamic>>(
                future: _drawerProfileFuture,
                builder: (context, snapshot) {
                  final profile = _stringMap(snapshot.data?['profile']);
                  return _drawerProfileHeader(
                    context,
                    profile: profile,
                    fallbackName: widget.firstName.isEmpty
                        ? 'CEO'
                        : widget.firstName,
                    fallbackEmail: widget.email,
                    fallbackUserId: widget.userId,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  );
                },
              ),
              const SizedBox(height: 18),
              Divider(color: cardBorder),
              const SizedBox(height: 4),

              // â”€â”€ Nav items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerItem(
                      context,
                      Icons.account_circle_rounded,
                      'Profile & Settings',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _ProfileSettingsPage(
                            userId: widget.userId,
                            fallbackName: widget.firstName,
                            fallbackEmail: widget.email,
                            onLogout: () => _openPage(
                              _LogoutConfirmPage(onLogout: _logout),
                            ),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.person_add_rounded,
                      'Create Team Member',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          CeoCreateAdminsPage(createdBy: widget.userId),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.account_balance_wallet_rounded,
                      'Budget Overview',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _BudgetOverviewDynamicPage(userId: widget.userId),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.groups_rounded,
                      'Employee Directory',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _EmployeeDirectoryDynamicPage(userId: widget.userId),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.apartment_rounded,
                      'Department Attendance Performance',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _DepartmentPerformanceDynamicPage(
                            userId: widget.userId,
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.business_rounded,
                      'Branch Performance',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _BranchPerformanceDynamicPage(userId: widget.userId),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.notifications_rounded,
                      'Notifications',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(
                          _NotificationsDynamicPage(userId: widget.userId),
                        );
                      },
                    ),
                    _drawerItem(
                      context,
                      Icons.event_rounded,
                      'Meetings',
                      false,
                      () {
                        Navigator.pop(context);
                        _openPage(_MeetingsDynamicPage(userId: widget.userId));
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder),

              // â”€â”€ Theme toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              ValueListenableBuilder<ThemeMode>(
                valueListenable: MyApp.themeNotifier,
                builder: (context, _, __) {
                  final currentlyDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      currentlyDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: const Color(0xFF00C6FF),
                      size: 20,
                    ),
                    title: Text(
                      currentlyDark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: ThemeConfig.getTextPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      currentlyDark
                          ? 'Switch to light theme'
                          : 'Switch to dark theme',
                      style: TextStyle(
                        color: ThemeConfig.getTextSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      MyApp.themeNotifier.value = currentlyDark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    },
                  );
                },
              ),

              // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openPage(_LogoutConfirmPage(onLogout: _logout));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final c = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: selected
            ? const Color(0xFF00C6FF).withValues(alpha: 0.10)
            : Colors.transparent,
        leading: Icon(
          icon,
          color: selected ? const Color(0xFF00C6FF) : muted,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF00C6FF) : c,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  ImageProvider<Object>? _drawerProfileImageProvider(
    File? localImage,
    String photoUrl,
  ) {
    if (localImage != null) return FileImage(localImage);
    if (photoUrl.startsWith('http')) return NetworkImage(photoUrl);
    return null;
  }

  Widget _drawerProfileAvatar({
    required BuildContext context,
    required File? localImage,
    required String photoUrl,
    required bool isDark,
    required VoidCallback onPickProfileImage,
  }) {
    final imageProvider = _drawerProfileImageProvider(localImage, photoUrl);
    return GestureDetector(
      onTap: onPickProfileImage,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF13D989), Color(0xFF9F3BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CircleAvatar(
          backgroundColor: isDark
              ? const Color(0xFF0A3359)
              : const Color(0xFFEAF7FF),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF00C6FF),
                  size: 30,
                )
              : null,
        ),
      ),
    );
  }

  Widget _drawerProfileHeader(
    BuildContext context, {
    required Map<String, dynamic> profile,
    required String fallbackName,
    required String fallbackEmail,
    required String fallbackUserId,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final name = _displayText(profile['name'], fallback: fallbackName);
    final role = _displayText(
      profile['designation_label'],
      fallback: _displayText(
        profile['role_label'],
        fallback: 'Chief Executive Officer',
      ),
    );
    final id = _displayText(profile['id'], fallback: fallbackUserId);
    final email = _displayText(profile['email'], fallback: fallbackEmail);
    final subtitle = id.isNotEmpty ? id : email;
    final photoUrl = _displayText(profile['photo_url']);

    return Row(
      children: [
        _drawerProfileAvatar(
          context: context,
          localImage: _profileImage,
          photoUrl: photoUrl,
          isDark: isDark,
          onPickProfileImage: _pickProfileImage,
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
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF00C6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardView(
        key: ValueKey(_dashboardRefreshTick),
        firstName: widget.firstName,
        email: widget.email,
        userId: widget.userId,
        profileImage: _profileImage,
        onPickProfileImage: _pickProfileImage,
        selectedRole: _dashboardRole,
        onRoleChanged: _switchRole,
        onOpenApprovals: () => _selectTab(2),
        onOpenReports: () => _openPage(_ReportsView(userId: widget.userId)),
        onOpenDirectory: () => _selectTab(1),
        onOpenAnalytics: () => _openPage(
          _AttendanceIntelligenceFlowPage(
            userId: widget.userId,
            onNavigate: _selectTab,
          ),
        ),
        onOpenProfile: () => _openPage(
          _ProfileSettingsPage(
            userId: widget.userId,
            fallbackName: widget.firstName,
            fallbackEmail: widget.email,
            onLogout: () => _openPage(_LogoutConfirmPage(onLogout: _logout)),
          ),
        ),
        onOpenDepartment: () => _openPage(
          _DepartmentOverviewFlowPage(
            userId: widget.userId,
            onNavigate: _selectTab,
          ),
        ),
        onOpenBranch: () =>
            _openPage(_BranchPerformanceDynamicPage(userId: widget.userId)),
        onCreateMember: () =>
            _openPage(CeoCreateAdminsPage(createdBy: widget.userId)),
        onNavigate: _selectTab,
      ),
      _EmployeeDirectoryDynamicPage(userId: widget.userId, embedded: true),
      _ApprovalsView(userId: widget.userId),
      _MoreView(
        onOrganization: () => _openPage(
          _OrganizationDynamicPage(
            userId: widget.userId,
            onNavigate: _selectTab,
          ),
        ),
        onSettings: () => _openPage(
          _CeoSettingsDashboardPage(
            firstName: widget.firstName,
            email: widget.email,
            userId: widget.userId,
            onOpenProfile: () => _openPage(
              _ProfileSettingsPage(
                userId: widget.userId,
                fallbackName: widget.firstName,
                fallbackEmail: widget.email,
                onLogout: () =>
                    _openPage(_LogoutConfirmPage(onLogout: _logout)),
              ),
            ),
            onOpenAudit: () =>
                _openPage(CeoAuditFlowScreen(userId: widget.userId)),
            onLogout: () => _openPage(_LogoutConfirmPage(onLogout: _logout)),
          ),
        ),
        onBudget: () =>
            _openPage(CeoPayrollOverviewScreen(userId: widget.userId)),
        onNotifications: () =>
            _openPage(CeoAuditFlowScreen(userId: widget.userId)),
        onMeetings: () =>
            _openPage(CeoProjectsFlowScreen(userId: widget.userId)),
        onLeave: () =>
            _openPage(CeoLeaveIntelligenceScreen(userId: widget.userId)),
        onHiring: () =>
            _openPage(CeoHiringPipelineScreen(userId: widget.userId)),
        onDepartment: () => _openPage(
          _DepartmentOverviewFlowPage(
            userId: widget.userId,
            onNavigate: _selectTab,
          ),
        ),
        onPerformance: () =>
            _openPage(CeoPerformanceMatrixScreen(userId: widget.userId)),
        onBranch: () => _openPage(_CeoAiInsightsPage(userId: widget.userId)),
        onReports: () => _openPage(CeoReportsFlowScreen(userId: widget.userId)),
        onDocuments: () =>
            _openPage(CeoDocumentCenterScreen(userId: widget.userId)),
        onAnalytics: () => _openPage(
          _AttendanceIntelligenceFlowPage(
            userId: widget.userId,
            onNavigate: _selectTab,
          ),
        ),
        onLogout: () => _openPage(_LogoutConfirmPage(onLogout: _logout)),
      ),
    ];

    final titles = [
      'CEO Dashboard',
      'People Intelligence',
      'Approvals Center',
      '',
    ];

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: _CeoShell(
        title: titles[_selectedIndex],
        showBack: false,
        drawer: _buildSideDrawer(context),
        trailing: _selectedIndex == 0
            ? IconButton(
                tooltip: 'Notifications',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 42,
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _cyan,
                  size: 22,
                ),
                onPressed: () =>
                    _openPage(_NotificationsDynamicPage(userId: widget.userId)),
              )
            : null,
        bottomNavigationBar: _BottomNavBar(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onChanged: _selectTab,
        ),
        child: pages[_selectedIndex],
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final String firstName;
  final String email;
  final String userId;
  final File? profileImage;
  final VoidCallback onPickProfileImage;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenDirectory;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenDepartment;
  final VoidCallback onOpenBranch;
  final VoidCallback onCreateMember;
  final ValueChanged<int> onNavigate;

  const _DashboardView({
    super.key,
    required this.firstName,
    required this.email,
    required this.userId,
    required this.profileImage,
    required this.onPickProfileImage,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onOpenApprovals,
    required this.onOpenReports,
    required this.onOpenDirectory,
    required this.onOpenAnalytics,
    required this.onOpenProfile,
    required this.onOpenDepartment,
    required this.onOpenBranch,
    required this.onCreateMember,
    required this.onNavigate,
  });

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  late final Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = CeoService().fetchHomeDashboard(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Unable to load data. Please try again.',
                textAlign: TextAlign.center,
                style: _CeoText.mutedFor(context, 12),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        final data = snapshot.data!;
        if (data['success'] != true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Backend dashboard data unavailable\n${data['message'] ?? data}',
                textAlign: TextAlign.center,
                style: _CeoText.mutedFor(context, 12),
              ),
            ),
          );
        }
        final categories = _mapList(data['employee_categories']);
        final rolePeople = _roleMembers(data['role_members']);
        final attendanceHealth = _mapFromDynamic(data['attendance_health']);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            Text(
              '${AppGreeting.current().label}, ${widget.firstName.isEmpty ? 'CEO' : widget.firstName}',
              overflow: TextOverflow.ellipsis,
              style: _CeoText.titleFor(context, 18),
            ),
            const SizedBox(height: 3),
            Text(
              'Here is your company overview',
              style: _CeoText.mutedFor(context, 12),
            ),
            const SizedBox(height: 14),
            _CeoHomeHealthCard(
              score:
                  int.tryParse(
                    _displayText(attendanceHealth['score'], fallback: '0'),
                  ) ??
                  0,
              healthLabel: _displayText(
                attendanceHealth['label'],
                fallback: 'No Data',
              ),
              totalMembers: _displayText(
                attendanceHealth['total_members'],
                fallback: '0',
              ),
              joinedThisMonth: _displayText(
                attendanceHealth['joined_this_month'],
                fallback: '0',
              ),
              presentToday: _displayText(
                attendanceHealth['present_today'],
                fallback: '0',
              ),
              onLeave: _displayText(
                attendanceHealth['on_leave_today'],
                fallback: '0',
              ),
              growth: _displayText(
                attendanceHealth['trend_label'],
                fallback: '+0%',
              ),
              trendPoints: _numberList(attendanceHealth['weekly_scores']),
              onTap: widget.onOpenAnalytics,
            ),
            const SizedBox(height: 14),
            _ApprovalsExecutiveCard(
              items: _mapList(data['approvals_summary']),
              onTap: widget.onOpenApprovals,
              onItemTap: (item) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CeoApprovalCategoryScreen(
                    category: _displayText(item['key']),
                    title: _displayText(item['title'], fallback: 'Approval'),
                    userId: widget.userId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _DepartmentPerformanceExecutiveCard(
              items: categories,
              onTap: widget.onOpenDepartment,
            ),
            const SizedBox(height: 14),
            _BackendPeopleSection(
              title: 'Leadership & Role Details',
              people: rolePeople,
              departmentCount: categories.length,
              emptyText: 'No HR, TL, Manager, Admin, or MD members found',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CeoLeadershipRolesPage(
                    userId: widget.userId,
                    onAssignRole: widget.onCreateMember,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
              onPersonTap: (person) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _EmployeeProfilePage(employee: _employeeFromMap(person)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CriticalAlertsCard(
              alerts: _criticalAlerts(data['critical_alerts']),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CeoCriticalAlertsPage(
                    userId: widget.userId,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
              onAlertTap: (alert) {
                final type = _displayText(alert['type']).toLowerCase();
                if (type == 'payroll') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CeoApprovalCategoryScreen(
                        category: 'salary',
                        title: 'Salary Revision',
                        userId: widget.userId,
                      ),
                    ),
                  );
                } else if (type == 'project' || type == 'projects') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _CeoProjectsPage(userId: widget.userId),
                    ),
                  );
                } else if (type == 'attendance') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _AttendanceIntelligenceFlowPage(
                        userId: widget.userId,
                        onNavigate: widget.onNavigate,
                      ),
                    ),
                  );
                } else if (type == 'hiring' || type == 'compliance') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CeoApprovalCategoryScreen(
                        category: 'hiring',
                        title: 'Hiring Pipeline',
                        userId: widget.userId,
                      ),
                    ),
                  );
                } else {
                  widget.onOpenReports();
                }
              },
            ),
            const SizedBox(height: 14),
            _RecentMembersList(
              members: _mapList(data['recent_members']),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CeoRecentMembersPage(
                    userId: widget.userId,
                    onAddMember: widget.onCreateMember,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
              onAddMember: widget.onCreateMember,
              onMemberTap: (member) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _EmployeeProfilePage(employee: _employeeFromMap(member)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

const List<_NavItem> _ceoViewAllNavItems = [
  _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _NavItem(Icons.groups_2_outlined, Icons.groups_2_rounded, 'People'),
  _NavItem(Icons.approval_outlined, Icons.approval_rounded, 'Approvals'),
  _NavItem(Icons.more_horiz_outlined, Icons.more_horiz_rounded, 'More'),
];

class _CeoLeadershipRolesPage extends StatefulWidget {
  final String userId;
  final VoidCallback onAssignRole;
  final ValueChanged<int> onNavigate;

  const _CeoLeadershipRolesPage({
    required this.userId,
    required this.onAssignRole,
    required this.onNavigate,
  });

  @override
  State<_CeoLeadershipRolesPage> createState() =>
      _CeoLeadershipRolesPageState();
}

class _CeoLeadershipRolesPageState extends State<_CeoLeadershipRolesPage> {
  final _searchController = TextEditingController();
  late final Future<Map<String, dynamic>> _future;
  String _filter = 'All';
  String _sort = 'Role · A–Z';

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchDashboard(widget.userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesRole(Map<String, dynamic> person) {
    final role = _displayText(person['role']).toLowerCase();
    final label = _displayText(person['role_label']).toLowerCase();
    if (_filter == 'Admins') return role == 'admin' || label.contains('admin');
    if (_filter == 'Team Leads') {
      return role == 'tl' || label.contains('team lead');
    }
    if (_filter == 'Department Heads') {
      return ['manager', 'director', 'hr'].contains(role) ||
          label.contains('head');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Leadership & Roles',
      bottomNavigationBar: _BottomNavBar(
        items: _ceoViewAllNavItems,
        selectedIndex: 1,
        onChanged: (index) {
          Navigator.of(context).pop();
          widget.onNavigate(index);
        },
      ),
      trailing: const Icon(
        Icons.notifications_none_rounded,
        color: _CeoDashboardState._cyan,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAssignRole,
        backgroundColor: _CeoDashboardState._cyan,
        foregroundColor: const Color(0xFF02101E),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Assign Role',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          final allPeople = _roleMembers(data['role_members']);
          final query = _searchController.text.trim().toLowerCase();
          final people = allPeople.where((person) {
            final matchesSearch =
                query.isEmpty ||
                [
                  person['name'],
                  person['id'],
                  person['department_label'],
                  person['role_label'],
                ].any(
                  (value) => _displayText(value).toLowerCase().contains(query),
                );
            return matchesSearch && _matchesRole(person);
          }).toList();
          people.sort((a, b) {
            if (_sort == 'Name · A–Z') {
              return _displayText(a['name']).compareTo(_displayText(b['name']));
            }
            if (_sort == 'Members · High') {
              return _mapList(
                b['children'],
              ).length.compareTo(_mapList(a['children']).length);
            }
            final roleResult = _displayText(
              a['role_label'],
            ).compareTo(_displayText(b['role_label']));
            return roleResult != 0
                ? roleResult
                : _displayText(a['name']).compareTo(_displayText(b['name']));
          });
          final admins = allPeople
              .where(
                (person) =>
                    _displayText(person['role']).toLowerCase() == 'admin',
              )
              .length;
          final teamLeads = allPeople
              .where(
                (person) => _displayText(person['role']).toLowerCase() == 'tl',
              )
              .length;
          final departments = _mapList(
            data['employee_categories'],
          ).where((item) => _departmentCount(item) > 0).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
            children: [
              _EmployeeSearchBox(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                hintText: 'Search name, ID or department',
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Admins', 'Team Leads', 'Department Heads']
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _LeadershipFilterChip(
                            label: filter,
                            selected: _filter == filter,
                            onTap: () => setState(() => _filter = filter),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _LeadershipSummaryStrip(
                roles: allPeople.length,
                admins: admins,
                teamLeads: teamLeads,
                departments: departments,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${people.length} Roles',
                      style: _CeoText.titleFor(context, 13),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: _AlertDropdown(
                      icon: Icons.sort_rounded,
                      value: _sort,
                      items: const [
                        'Role · A–Z',
                        'Name · A–Z',
                        'Members · High',
                      ],
                      onChanged: (value) => setState(() => _sort = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (people.isEmpty)
                _GlassCard(
                  child: Text(
                    'No leadership roles match the selected filters',
                    style: _CeoText.mutedFor(context, 12),
                  ),
                )
              else
                ...people.map(
                  (person) => _LeadershipRoleRow(
                    person: person,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _EmployeeProfilePage(
                          employee: _employeeFromMap(person),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LeadershipFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LeadershipFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: selected
            ? _CeoDashboardState._cyan.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? _CeoDashboardState._cyan
              : _CeoDashboardState._border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? _CeoDashboardState._cyan
              : _CeoDashboardState._muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _LeadershipSummaryStrip extends StatelessWidget {
  final int roles;
  final int admins;
  final int teamLeads;
  final int departments;

  const _LeadershipSummaryStrip({
    required this.roles,
    required this.admins,
    required this.teamLeads,
    required this.departments,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
    child: Row(
      children: [
        Expanded(
          child: _LeadershipSummaryValue(
            Icons.groups_rounded,
            '$roles',
            'Total Roles',
            const Color(0xFF4895FF),
          ),
        ),
        const _DashboardDivider(),
        Expanded(
          child: _LeadershipSummaryValue(
            Icons.person_rounded,
            '$admins',
            'Admins',
            const Color(0xFF4895FF),
          ),
        ),
        const _DashboardDivider(),
        Expanded(
          child: _LeadershipSummaryValue(
            Icons.groups_2_rounded,
            '$teamLeads',
            'Team Leads',
            _CeoDashboardState._purple,
          ),
        ),
        const _DashboardDivider(),
        Expanded(
          child: _LeadershipSummaryValue(
            Icons.apartment_rounded,
            '$departments',
            'Departments',
            _CeoDashboardState._cyan,
          ),
        ),
      ],
    ),
  );
}

class _LeadershipSummaryValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _LeadershipSummaryValue(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 23),
      const SizedBox(height: 4),
      Text(value, style: _CeoText.titleFor(context, 17)),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _CeoText.mutedFor(context, 8),
      ),
    ],
  );
}

class _LeadershipRoleRow extends StatelessWidget {
  final Map<String, dynamic> person;
  final VoidCallback onTap;

  const _LeadershipRoleRow({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _displayText(person['status'], fallback: 'Active');
    final statusColor = status.toLowerCase() == 'active'
        ? _CeoDashboardState._green
        : _CeoDashboardState._gold;
    final memberCount = _mapList(person['children']).length;
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _AvatarBadge(
            icon: Icons.person_rounded,
            small: true,
            imageUrl: _displayText(person['doc_passport_photo']),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayText(person['name'], fallback: 'Leader'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 13),
                ),
                Text(
                  _displayText(person['id']),
                  style: _CeoText.mutedFor(context, 10),
                ),
                Text(
                  '${_displayText(person['role_label'], fallback: 'Role')} · ${_displayText(person['department_label'], fallback: '-')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 10),
                ),
                if (_displayText(person['working_under']).isNotEmpty)
                  Text(
                    'Reports to: ${_displayText(person['working_under'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CeoDashboardState._cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$memberCount Members',
                style: _CeoText.mutedFor(context, 9),
              ),
              const SizedBox(height: 5),
              _DashboardPill(status, color: statusColor),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

class _CeoRecentMembersPage extends StatefulWidget {
  final String userId;
  final VoidCallback onAddMember;
  final ValueChanged<int> onNavigate;

  const _CeoRecentMembersPage({
    required this.userId,
    required this.onAddMember,
    required this.onNavigate,
  });

  @override
  State<_CeoRecentMembersPage> createState() => _CeoRecentMembersPageState();
}

class _CeoRecentMembersPageState extends State<_CeoRecentMembersPage> {
  final _searchController = TextEditingController();
  late Future<Map<String, dynamic>> _future;
  String _filter = 'All';
  String _sort = 'Newest First';

  @override
  void initState() {
    super.initState();
    _future = _fetchCreatedMembers();
  }

  Future<Map<String, dynamic>> _fetchCreatedMembers() async {
    Map<String, dynamic> employeesData = {};
    Map<String, dynamic> homeData = {};
    try {
      employeesData = await CeoService().fetchEmployees(widget.userId);
    } catch (_) {
      employeesData = {};
    }
    try {
      homeData = await CeoService().fetchHomeDashboard(widget.userId);
    } catch (_) {
      homeData = {};
    }

    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};
    void addAll(dynamic value) {
      for (final member in _mapList(value)) {
        final id = _displayText(
          member['id'],
          fallback: _displayText(
            member['employee_id'],
            fallback: _displayText(member['email']),
          ),
        );
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        merged.add(member);
      }
    }

    addAll(employeesData['created_members']);
    addAll(homeData['recent_members']);
    addAll(employeesData['active_employees']);

    return {...employeesData, 'success': true, 'created_members': merged};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Recently Created Members',
      bottomNavigationBar: _BottomNavBar(
        items: _ceoViewAllNavItems,
        selectedIndex: 1,
        onChanged: (index) {
          Navigator.of(context).pop();
          widget.onNavigate(index);
        },
      ),
      trailing: IconButton(
        tooltip: 'Add Member',
        onPressed: widget.onAddMember,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: _CeoDashboardState._cyan,
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final allMembers = _mapList(snapshot.data!['created_members']);
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final query = _searchController.text.trim().toLowerCase();
          final members = allMembers.where((member) {
            final status = _displayText(
              member['status'],
              fallback: 'Active',
            ).toLowerCase();
            final created = _memberCreatedAt(member);
            final matchesFilter =
                _filter == 'All' ||
                (_filter == 'Active' && status == 'active') ||
                (_filter == 'Pending' && status != 'active') ||
                (_filter == 'This Week' &&
                    created != null &&
                    !created.isBefore(
                      DateTime(weekStart.year, weekStart.month, weekStart.day),
                    ));
            final matchesSearch =
                query.isEmpty ||
                [
                  member['name'],
                  member['id'],
                  member['department_label'],
                  member['role_label'],
                ].any(
                  (value) => _displayText(value).toLowerCase().contains(query),
                );
            return matchesFilter && matchesSearch;
          }).toList();
          members.sort((a, b) {
            final aDate = _memberCreatedAt(a);
            final bDate = _memberCreatedAt(b);
            var result = (bDate ?? DateTime(1970)).compareTo(
              aDate ?? DateTime(1970),
            );
            if (result == 0) {
              result = _displayText(b['id'], fallback: _displayText(b['email']))
                  .compareTo(
                    _displayText(a['id'], fallback: _displayText(a['email'])),
                  );
            }
            return _sort == 'Oldest First' ? -result : result;
          });
          final active = allMembers
              .where(
                (member) =>
                    _displayText(member['status']).toLowerCase() == 'active',
              )
              .length;
          final pending = allMembers.length - active;
          final addedThisMonth = allMembers.where((member) {
            final created = _memberCreatedAt(member);
            return created != null &&
                created.year == now.year &&
                created.month == now.month;
          }).length;
          final grouped = <String, List<Map<String, dynamic>>>{
            'Today': [],
            'This Week': [],
            'Earlier': [],
          };
          for (final member in members) {
            grouped[_memberDateGroup(member)]!.add(member);
          }
          final groupOrder = _sort == 'Oldest First'
              ? const ['Earlier', 'This Week', 'Today']
              : const ['Today', 'This Week', 'Earlier'];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _EmployeeSearchBox(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                hintText: 'Search name, ID or department',
              ),
              const SizedBox(height: 14),
              _RecentMemberSummaryStrip(
                added: addedThisMonth,
                active: active,
                pending: pending,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Active', 'Pending', 'This Week']
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: _LeadershipFilterChip(
                                  label: filter,
                                  selected: _filter == filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: _AlertDropdown(
                      icon: Icons.sort_rounded,
                      value: _sort,
                      items: const ['Newest First', 'Oldest First'],
                      onChanged: (value) => setState(() => _sort = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (members.isEmpty)
                _GlassCard(
                  child: Text(
                    'No recently created members match the filters',
                    style: _CeoText.mutedFor(context, 12),
                  ),
                ),
              for (final group in groupOrder)
                if (grouped[group]!.isNotEmpty) ...[
                  _AlertGroupTitle(group),
                  ...grouped[group]!.map(
                    (member) => _RecentMemberCenterRow(
                      member: member,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _EmployeeProfilePage(
                            employee: _employeeFromMap(member),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onAddMember,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _CeoDashboardState._cyan,
                  side: const BorderSide(color: _CeoDashboardState._cyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add New Member',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentMemberSummaryStrip extends StatelessWidget {
  final int added;
  final int active;
  final int pending;

  const _RecentMemberSummaryStrip({
    required this.added,
    required this.active,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: Row(
      children: [
        Expanded(
          child: _AlertSummaryValue(
            '$added',
            'Added This Month',
            _CeoDashboardState._cyan,
          ),
        ),
        const _DashboardDivider(),
        Expanded(
          child: _AlertSummaryValue(
            '$active',
            'Active',
            _CeoDashboardState._green,
          ),
        ),
        const _DashboardDivider(),
        Expanded(
          child: _AlertSummaryValue(
            '$pending',
            'Pending',
            _CeoDashboardState._gold,
          ),
        ),
      ],
    ),
  );
}

class _RecentMemberCenterRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onTap;

  const _RecentMemberCenterRow({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _displayText(member['status'], fallback: 'Active');
    final color = status.toLowerCase() == 'active'
        ? _CeoDashboardState._green
        : _CeoDashboardState._gold;
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _InitialsAvatar(
            name: _displayText(member['name'], fallback: 'Member'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayText(member['name'], fallback: 'Member'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 13),
                ),
                Text(
                  '${_displayText(member['role_label'], fallback: 'Role')} · ${_displayText(member['department_label'], fallback: '-')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 10),
                ),
                Text(
                  _displayText(member['id']),
                  style: _CeoText.mutedFor(context, 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DashboardPill(status, color: color),
              const SizedBox(height: 5),
              Text(
                _memberDateLabel(member),
                style: _CeoText.mutedFor(context, 9),
              ),
            ],
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

DateTime? _memberCreatedAt(Map<String, dynamic> member) {
  final value = _displayText(member['created_at']);
  return value.isEmpty ? null : DateTime.tryParse(value)?.toLocal();
}

String _memberDateGroup(Map<String, dynamic> member) {
  final created = _memberCreatedAt(member);
  if (created == null) return 'Earlier';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdDay = DateTime(created.year, created.month, created.day);
  if (createdDay == today) return 'Today';
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  return !createdDay.isBefore(weekStart) ? 'This Week' : 'Earlier';
}

String _memberDateLabel(Map<String, dynamic> member) {
  final created = _memberCreatedAt(member);
  if (created == null) return 'Earlier';
  final group = _memberDateGroup(member);
  final hour = created.hour % 12 == 0 ? 12 : created.hour % 12;
  final minute = created.minute.toString().padLeft(2, '0');
  final period = created.hour >= 12 ? 'PM' : 'AM';
  if (group == 'Today') return 'Today, $hour:$minute $period';
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
  return '${created.day} ${months[created.month - 1]}, $hour:$minute $period';
}

class _CeoCriticalAlertsPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _CeoCriticalAlertsPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_CeoCriticalAlertsPage> createState() => _CeoCriticalAlertsPageState();
}

class _CeoCriticalAlertsPageState extends State<_CeoCriticalAlertsPage> {
  final _searchController = TextEditingController();
  late final Future<Map<String, dynamic>> _future;
  String _status = 'All';
  String _module = 'All Modules';
  String _date = 'All Dates';

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchDashboard(widget.userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAlertAction(Map<String, dynamic> alert) {
    final type = _displayText(alert['type']).toLowerCase();
    Widget page;
    if (type == 'payroll') {
      page = CeoApprovalCategoryScreen(
        category: 'salary',
        title: 'Payroll Approvals',
        userId: widget.userId,
      );
    } else if (type == 'projects' || type == 'project') {
      page = _CeoProjectsPage(userId: widget.userId);
    } else if (type == 'attendance') {
      page = _AnalyticsDynamicView(userId: widget.userId);
    } else if (type == 'hiring' || type == 'compliance') {
      page = CeoApprovalCategoryScreen(
        category: 'hiring',
        title: 'Hiring Pipeline',
        userId: widget.userId,
      );
    } else if (type == 'leave') {
      page = CeoApprovalCategoryScreen(
        category: 'leave',
        title: 'Leave Intelligence',
        userId: widget.userId,
      );
    } else {
      page = _CeoDataDetailPage(title: 'Alert Detail', data: alert);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  bool _matchesDate(Map<String, dynamic> alert) {
    if (_date == 'All Dates') return true;
    final isToday =
        _displayText(alert['date_group'], fallback: 'Today').toLowerCase() ==
        'today';
    return _date == 'Today' ? isToday : !isToday;
  }

  bool get _hasActiveFilters =>
      _status != 'All' || _module != 'All Modules' || _date != 'All Dates';

  Future<void> _showAlertFilters() async {
    final data = await _future;
    if (!mounted) return;
    final modules =
        _criticalAlerts(data['critical_alerts'])
            .map(
              (alert) => _displayText(
                alert['module'],
                fallback: _displayText(alert['type']).toUpperCase(),
              ),
            )
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    var status = _status;
    var module = modules.contains(_module) ? _module : 'All Modules';
    var date = _date;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeConfig.getCardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter Critical Alerts',
                        style: _CeoText.titleFor(context, 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        status = 'All';
                        module = 'All Modules';
                        date = 'All Dates';
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AlertDropdown(
                  icon: Icons.priority_high_rounded,
                  value: status,
                  items: const ['All', 'Critical', 'Warning', 'Resolved'],
                  onChanged: (value) => setSheetState(() => status = value),
                ),
                const SizedBox(height: 10),
                _AlertDropdown(
                  icon: Icons.grid_view_rounded,
                  value: module,
                  items: ['All Modules', ...modules],
                  onChanged: (value) => setSheetState(() => module = value),
                ),
                const SizedBox(height: 10),
                _AlertDropdown(
                  icon: Icons.calendar_month_rounded,
                  value: date,
                  items: const ['All Dates', 'Today', 'Earlier'],
                  onChanged: (value) => setSheetState(() => date = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _status = status;
                        _module = module;
                        _date = date;
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Critical Alerts',
      bottomNavigationBar: _BottomNavBar(
        items: _ceoViewAllNavItems,
        selectedIndex: 0,
        onChanged: (index) {
          Navigator.of(context).pop();
          widget.onNavigate(index);
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: _CeoDashboardState._cyan,
            size: 22,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: _hasActiveFilters
                ? 'Change active filters'
                : 'Filter alerts',
            onPressed: _showAlertFilters,
            icon: Icon(
              _hasActiveFilters
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _hasActiveFilters
                  ? _CeoDashboardState._cyan
                  : Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final allAlerts = _criticalAlerts(snapshot.data!['critical_alerts']);
          final modules =
              allAlerts
                  .map(
                    (alert) => _displayText(
                      alert['module'],
                      fallback: _displayText(alert['type']).toUpperCase(),
                    ),
                  )
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final query = _searchController.text.trim().toLowerCase();
          final filtered = allAlerts.where((alert) {
            final severity = _displayText(alert['severity']).toLowerCase();
            final alertStatus = _displayText(
              alert['status'],
              fallback: 'open',
            ).toLowerCase();
            final module = _displayText(
              alert['module'],
              fallback: _displayText(alert['type']).toUpperCase(),
            );
            final matchesStatus =
                _status == 'All' ||
                (_status == 'Resolved'
                    ? alertStatus == 'resolved'
                    : severity == _status.toLowerCase());
            final matchesModule = _module == 'All Modules' || module == _module;
            final matchesSearch =
                query.isEmpty ||
                [
                  alert['title'],
                  alert['subtitle'],
                  alert['module'],
                  alert['owner'],
                ].any(
                  (value) => _displayText(value).toLowerCase().contains(query),
                );
            return matchesStatus &&
                matchesModule &&
                matchesSearch &&
                _matchesDate(alert);
          }).toList();
          final todayAlerts = filtered
              .where(
                (alert) =>
                    _displayText(
                      alert['date_group'],
                      fallback: 'Today',
                    ).toLowerCase() ==
                    'today',
              )
              .toList();
          final earlierAlerts = filtered
              .where((alert) => !todayAlerts.contains(alert))
              .toList();
          final open = allAlerts
              .where(
                (alert) =>
                    _displayText(
                      alert['status'],
                      fallback: 'open',
                    ).toLowerCase() !=
                    'resolved',
              )
              .length;
          final critical = allAlerts
              .where(
                (alert) =>
                    _displayText(alert['severity']).toLowerCase() == 'critical',
              )
              .length;
          final warning = allAlerts
              .where(
                (alert) =>
                    _displayText(alert['severity']).toLowerCase() == 'warning',
              )
              .length;
          final resolved = allAlerts
              .where(
                (alert) =>
                    _displayText(alert['status']).toLowerCase() == 'resolved',
              )
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _EmployeeSearchBox(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                hintText: 'Search alerts',
              ),
              const SizedBox(height: 14),
              _AlertSummaryStrip(
                open: open,
                critical: critical,
                warning: warning,
                resolved: resolved,
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Critical', 'Warning', 'Resolved']
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AlertFilterChip(
                            label: label,
                            selected: _status == label,
                            onTap: () => setState(() => _status = label),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AlertDropdown(
                      icon: Icons.grid_view_rounded,
                      value: _module,
                      items: ['All Modules', ...modules],
                      onChanged: (value) => setState(() => _module = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AlertDropdown(
                      icon: Icons.calendar_month_rounded,
                      value: _date,
                      items: const ['All Dates', 'Today', 'Earlier'],
                      onChanged: (value) => setState(() => _date = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                _GlassCard(
                  child: Center(
                    child: Text(
                      'No alerts match the selected filters',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              if (todayAlerts.isNotEmpty) ...[
                const _AlertGroupTitle('Today'),
                ...todayAlerts.map(
                  (alert) => _CriticalAlertCenterRow(
                    alert: alert,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CeoCriticalAlertDetailPage(
                          userId: widget.userId,
                          alert: alert,
                          onAction: () => _openAlertAction(alert),
                        ),
                      ),
                    ),
                    onAction: () => _openAlertAction(alert),
                  ),
                ),
              ],
              if (earlierAlerts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _AlertGroupTitle('Earlier'),
                ...earlierAlerts.map(
                  (alert) => _CriticalAlertCenterRow(
                    alert: alert,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CeoCriticalAlertDetailPage(
                          userId: widget.userId,
                          alert: alert,
                          onAction: () => _openAlertAction(alert),
                        ),
                      ),
                    ),
                    onAction: () => _openAlertAction(alert),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AlertSummaryStrip extends StatelessWidget {
  final int open;
  final int critical;
  final int warning;
  final int resolved;

  const _AlertSummaryStrip({
    required this.open,
    required this.critical,
    required this.warning,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: _AlertSummaryValue('$open', 'Open', Colors.redAccent),
          ),
          const _DashboardDivider(),
          Expanded(
            child: _AlertSummaryValue(
              '$critical',
              'Critical',
              Colors.redAccent,
            ),
          ),
          const _DashboardDivider(),
          Expanded(
            child: _AlertSummaryValue(
              '$warning',
              'Warning',
              _CeoDashboardState._gold,
            ),
          ),
          const _DashboardDivider(),
          Expanded(
            child: _AlertSummaryValue(
              '$resolved',
              'Resolved',
              _CeoDashboardState._green,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSummaryValue extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AlertSummaryValue(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(label, style: _CeoText.mutedFor(context, 10)),
    ],
  );
}

class _AlertFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AlertFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = label == 'Critical'
        ? Colors.redAccent
        : label == 'Warning'
        ? _CeoDashboardState._gold
        : label == 'Resolved'
        ? _CeoDashboardState._green
        : _CeoDashboardState._cyan;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : _CeoDashboardState._border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : _CeoDashboardState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AlertDropdown extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _AlertDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: _CeoDashboardState._cardAlt,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _CeoDashboardState._border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: _CeoDashboardState._cardAlt,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _CeoDashboardState._muted,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Icon(icon, color: _CeoDashboardState._muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _CeoText.mutedFor(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    ),
  );
}

class _AlertGroupTitle extends StatelessWidget {
  final String title;

  const _AlertGroupTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: _CeoText.titleFor(context, 14)),
  );
}

class _CriticalAlertCenterRow extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _CriticalAlertCenterRow({
    required this.alert,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final severity = _displayText(alert['severity']).toLowerCase();
    final status = _displayText(alert['status']).toLowerCase();
    final color = status == 'resolved'
        ? _CeoDashboardState._green
        : severity == 'critical'
        ? Colors.redAccent
        : _CeoDashboardState._gold;
    final type = _displayText(alert['type']).toLowerCase();
    final icon = type == 'payroll'
        ? Icons.request_quote_outlined
        : type == 'projects' || type == 'project'
        ? Icons.trending_up_rounded
        : type == 'hiring'
        ? Icons.person_search_rounded
        : type == 'compliance'
        ? Icons.badge_outlined
        : Icons.warning_amber_rounded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
            decoration: BoxDecoration(
              color: _CeoDashboardState._cardAlt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _CeoDashboardState._border),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(-3, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                _IconSquare(icon: icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayText(alert['title'], fallback: 'Alert'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _CeoText.titleFor(context, 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _displayText(alert['subtitle']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _CeoText.mutedFor(context, 10),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _DashboardPill(
                            _displayText(alert['module'], fallback: 'General'),
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _displayText(
                                alert['owner'],
                                fallback: 'CEO Team',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.mutedFor(context, 9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: status == 'resolved' ? null : onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(58, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    status == 'resolved'
                        ? 'Resolved'
                        : _displayText(alert['action'], fallback: 'Review'),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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

class _CeoCriticalAlertDetailPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> alert;
  final VoidCallback onAction;

  const _CeoCriticalAlertDetailPage({
    required this.userId,
    required this.alert,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final severity = _displayText(alert['severity']).toLowerCase();
    final color = severity == 'critical'
        ? Colors.redAccent
        : _CeoDashboardState._gold;
    return _CeoShell(
      title: 'Alert Details',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 38),
                const SizedBox(height: 10),
                Text(
                  _displayText(alert['title'], fallback: 'Critical Alert'),
                  style: _CeoText.titleFor(context, 18),
                ),
                const SizedBox(height: 5),
                Text(
                  _displayText(alert['subtitle']),
                  style: _CeoText.mutedFor(context, 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: Column(
              children: [
                _InfoRow(
                  'Module',
                  _displayText(alert['module'], fallback: '-'),
                ),
                _InfoRow('Severity', _fieldLabel(severity)),
                _InfoRow('Owner', _displayText(alert['owner'], fallback: '-')),
                _InfoRow(
                  'Status',
                  _fieldLabel(_displayText(alert['status'], fallback: 'open')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _displayText(alert['action'], fallback: 'Review Alert'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsDynamicView extends StatelessWidget {
  final String userId;

  const _AnalyticsDynamicView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Attendance Insights',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          final health = _mapFromDynamic(data['attendance_health']);
          final workforce = _mapFromDynamic(data['workforce_today']);
          final departments = _mapList(data['employee_categories']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              const _PeriodSelector(),
              const SizedBox(height: 14),
              _MetricGrid(
                cards: [
                  _MetricData(
                    'Health Score',
                    '${_displayText(health['score'], fallback: '0')}%',
                    _displayText(health['label'], fallback: 'No Data'),
                    Icons.monitor_heart_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _MetricData(
                    'Present Today',
                    _displayText(health['present_today'], fallback: '0'),
                    'Live',
                    Icons.how_to_reg_rounded,
                    _CeoDashboardState._green,
                  ),
                  _MetricData(
                    'Absent Today',
                    _displayText(workforce['absent'], fallback: '0'),
                    'Live',
                    Icons.person_off_rounded,
                    Colors.redAccent,
                  ),
                  _MetricData(
                    'Late Entry',
                    _displayText(workforce['late_entry'], fallback: '0'),
                    'Today',
                    Icons.schedule_rounded,
                    _CeoDashboardState._gold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ChartCard(
                title: 'Weekly Attendance',
                subtitle: 'Current month health score',
                trend:
                    '${_displayText(health['trend_label'], fallback: '+0%')} vs last month',
                bars: _numberList(health['weekly_scores']),
                color: _CeoDashboardState._cyan,
              ),
              const SizedBox(height: 14),
              _DepartmentPerformanceExecutiveCard(
                items: departments,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _DepartmentPerformanceDynamicPage(userId: userId),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _CeoFlowListTile(
                icon: Icons.groups_rounded,
                title: 'Employee Attendance Details',
                subtitle: 'Open an employee profile to view attendance history',
                color: _CeoDashboardState._purple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _EmployeeDirectoryDynamicPage(userId: userId),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceIntelligenceFlowPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _AttendanceIntelligenceFlowPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_AttendanceIntelligenceFlowPage> createState() =>
      _AttendanceIntelligenceFlowPageState();
}

class _AttendanceIntelligenceFlowPageState
    extends State<_AttendanceIntelligenceFlowPage> {
  late Future<Map<String, dynamic>> _future;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(today.year, today.month, today.day - 6),
      end: DateTime(today.year, today.month, today.day),
    );
    _reload();
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _reload() {
    _future = CeoService().fetchAttendanceIntelligence(
      widget.userId,
      dateFrom: _iso(_range.start),
      dateTo: _iso(_range.end),
      selectedDate: _iso(_range.end),
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _pickRange() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _range.end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select attendance date',
    );
    if (selected == null || !mounted) return;
    final end = DateTime(selected.year, selected.month, selected.day);
    setState(() {
      _range = DateTimeRange(
        start: end.subtract(const Duration(days: 6)),
        end: end,
      );
      _reload();
    });
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => _AttendanceFlowShell(
    title: 'Attendance Dashboard',
    onNavigate: widget.onNavigate,
    trailing: IconButton(
      tooltip: 'Select date',
      onPressed: _pickRange,
      icon: const Icon(
        Icons.calendar_month_outlined,
        color: _CeoDashboardState._cyan,
      ),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _CeoLoadError(
            message: 'Unable to fetch attendance details from the backend.',
            onRetry: () => setState(_reload),
          );
        }
        final data = snapshot.data!;
        final summary = _stringMap(data['summary']);
        final daily = _mapList(data['daily']);
        final employees = _mapList(data['employees']);
        final hasSelectedData = _hasAttendanceData(data);
        return RefreshIndicator(
          color: _CeoDashboardState._cyan,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _AttendanceDateBanner(
                data: data,
                label: 'Selected date: ${_displayText(data['selected_date'])}',
                onTap: _pickRange,
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _CeoDashboardState._green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live backend data • ${employees.length} active employees',
                    style: _CeoText.mutedFor(context, 8.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AttendanceMetricsGrid(
                items: [
                  _AttendanceMetricData(
                    'Total Employees',
                    _displayText(summary['total'], fallback: '0'),
                    Icons.groups_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _AttendanceMetricData(
                    'Present',
                    hasSelectedData
                        ? _displayText(summary['present'], fallback: '0')
                        : '0',
                    Icons.badge_outlined,
                    _CeoDashboardState._green,
                  ),
                  _AttendanceMetricData(
                    'Late',
                    hasSelectedData
                        ? _displayText(summary['late'], fallback: '0')
                        : '0',
                    Icons.schedule_rounded,
                    _CeoDashboardState._gold,
                  ),
                  _AttendanceMetricData(
                    'Absent',
                    hasSelectedData
                        ? _displayText(summary['absent'], fallback: '0')
                        : '0',
                    Icons.person_off_outlined,
                    Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Overview',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 12),
                    hasSelectedData
                        ? _AttendanceOverview(summary: summary)
                        : const _AttendanceEmptyState(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trend', style: _CeoText.titleFor(context, 13)),
                    const SizedBox(height: 10),
                    _AttendanceTrendChart(
                      daily: _dailyWithActualData(daily),
                      analysis: false,
                      onDateTap: (date) => _open(
                        _DailyAttendanceFlowPage(
                          userId: widget.userId,
                          onNavigate: widget.onNavigate,
                          initialDate: DateTime.tryParse(date),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 5),
                    _AttendanceActionRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'View Daily Attendance',
                      onTap: () => _open(
                        _DailyAttendanceFlowPage(
                          userId: widget.userId,
                          onNavigate: widget.onNavigate,
                          initialDate: _range.end,
                        ),
                      ),
                    ),
                    _AttendanceActionRow(
                      icon: Icons.analytics_outlined,
                      label: 'Late & Absent Analysis',
                      onTap: () => _open(
                        _LateAbsentAnalysisFlowPage(
                          data: data,
                          userId: widget.userId,
                          onNavigate: widget.onNavigate,
                        ),
                      ),
                    ),
                    _AttendanceActionRow(
                      icon: Icons.file_download_outlined,
                      label: 'Export Attendance Report',
                      onTap: () => _open(
                        _AttendanceExportFlowPage(
                          data: data,
                          userId: widget.userId,
                          onNavigate: widget.onNavigate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (employees.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No active employees were returned by the backend.',
                    textAlign: TextAlign.center,
                    style: _CeoText.mutedFor(context, 10),
                  ),
                ),
              if (!hasSelectedData)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No data available',
                    textAlign: TextAlign.center,
                    style: _CeoText.mutedFor(context, 10),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _DailyAttendanceFlowPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;
  final DateTime? initialDate;

  const _DailyAttendanceFlowPage({
    required this.userId,
    required this.onNavigate,
    this.initialDate,
  });

  @override
  State<_DailyAttendanceFlowPage> createState() =>
      _DailyAttendanceFlowPageState();
}

class _DailyAttendanceFlowPageState extends State<_DailyAttendanceFlowPage> {
  late DateTime _date;
  late Future<Map<String, dynamic>> _future;
  String _query = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _load();
  }

  String get _isoDate =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  void _load() {
    _future = CeoService().fetchAttendanceIntelligence(
      widget.userId,
      selectedDate: _isoDate,
      dateTo: _isoDate,
    );
  }

  void _selectDate(DateTime selected) {
    final normalized = DateTime(selected.year, selected.month, selected.day);
    if (DateUtils.isSameDay(normalized, _date)) return;
    setState(() {
      _date = normalized;
      _filter = 'all';
      _load();
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    _selectDate(selected);
  }

  @override
  Widget build(BuildContext context) => _AttendanceFlowShell(
    title: 'Daily Attendance',
    onNavigate: widget.onNavigate,
    trailing: IconButton(
      onPressed: _pickDate,
      icon: const Icon(
        Icons.calendar_month_outlined,
        color: _CeoDashboardState._cyan,
      ),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _CeoLoadError(
            message: 'Unable to load attendance for $_isoDate.',
            onRetry: () => setState(_load),
          );
        }
        final data = snapshot.data!;
        final summary = _stringMap(data['summary']);
        final all = _mapList(data['employees']);
        final hasSelectedData = _hasAttendanceData(data);
        final employees = all.where((employee) {
          final group = _displayText(employee['selected_group']);
          final matchesFilter = _filter == 'all' || group == _filter;
          final haystack =
              '${employee['name']} ${employee['id']} ${employee['department_label']}'
                  .toLowerCase();
          return matchesFilter && haystack.contains(_query.toLowerCase());
        }).toList();
        if (!hasSelectedData) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
                child: Column(
                  children: [
                    _GlassCard(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: _CeoDashboardState._cyan,
                            onPrimary: const Color(0xFF001321),
                            surface: Colors.transparent,
                            onSurface: ThemeConfig.getTextPrimary(context),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          currentDate: DateTime.now(),
                          onDateChanged: _selectDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AttendanceDateBanner(
                      data: {
                        'date_from': data['selected_date'],
                        'date_to': data['selected_date'],
                      },
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'No data available',
                    style: _CeoText.mutedFor(context, 11),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
              child: Column(
                children: [
                  _GlassCard(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: _CeoDashboardState._cyan,
                          onPrimary: const Color(0xFF001321),
                          surface: Colors.transparent,
                          onSurface: ThemeConfig.getTextPrimary(context),
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        currentDate: DateTime.now(),
                        onDateChanged: _selectDate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AttendanceDateBanner(
                    data: {
                      'date_from': data['selected_date'],
                      'date_to': data['selected_date'],
                    },
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  _OrganizationSearchField(
                    hint: 'Search employee',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AttendanceFilterTab(
                        label: 'All',
                        value: _displayText(summary['total'], fallback: '0'),
                        selected: _filter == 'all',
                        color: _CeoDashboardState._cyan,
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _AttendanceFilterTab(
                        label: 'Present',
                        value: _displayText(summary['present'], fallback: '0'),
                        selected: _filter == 'present',
                        color: _CeoDashboardState._green,
                        onTap: () => setState(() => _filter = 'present'),
                      ),
                      _AttendanceFilterTab(
                        label: 'Late',
                        value: _displayText(summary['late'], fallback: '0'),
                        selected: _filter == 'late',
                        color: _CeoDashboardState._gold,
                        onTap: () => setState(() => _filter = 'late'),
                      ),
                      _AttendanceFilterTab(
                        label: 'Absent',
                        value: _displayText(summary['absent'], fallback: '0'),
                        selected: _filter == 'absent',
                        color: Colors.redAccent,
                        onTap: () => setState(() => _filter = 'absent'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Row(
                children: [
                  Text(
                    'Results for $_isoDate',
                    style: _CeoText.titleFor(context, 11),
                  ),
                  const Spacer(),
                  Text(
                    '${employees.length} employees',
                    style: _CeoText.mutedFor(context, 9),
                  ),
                ],
              ),
            ),
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: _CeoText.mutedFor(context, 11),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return _AttendanceEmployeeRow(
                          employee: employee,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _AttendanceEmployeeDetailFlowPage(
                                employee: employee,
                                data: data,
                                userId: widget.userId,
                                onNavigate: widget.onNavigate,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _LateAbsentAnalysisFlowPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final ValueChanged<int> onNavigate;

  const _LateAbsentAnalysisFlowPage({
    required this.data,
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_LateAbsentAnalysisFlowPage> createState() =>
      _LateAbsentAnalysisFlowPageState();
}

class _LateAbsentAnalysisFlowPageState
    extends State<_LateAbsentAnalysisFlowPage> {
  late Map<String, dynamic> _data;
  late DateTimeRange _range;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    final now = DateTime.now();
    final start = DateTime.tryParse(_displayText(_data['date_from'])) ?? now;
    final end = DateTime.tryParse(_displayText(_data['date_to'])) ?? now;
    _range = DateTimeRange(start: start, end: end);
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select analysis range (maximum 31 days)',
    );
    if (selected == null || !mounted) return;
    final end = selected.end;
    final start = selected.duration.inDays > 30
        ? end.subtract(const Duration(days: 30))
        : selected.start;
    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _loading = true;
      _error = null;
    });
    try {
      final result = await CeoService().fetchAttendanceIntelligence(
        widget.userId,
        dateFrom: _iso(start),
        dateTo: _iso(end),
        selectedDate: _iso(end),
      );
      if (!mounted) return;
      setState(() => _data = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load attendance for this range.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _stringMap(_data['summary']);
    final total = double.tryParse(_displayText(summary['total'])) ?? 0;
    double percentage(String key) {
      final value = double.tryParse(_displayText(summary[key])) ?? 0;
      return total == 0 ? 0 : value / total * 100;
    }

    final departments = _mapList(_data['departments']);
    final dailyWithData = _dailyWithActualData(_mapList(_data['daily']));
    final hasRangeData = dailyWithData.isNotEmpty;
    return _AttendanceFlowShell(
      title: 'Late & Absent Analysis',
      onNavigate: widget.onNavigate,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Select date range',
            onPressed: _loading ? null : _pickRange,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: _CeoDashboardState._cyan,
            ),
          ),
          IconButton(
            tooltip: 'Export report',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _AttendanceExportFlowPage(
                  data: _data,
                  userId: widget.userId,
                  initialType: 'Late & Absent Analysis',
                  onNavigate: widget.onNavigate,
                ),
              ),
            ),
            icon: const Icon(
              Icons.file_download_outlined,
              color: _CeoDashboardState._cyan,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            children: [
              _AttendanceDateBanner(data: _data, onTap: _pickRange),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 9),
                ),
              ],
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _AttendanceAnalysisMetric(
                      label: 'Late Arrivals',
                      value: hasRangeData
                          ? _displayText(summary['late'], fallback: '0')
                          : '0',
                      percentage: hasRangeData ? percentage('late') : 0,
                      color: _CeoDashboardState._gold,
                      icon: Icons.schedule_rounded,
                    ),
                    _AttendanceAnalysisMetric(
                      label: 'Absentees',
                      value: hasRangeData
                          ? _displayText(summary['absent'], fallback: '0')
                          : '0',
                      percentage: hasRangeData ? percentage('absent') : 0,
                      color: Colors.redAccent,
                      icon: Icons.person_off_outlined,
                    ),
                  ];
                  if (constraints.maxWidth < 330) {
                    return Column(
                      children: [
                        cards.first,
                        const SizedBox(height: 9),
                        cards.last,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cards.first),
                      const SizedBox(width: 9),
                      Expanded(child: cards.last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Trend', style: _CeoText.titleFor(context, 13)),
                    const SizedBox(height: 12),
                    hasRangeData
                        ? _AttendanceTrendChart(
                            daily: dailyWithData,
                            analysis: true,
                            onDateTap: (date) => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _DailyAttendanceFlowPage(
                                  userId: widget.userId,
                                  onNavigate: widget.onNavigate,
                                  initialDate: DateTime.tryParse(date),
                                ),
                              ),
                            ),
                          )
                        : const _AttendanceEmptyState(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department Breakdown',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 10),
                    if (!hasRangeData)
                      const _AttendanceEmptyState()
                    else
                      ...departments.map(
                        (department) =>
                            _AttendanceDepartmentRow(department: department),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66001121),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _CeoDashboardState._cyan,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceEmployeeDetailFlowPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<String, dynamic> data;
  final String userId;
  final ValueChanged<int> onNavigate;

  const _AttendanceEmployeeDetailFlowPage({
    required this.employee,
    required this.data,
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_AttendanceEmployeeDetailFlowPage> createState() =>
      _AttendanceEmployeeDetailFlowPageState();
}

class _AttendanceEmployeeDetailFlowPageState
    extends State<_AttendanceEmployeeDetailFlowPage> {
  late Map<String, dynamic> _employee;
  late Map<String, dynamic> _data;
  late DateTimeRange _range;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _data = widget.data;
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime.tryParse(_displayText(_data['date_from'])) ?? now,
      end: DateTime.tryParse(_displayText(_data['date_to'])) ?? now,
    );
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select employee attendance range',
    );
    if (selected == null || !mounted) return;
    final end = selected.end;
    final start = selected.duration.inDays > 30
        ? end.subtract(const Duration(days: 30))
        : selected.start;
    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _loading = true;
    });
    try {
      final result = await CeoService().fetchAttendanceIntelligence(
        widget.userId,
        dateFrom: _iso(start),
        dateTo: _iso(end),
        selectedDate: _iso(end),
      );
      final employeeId = _displayText(_employee['id']);
      final matches = _mapList(
        result['employees'],
      ).where((item) => _displayText(item['id']) == employeeId);
      if (!mounted) return;
      setState(() {
        _data = result;
        if (matches.isNotEmpty) _employee = matches.first;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load this date range.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _stringMap(_employee['summary']);
    final history = _mapList(_employee['history']);
    return _AttendanceFlowShell(
      title: 'Employee Detail',
      onNavigate: widget.onNavigate,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Select date range',
            onPressed: _loading ? null : _pickRange,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: _CeoDashboardState._cyan,
            ),
          ),
          IconButton(
            tooltip: 'Export employee attendance',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _AttendanceExportFlowPage(
                  data: _data,
                  userId: widget.userId,
                  employeeId: _displayText(_employee['id']),
                  initialType: 'Employee Attendance',
                  onNavigate: widget.onNavigate,
                ),
              ),
            ),
            icon: const Icon(
              Icons.file_download_outlined,
              color: _CeoDashboardState._muted,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            children: [
              _AttendanceDateBanner(data: _data, onTap: _pickRange),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: _CeoDashboardState._cyan.withValues(
                      alpha: .14,
                    ),
                    child: Text(
                      _initials(_displayText(_employee['name'])),
                      style: const TextStyle(
                        color: _CeoDashboardState._cyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayText(_employee['name'], fallback: 'Employee'),
                          style: _CeoText.titleFor(context, 17),
                        ),
                        Text(
                          _displayText(_employee['id']),
                          style: _CeoText.mutedFor(context, 9.5),
                        ),
                        Text(
                          '${_displayText(_employee['designation'])} • ${_displayText(_employee['department_label'])}',
                          style: _CeoText.mutedFor(context, 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OrganizationStatRow(
                items: [
                  (
                    'Date of Joining',
                    _displayText(_employee['date_of_joining']),
                  ),
                  (
                    'Reporting Manager',
                    _displayText(_employee['reporting_manager']),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _OrganizationStatRow(
                items: [
                  ('Work Location', _displayText(_employee['work_location'])),
                  (
                    'Attendance Type',
                    _displayText(_employee['employment_type']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Summary',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 10),
                    _OrganizationStatRow(
                      items: [
                        (
                          'Present',
                          _displayText(summary['present'], fallback: '0'),
                        ),
                        ('Late', _displayText(summary['late'], fallback: '0')),
                        (
                          'Absent',
                          _displayText(summary['absent'], fallback: '0'),
                        ),
                        (
                          'Attendance %',
                          '${_displayText(summary['percentage'], fallback: '0')}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Attendance',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 6),
                    ...history.map(
                      (record) => _AttendanceHistoryRow(
                        record: record,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _DailyAttendanceFlowPage(
                              userId: widget.userId,
                              onNavigate: widget.onNavigate,
                              initialDate: DateTime.tryParse(
                                _displayText(record['date']),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66001121),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _CeoDashboardState._cyan,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceExportFlowPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final ValueChanged<int> onNavigate;
  final String initialType;
  final String? employeeId;

  const _AttendanceExportFlowPage({
    required this.data,
    required this.userId,
    required this.onNavigate,
    this.initialType = 'Daily Attendance Summary',
    this.employeeId,
  });

  @override
  State<_AttendanceExportFlowPage> createState() =>
      _AttendanceExportFlowPageState();
}

class _AttendanceExportFlowPageState extends State<_AttendanceExportFlowPage> {
  static const _downloadChannel = MethodChannel('hrms/files');
  late String _type;
  late Map<String, dynamic> _data;
  late DateTimeRange _range;
  String _format = 'PDF';
  String _department = 'All';
  String _location = 'All';
  String _employmentType = 'All';
  bool _exporting = false;
  bool _loadingDates = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _data = widget.data;
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime.tryParse(_displayText(_data['date_from'])) ?? now,
      end: DateTime.tryParse(_displayText(_data['date_to'])) ?? now,
    );
  }

  List<Map<String, dynamic>> get _employees {
    final all = _mapList(_data['employees']);
    return all.where((item) {
      if (widget.employeeId != null &&
          _displayText(item['id']) != widget.employeeId) {
        return false;
      }
      if (_department != 'All' &&
          _displayText(item['department_label']) != _department) {
        return false;
      }
      if (_location != 'All' &&
          _displayText(item['work_location']) != _location) {
        return false;
      }
      if (_employmentType != 'All' &&
          _displayText(item['employment_type']) != _employmentType) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> _filterOptions(String key) {
    final values =
        _mapList(_data['employees'])
            .map((item) => _displayText(item[key]))
            .where((value) => value.isNotEmpty && value != '-')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select report date range',
    );
    if (selected == null || !mounted) return;
    final end = selected.end;
    final start = selected.duration.inDays > 30
        ? end.subtract(const Duration(days: 30))
        : selected.start;
    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _loadingDates = true;
    });
    try {
      final result = await CeoService().fetchAttendanceIntelligence(
        widget.userId,
        dateFrom: _iso(start),
        dateTo: _iso(end),
        selectedDate: _iso(end),
      );
      if (mounted) setState(() => _data = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load this report range.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDates = false);
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final safeType = _type
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      late final Uint8List bytes;
      late final String extension;
      late final String mimeType;
      if (_format == 'PDF') {
        final document = pw.Document();
        document.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (_) => [
              pw.Text(
                _type,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${_displayText(_data['date_from'])} to ${_displayText(_data['date_to'])}',
              ),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Employee ID',
                  'Name',
                  'Department',
                  'Status',
                  'Check In',
                  'Attendance %',
                ],
                data: _employees
                    .map(
                      (employee) => [
                        _displayText(employee['id']),
                        _displayText(employee['name']),
                        _displayText(employee['department_label']),
                        _displayText(employee['selected_status']),
                        _displayText(employee['selected_check_in']),
                        '${_displayText(_stringMap(employee['summary'])['percentage'])}%',
                      ],
                    )
                    .toList(),
              ),
            ],
          ),
        );
        bytes = await document.save();
        extension = 'pdf';
        mimeType = 'application/pdf';
      } else {
        final rows = <String>[
          'Employee ID,Name,Department,Status,Check In,Check Out,Attendance Percentage',
          ..._employees.map((employee) {
            String cell(dynamic value) =>
                '"${_displayText(value).replaceAll('"', '""')}"';
            return [
              employee['id'],
              employee['name'],
              employee['department_label'],
              employee['selected_status'],
              employee['selected_check_in'],
              employee['selected_check_out'],
              _stringMap(employee['summary'])['percentage'],
            ].map(cell).join(',');
          }),
        ];
        extension = _format == 'Excel' ? 'xls' : 'csv';
        mimeType = _format == 'Excel' ? 'application/vnd.ms-excel' : 'text/csv';
        bytes = Uint8List.fromList(utf8.encode(rows.join('\n')));
      }
      final fileName = '${safeType}_$stamp.$extension';
      late final String savedUrl;
      final savedLocation = 'Downloads/BitByte HRMS/$fileName';
      if (Platform.isAndroid) {
        savedUrl =
            await _downloadChannel.invokeMethod<String>('saveToDownloads', {
              'fileName': fileName,
              'mimeType': mimeType,
              'bytes': bytes,
            }) ??
            savedLocation;
      } else {
        final directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        savedUrl = file.uri.toString();
      }
      await CeoLocalDocuments.save(
        userId: widget.userId,
        title: _type,
        category: 'Attendance Reports',
        extension: extension,
        url: savedUrl,
        displayPath: savedLocation,
        owner: widget.userId.isEmpty ? 'CEO' : widget.userId,
        status: 'Saved',
        direction: 'Saved',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report saved in $savedLocation')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to export report: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AttendanceFlowShell(
    title: 'Export Report',
    onNavigate: widget.onNavigate,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Type', style: _CeoText.titleFor(context, 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          'Daily Attendance Summary',
                          'Late & Absent Analysis',
                          'Department Attendance',
                          'Employee Attendance',
                          'Custom Report',
                        ]
                        .map(
                          (type) => ChoiceChip(
                            label: Text(type),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: _CeoText.titleFor(context, 12)),
              const SizedBox(height: 8),
              _AttendanceExportFilter(
                label: 'Department',
                value: _department,
                options: _filterOptions('department_label'),
                onChanged: (value) => setState(() => _department = value),
              ),
              _AttendanceExportFilter(
                label: 'Location',
                value: _location,
                options: _filterOptions('work_location'),
                onChanged: (value) => setState(() => _location = value),
              ),
              _AttendanceExportFilter(
                label: 'Employment Type',
                value: _employmentType,
                options: _filterOptions('employment_type'),
                onChanged: (value) => setState(() => _employmentType = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          onTap: _loadingDates ? null : _pickRange,
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: _CeoDashboardState._cyan,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date Range', style: _CeoText.titleFor(context, 12)),
                    const SizedBox(height: 5),
                    Text(
                      '${_displayText(_data['date_from'])} – ${_displayText(_data['date_to'])}',
                      style: _CeoText.mutedFor(context, 10),
                    ),
                  ],
                ),
              ),
              if (_loadingDates)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _CeoDashboardState._muted,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Format', style: _CeoText.titleFor(context, 12)),
              const SizedBox(height: 8),
              Row(
                children: ['PDF', 'Excel', 'CSV']
                    .map(
                      (format) => Expanded(
                        child: RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            format,
                            style: _CeoText.mutedFor(context, 9),
                          ),
                          value: format,
                          groupValue: _format,
                          activeColor: _CeoDashboardState._cyan,
                          onChanged: (value) =>
                              setState(() => _format = value!),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _exporting ? null : _export,
          style: FilledButton.styleFrom(
            backgroundColor: _CeoDashboardState._cyan,
            foregroundColor: const Color(0xFF001321),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_outlined),
          label: const Text(
            'Export Report',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _AttendanceExportFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _AttendanceExportFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: options.contains(value) ? value : 'All',
    isExpanded: true,
    dropdownColor: _CeoDashboardState._card,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: _CeoText.mutedFor(context, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _CeoDashboardState._border),
      ),
    ),
    style: _CeoText.titleFor(context, 10),
    items: options
        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
        .toList(),
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );
}

class _AttendanceFlowShell extends StatelessWidget {
  final String title;
  final Widget child;
  final ValueChanged<int> onNavigate;
  final Widget? trailing;

  const _AttendanceFlowShell({
    required this.title,
    required this.child,
    required this.onNavigate,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => _CeoShell(
    title: title,
    trailing: trailing,
    bottomNavigationBar: _BottomNavBar(
      items: _ceoViewAllNavItems,
      selectedIndex: 3,
      onChanged: (index) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        onNavigate(index);
      },
    ),
    child: child,
  );
}

class _AttendanceDateBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final String? label;

  const _AttendanceDateBanner({required this.data, this.onTap, this.label});

  String _friendlyDate(dynamic value) {
    final parsed = DateTime.tryParse(_displayText(value));
    if (parsed == null) return _displayText(value, fallback: 'Select date');
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
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _CeoDashboardState._card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _CeoDashboardState._border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label ??
                  (_displayText(data['date_from']) ==
                          _displayText(data['date_to'])
                      ? _friendlyDate(data['date_from'])
                      : '${_friendlyDate(data['date_from'])} – ${_friendlyDate(data['date_to'])}'),
              overflow: TextOverflow.ellipsis,
              style: _CeoText.titleFor(context, 10),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.calendar_month_outlined,
            size: 16,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    ),
  );
}

class _AttendanceMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AttendanceMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _CeoDashboardState._card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _CeoDashboardState._border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: _CeoText.mutedFor(context, 9)),
              const SizedBox(height: 4),
              Text(value, style: _CeoText.titleFor(context, 18)),
            ],
          ),
        ),
        Icon(icon, color: color, size: 27),
      ],
    ),
  );
}

class _AttendanceMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AttendanceMetricData(this.label, this.value, this.icon, this.color);
}

class _AttendanceMetricsGrid extends StatelessWidget {
  final List<_AttendanceMetricData> items;

  const _AttendanceMetricsGrid({required this.items});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      final spacing = 9.0;
      final width =
          (constraints.maxWidth - (spacing * (columns - 1))) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                height: 92,
                child: _AttendanceMetricCard(
                  label: item.label,
                  value: item.value,
                  icon: item.icon,
                  color: item.color,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _AttendanceOverview extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _AttendanceOverview({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percentage =
        double.tryParse(_displayText(summary['attendance_percentage'])) ?? 0;
    final chart = SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 92,
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: 20,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.redAccent.withValues(alpha: .72),
              color: _CeoDashboardState._green,
            ),
          ),
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ThemeConfig.getCardBg(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: _CeoText.titleFor(context, 15),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Present',
                      textAlign: TextAlign.center,
                      style: _CeoText.mutedFor(context, 7.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AttendanceLegend(
          label: 'Present',
          value: _displayText(summary['present'], fallback: '0'),
          color: _CeoDashboardState._green,
        ),
        _AttendanceLegend(
          label: 'Late',
          value: _displayText(summary['late'], fallback: '0'),
          color: _CeoDashboardState._gold,
        ),
        _AttendanceLegend(
          label: 'Absent',
          value: _displayText(summary['absent'], fallback: '0'),
          color: Colors.redAccent,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(children: [chart, const SizedBox(height: 12), legend]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chart,
            const SizedBox(width: 22),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _AttendanceEmptyState extends StatelessWidget {
  const _AttendanceEmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text('No data available', style: _CeoText.mutedFor(context, 11)),
    ),
  );
}

bool _hasAttendanceData(Map<String, dynamic> data) {
  final summary = _stringMap(data['summary']);
  final explicit = summary['has_data'];
  if (explicit is bool) return explicit;
  if ('${explicit ?? ''}'.toLowerCase() == 'true') return true;
  if ('${explicit ?? ''}'.toLowerCase() == 'false') return false;

  final records = int.tryParse(_displayText(summary['records']));
  if (records != null) return records > 0;

  final selectedDate = _displayText(data['selected_date']);
  if (selectedDate.isEmpty) return _mapList(data['employees']).isNotEmpty;
  return _mapList(data['employees']).any(
    (employee) => _mapList(employee['history']).any(
      (record) =>
          _displayText(record['date']) == selectedDate &&
          (_displayText(record['group']) != 'absent' ||
              _displayText(record['check_in'], fallback: '--') != '--' ||
              _displayText(record['check_out'], fallback: '--') != '--' ||
              _displayText(record['working_hours'], fallback: '--') != '--'),
    ),
  );
}

List<Map<String, dynamic>> _dailyWithActualData(
  List<Map<String, dynamic>> daily,
) {
  return daily.where((item) {
    final explicit = item['has_data'];
    if (explicit is bool) return explicit;
    if ('${explicit ?? ''}'.toLowerCase() == 'true') return true;
    if ('${explicit ?? ''}'.toLowerCase() == 'false') return false;
    final records = int.tryParse(_displayText(item['records']));
    if (records != null) return records > 0;
    final present = int.tryParse(_displayText(item['present'])) ?? 0;
    final late = int.tryParse(_displayText(item['late'])) ?? 0;
    final percentage = double.tryParse(_displayText(item['percentage'])) ?? 0;
    return present > 0 || late > 0 || percentage > 0;
  }).toList();
}

class _AttendanceLegend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AttendanceLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(width: 9, height: 9, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: _CeoText.mutedFor(context, 9))),
        Text(value, style: _CeoText.titleFor(context, 9.5)),
      ],
    ),
  );
}

class _AttendanceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> daily;
  final bool analysis;
  final ValueChanged<String>? onDateTap;

  const _AttendanceTrendChart({
    required this.daily,
    required this.analysis,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = daily.fold<double>(1, (value, item) {
      final next = analysis
          ? math.max(
              double.tryParse(_displayText(item['late'])) ?? 0,
              double.tryParse(_displayText(item['absent'])) ?? 0,
            )
          : double.tryParse(_displayText(item['percentage'])) ?? 0;
      return math.max(value, next);
    });
    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: daily.map((item) {
          final primary = analysis
              ? double.tryParse(_displayText(item['late'])) ?? 0
              : double.tryParse(_displayText(item['percentage'])) ?? 0;
          final secondary = double.tryParse(_displayText(item['absent'])) ?? 0;
          final date = _displayText(item['date']);
          return Expanded(
            child: InkWell(
              onTap: onDateTap == null ? null : () => onDateTap!(date),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: analysis ? 8 : 14,
                            height: math.max(3, 110 * primary / maxValue),
                            decoration: BoxDecoration(
                              color: analysis
                                  ? _CeoDashboardState._gold
                                  : _CeoDashboardState._cyan,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          if (analysis) ...[
                            const SizedBox(width: 3),
                            Container(
                              width: 8,
                              height: math.max(3, 110 * secondary / maxValue),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date.length >= 10 ? date.substring(8) : date,
                      style: _CeoText.mutedFor(context, 7),
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

class _AttendanceActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttendanceActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: _CeoDashboardState._cyan),
    title: Text(label, style: _CeoText.titleFor(context, 10)),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: _CeoDashboardState._muted,
    ),
    onTap: onTap,
  );
}

class _AttendanceFilterTab extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _AttendanceFilterTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? ThemeConfig.blueGradient : null,
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? ThemeConfig.loginButtonColor
                  : _CeoDashboardState._border,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 8.5,
              ),
            ),
            Text(
              value,
              style: _CeoText.titleFor(
                context,
                10.5,
              ).copyWith(color: selected ? Colors.white : null),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AttendanceEmployeeRow extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onTap;
  const _AttendanceEmployeeRow({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final group = _displayText(employee['selected_group']);
    final color = group == 'present'
        ? _CeoDashboardState._green
        : group == 'late'
        ? _CeoDashboardState._gold
        : Colors.redAccent;
    return _GlassCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Text(
            _initials(_displayText(employee['name'])),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          _displayText(employee['name']),
          style: _CeoText.titleFor(context, 10.5),
        ),
        subtitle: Text(
          _displayText(employee['id']),
          style: _CeoText.mutedFor(context, 8.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _displayText(employee['selected_status']),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              _displayText(employee['selected_check_in']),
              style: _CeoText.mutedFor(context, 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceAnalysisMetric extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;
  final Color color;
  final IconData icon;
  const _AttendanceAnalysisMetric({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 9)),
              Text(value, style: _CeoText.titleFor(context, 19)),
              Text(
                '${percentage.toStringAsFixed(1)}% of total',
                style: TextStyle(color: color, fontSize: 8),
              ),
            ],
          ),
        ),
        Icon(icon, color: color, size: 28),
      ],
    ),
  );
}

class _AttendanceDepartmentRow extends StatelessWidget {
  final Map<String, dynamic> department;
  const _AttendanceDepartmentRow({required this.department});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            _fieldLabel(_displayText(department['department'])),
            overflow: TextOverflow.ellipsis,
            style: _CeoText.titleFor(context, 9),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Late ${_displayText(department['late_percentage'])}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _CeoDashboardState._gold,
              fontSize: 8,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Absent ${_displayText(department['absent_percentage'])}%',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.redAccent, fontSize: 8),
          ),
        ),
      ],
    ),
  );
}

class _AttendanceHistoryRow extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback? onTap;
  const _AttendanceHistoryRow({required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final group = _displayText(record['group']);
    final color = group == 'present'
        ? _CeoDashboardState._green
        : group == 'late'
        ? _CeoDashboardState._gold
        : Colors.redAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayText(record['date']),
                style: _CeoText.mutedFor(context, 9),
              ),
            ),
            Text(
              _displayText(record['status']),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 62,
              child: Text(
                _displayText(record['check_in']),
                textAlign: TextAlign.end,
                style: _CeoText.mutedFor(context, 8.5),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: _CeoDashboardState._cyan,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportsView extends StatelessWidget {
  final String userId;
  const _ReportsView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Reports',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchReports(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final reports = snapshot.data!['reports'] is List
              ? snapshot.data!['reports'] as List
              : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              if (reports.isEmpty)
                _GlassCard(
                  child: Center(
                    child: Text(
                      'No reports found',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ...reports.map((item) {
                final report = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                return _ReportTile(
                  _reportIcon(_displayText(report['type'])),
                  _displayText(report['title'], fallback: 'Report'),
                  _displayText(report['subtitle'], fallback: 'View report'),
                  _reportColor(_displayText(report['type'])),
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ReportDetailsDynamicPage(
                        userId: userId,
                        report: report,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ApprovalsView extends StatefulWidget {
  final String userId;
  const _ApprovalsView({required this.userId});

  @override
  State<_ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<_ApprovalsView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: CeoService().fetchApprovals(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }

        final categories = _mapList(snapshot.data!['summary']);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            _GlassCard(
              child: Text(
                'Select an approval category to view its pending records and history.',
                style: _CeoText.mutedFor(context, 12),
              ),
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No approval data from backend',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ),
            ...categories.map((category) {
              final priority = _displayText(
                category['priority'],
                fallback: 'Clear',
              );
              return _ApprovalTile(
                _approvalCategoryIcon(_displayText(category['key'])),
                _displayText(category['title'], fallback: 'Approval'),
                '${_displayText(category['count'], fallback: '0')} pending - $priority',
                _priorityColor(priority),
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CeoApprovalCategoryScreen(
                      category: _displayText(category['key']),
                      title: _displayText(
                        category['title'],
                        fallback: 'Approval',
                      ),
                      userId: widget.userId,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MoreView extends StatelessWidget {
  final VoidCallback onOrganization;
  final VoidCallback onSettings;
  final VoidCallback onBudget;
  final VoidCallback onNotifications;
  final VoidCallback onMeetings;
  final VoidCallback onLeave;
  final VoidCallback onHiring;
  final VoidCallback onDepartment;
  final VoidCallback onPerformance;
  final VoidCallback onBranch;
  final VoidCallback onReports;
  final VoidCallback onDocuments;
  final VoidCallback onAnalytics;
  final VoidCallback onLogout;

  const _MoreView({
    required this.onOrganization,
    required this.onSettings,
    required this.onBudget,
    required this.onNotifications,
    required this.onMeetings,
    required this.onLeave,
    required this.onHiring,
    required this.onDepartment,
    required this.onPerformance,
    required this.onBranch,
    required this.onReports,
    required this.onDocuments,
    required this.onAnalytics,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreGridItem(Icons.account_tree_rounded, 'Organization', onOrganization),
      _MoreGridItem(Icons.apartment_rounded, 'Departments', onDepartment),
      _MoreGridItem(
        Icons.insights_rounded,
        'Attendance\nIntelligence',
        onAnalytics,
      ),
      _MoreGridItem(Icons.beach_access_rounded, 'Leave\nIntelligence', onLeave),
      _MoreGridItem(Icons.payments_rounded, 'Payroll\nOverview', onBudget),
      _MoreGridItem(
        Icons.person_add_alt_1_rounded,
        'Hiring\nPipeline',
        onHiring,
      ),
      _MoreGridItem(Icons.work_rounded, 'Projects', onMeetings),
      _MoreGridItem(Icons.speed_rounded, 'Performance\nMatrix', onPerformance),
      _MoreGridItem(Icons.assessment_rounded, 'Reports', onReports),
      _MoreGridItem(Icons.folder_copy_rounded, 'Document\nCenter', onDocuments),
      _MoreGridItem(Icons.receipt_long_rounded, 'Audit Logs', onNotifications),
      _MoreGridItem(Icons.auto_awesome_rounded, 'AI Insights', onBranch),
      _MoreGridItem(Icons.settings_rounded, 'Settings', onSettings),
      _MoreGridItem(
        Icons.logout_rounded,
        'Logout',
        onLogout,
        color: Colors.deepOrangeAccent,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) => items[index],
        ),
      ],
    );
  }
}

class _CeoPayrollOverviewPage extends StatelessWidget {
  final String userId;

  const _CeoPayrollOverviewPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Payroll Overview',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          final salary = _mapList(data['approvals_summary']).firstWhere(
            (item) => _displayText(item['key']) == 'salary',
            orElse: () => <String, dynamic>{},
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _MetricGrid(
                cards: [
                  _MetricData(
                    'Payroll Cost',
                    _displayText(data['payroll_cost'], fallback: '₹0'),
                    'Current month',
                    Icons.payments_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _MetricData(
                    'Deductions',
                    _displayText(data['expenses'], fallback: '₹0'),
                    'Current month',
                    Icons.trending_down_rounded,
                    _CeoDashboardState._gold,
                  ),
                  _MetricData(
                    'Pending',
                    _displayText(salary['count'], fallback: '0'),
                    'Approvals',
                    Icons.pending_actions_rounded,
                    _CeoDashboardState._purple,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CeoFlowListTile(
                icon: Icons.approval_rounded,
                title: 'Payroll Approvals',
                subtitle: 'Review salary revisions awaiting CEO approval',
                color: _CeoDashboardState._gold,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CeoApprovalCategoryScreen(
                      category: 'salary',
                      title: 'Payroll Approvals',
                      userId: userId,
                    ),
                  ),
                ),
              ),
              _CeoFlowListTile(
                icon: Icons.assessment_rounded,
                title: 'Payroll Reports',
                subtitle: 'Open payroll cost and monthly reporting',
                color: _CeoDashboardState._cyan,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ReportsView(userId: userId),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoProjectsPage extends StatefulWidget {
  final String userId;

  const _CeoProjectsPage({required this.userId});

  @override
  State<_CeoProjectsPage> createState() => _CeoProjectsPageState();
}

class _CeoProjectsPageState extends State<_CeoProjectsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Projects',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          final overview = _mapFromDynamic(data['project_overview']);
          final query = _search.text.trim().toLowerCase();
          final tasks = _mapList(data['project_items']).where((item) {
            if (query.isEmpty) return true;
            return [
              item['title'],
              item['project'],
              item['assignee'],
              item['status'],
              item['priority'],
            ].any((value) => _displayText(value).toLowerCase().contains(query));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _MetricGrid(
                cards: [
                  _MetricData(
                    'Active',
                    _displayText(overview['active'], fallback: '0'),
                    '',
                    Icons.work_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _MetricData(
                    'Completed',
                    _displayText(overview['completed'], fallback: '0'),
                    '',
                    Icons.task_alt_rounded,
                    _CeoDashboardState._green,
                  ),
                  _MetricData(
                    'At Risk',
                    _displayText(overview['at_risk'], fallback: '0'),
                    '',
                    Icons.warning_amber_rounded,
                    Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _EmployeeSearchBox(
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _GlassCard(
                  child: Text(
                    'No project tasks found',
                    style: _CeoText.mutedFor(context, 12),
                  ),
                )
              else
                ...tasks.map(
                  (task) => _CeoFlowListTile(
                    icon: Icons.account_tree_rounded,
                    title: _displayText(
                      task['title'],
                      fallback: 'Project Task',
                    ),
                    subtitle:
                        '${_displayText(task['project'], fallback: 'General')} · ${_displayText(task['status'], fallback: 'Pending')} · ${_displayText(task['assignee'], fallback: 'Unassigned')}',
                    color: _priorityColor(_displayText(task['priority'])),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CeoDataDetailPage(
                          title: 'Project Detail',
                          data: task,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoAuditLogsPage extends StatelessWidget {
  final String userId;

  const _CeoAuditLogsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Audit Logs',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchNotifications(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final logs = _mapList(snapshot.data!['notifications']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _GlassCard(
                child: Text(
                  'Backend activity timeline for approvals, member creation, leave, meetings, and system events.',
                  style: _CeoText.mutedFor(context, 11),
                ),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                _GlassCard(
                  child: Text(
                    'No audit activity found',
                    style: _CeoText.mutedFor(context, 12),
                  ),
                )
              else
                ...logs.map(
                  (log) => _CeoFlowListTile(
                    icon: _notificationIcon(_displayText(log['type'])),
                    title: _displayText(log['title'], fallback: 'Activity'),
                    subtitle:
                        '${_displayText(log['message'], fallback: _displayText(log['subtitle']))} · ${_displayText(log['time'], fallback: 'Recent')}',
                    color: _notificationColor(_displayText(log['type'])),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CeoDataDetailPage(
                          title: 'Audit Detail',
                          data: log,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoAiInsightsPage extends StatelessWidget {
  final String userId;

  const _CeoAiInsightsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'AI Insights',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          final health = _mapFromDynamic(data['attendance_health']);
          final departments = _mapList(data['employee_categories']);
          final attention =
              departments
                  .where((item) => _departmentPerformance(item) < 70)
                  .toList()
                ..sort(
                  (a, b) => _departmentPerformance(
                    a,
                  ).compareTo(_departmentPerformance(b)),
                );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Executive Summary'),
                    const SizedBox(height: 8),
                    Text(
                      'Attendance health is ${_displayText(health['score'], fallback: '0')}% (${_displayText(health['label'], fallback: 'No Data')}). ${attention.length} department(s) currently need attention.',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CeoFlowListTile(
                icon: Icons.monitor_heart_rounded,
                title: 'Attendance Health',
                subtitle:
                    '${_displayText(health['trend_label'], fallback: '+0%')} vs last month · ${_displayText(health['present_today'], fallback: '0')} present today',
                color: _CeoDashboardState._cyan,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _AnalyticsDynamicView(userId: userId),
                  ),
                ),
              ),
              ...attention.map(
                (department) => _CeoFlowListTile(
                  icon: Icons.warning_amber_rounded,
                  title:
                      '${_departmentDisplayName(department)} needs attention',
                  subtitle:
                      '${_departmentPerformance(department)}% attendance performance · ${_departmentCount(department)} employees',
                  color: _CeoDashboardState._gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _DepartmentDetailPage(department: department),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoPerformanceMatrixPage extends StatelessWidget {
  final String userId;

  const _CeoPerformanceMatrixPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Performance Matrix',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDepartmentPerformance(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          if (!snapshot.hasData) {
            return _CeoLoadError(
              message: 'Unable to load performance data.',
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => _CeoPerformanceMatrixPage(userId: userId),
                ),
              ),
            );
          }
          final departments = _mapList(
            snapshot.data!['departments'],
          ).where((item) => _departmentCount(item) > 0).toList();
          final employeeCount = departments.fold<int>(
            0,
            (total, item) => total + _departmentCount(item),
          );
          final average = departments.isEmpty
              ? 0
              : (departments.fold<int>(
                          0,
                          (total, item) => total + _departmentPerformance(item),
                        ) /
                        departments.length)
                    .round();
          final top = departments.isEmpty
              ? <String, dynamic>{}
              : (List<Map<String, dynamic>>.from(departments)..sort(
                      (a, b) => _departmentPerformance(
                        b,
                      ).compareTo(_departmentPerformance(a)),
                    ))
                    .first;
          final needsAttention = departments
              .where((item) => _departmentPerformance(item) < 70)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _MetricGrid(
                cards: [
                  _MetricData(
                    'Average Score',
                    '$average%',
                    '${departments.length} departments',
                    Icons.speed_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _MetricData(
                    'Employees',
                    '$employeeCount',
                    'Measured',
                    Icons.groups_rounded,
                    _CeoDashboardState._purple,
                  ),
                  _MetricData(
                    'Needs Attention',
                    '$needsAttention',
                    'Below 70%',
                    Icons.warning_amber_rounded,
                    _CeoDashboardState._gold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (top.isNotEmpty)
                _GlassCard(
                  child: Row(
                    children: [
                      const _IconSquare(
                        icon: Icons.emoji_events_rounded,
                        color: _CeoDashboardState._gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top Performing Department',
                              style: _CeoText.mutedFor(context, 10),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _departmentDisplayName(top),
                              style: _CeoText.titleFor(context, 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_departmentPerformance(top)}%',
                        style: const TextStyle(
                          color: _CeoDashboardState._green,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const _SectionTitle('Department Performance Matrix'),
              const SizedBox(height: 10),
              if (departments.isEmpty)
                _GlassCard(
                  child: Text(
                    'No employee performance records found',
                    style: _CeoText.mutedFor(context, 12),
                  ),
                ),
              ...departments.map(
                (department) => _AllDepartmentTile(
                  item: department,
                  showStrength: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _DepartmentDetailPage(department: department),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoSettingsDashboardPage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String email;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAudit;
  final VoidCallback onLogout;

  const _CeoSettingsDashboardPage({
    required this.userId,
    required this.firstName,
    required this.email,
    required this.onOpenProfile,
    required this.onOpenAudit,
    required this.onLogout,
  });

  @override
  State<_CeoSettingsDashboardPage> createState() =>
      _CeoSettingsDashboardPageState();
}

class _CeoSettingsDashboardPageState extends State<_CeoSettingsDashboardPage> {
  bool _approvalAlerts = true;
  bool _memberAlerts = true;

  void _saveSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConfig.getCardBg(context),
        title: const Text('Settings Saved'),
        content: const Text(
          'Your CEO dashboard preferences have been updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Settings',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _GlassCard(
                child: Row(
                  children: [
                    _InitialsAvatar(name: widget.firstName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.firstName.isEmpty
                                ? 'CEO Account'
                                : widget.firstName,
                            style: _CeoText.titleFor(context, 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.userId} · ${widget.email}',
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.mutedFor(context, 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onOpenProfile,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: _CeoDashboardState._muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Dashboard Configuration'),
              const SizedBox(height: 10),
              _GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _approvalAlerts,
                      activeThumbColor: _CeoDashboardState._cyan,
                      title: Text(
                        'Approval notifications',
                        style: _CeoText.titleFor(context, 12),
                      ),
                      subtitle: Text(
                        '${_displayText(data['pending_approvals'], fallback: '0')} currently pending',
                        style: _CeoText.mutedFor(context, 10),
                      ),
                      onChanged: (value) =>
                          setState(() => _approvalAlerts = value),
                    ),
                    Divider(color: ThemeConfig.getCardBorder(context)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _memberAlerts,
                      activeThumbColor: _CeoDashboardState._cyan,
                      title: Text(
                        'Member creation notifications',
                        style: _CeoText.titleFor(context, 12),
                      ),
                      subtitle: Text(
                        '${_displayText(data['total_employees'], fallback: '0')} employees in the backend',
                        style: _CeoText.mutedFor(context, 10),
                      ),
                      onChanged: (value) =>
                          setState(() => _memberAlerts = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CeoFlowListTile(
                icon: Icons.manage_accounts_rounded,
                title: 'Profile and Account',
                subtitle: 'Review CEO account information and security',
                color: _CeoDashboardState._cyan,
                onTap: widget.onOpenProfile,
              ),
              _CeoFlowListTile(
                icon: Icons.receipt_long_rounded,
                title: 'Audit and Notifications',
                subtitle: 'Review backend activity and notification history',
                color: _CeoDashboardState._purple,
                onTap: widget.onOpenAudit,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _CeoDashboardState._cyan,
                    foregroundColor: const Color(0xFF02101E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepOrangeAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CeoDataDetailPage extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _CeoDataDetailPage({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((entry) {
      final value = _displayText(entry.value);
      return value.isNotEmpty &&
          !value.startsWith('[') &&
          !value.startsWith('{');
    }).toList();
    return _CeoShell(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _GlassCard(
            child: Column(
              children: entries
                  .map(
                    (entry) => _InfoRow(
                      _fieldLabel(entry.key),
                      _displayText(entry.value, fallback: '-'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CeoFlowListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CeoFlowListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconSquare(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 13),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 10),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

String _fieldLabel(String value) {
  final words = value.replaceAll('_', ' ').trim().split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _PeopleFilterChips extends StatelessWidget {
  final int total;

  const _PeopleFilterChips({required this.total});

  @override
  Widget build(BuildContext context) {
    final chips = [
      ['All', '$total'],
      ['Leaders', '$total'],
      ['On Leave', '0'],
      ['New', '0'],
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? _CeoDashboardState._cyan.withAlpha(50)
                  : ThemeConfig.getCardBg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? _CeoDashboardState._cyan
                    : ThemeConfig.getCardBorder(context),
              ),
            ),
            child: Text(
              '${chips[index][0]}  ${chips[index][1]}',
              style: TextStyle(
                color: active
                    ? _CeoDashboardState._cyan
                    : ThemeConfig.getTextSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoreGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MoreGridItem(
    this.icon,
    this.label,
    this.onTap, {
    this.color = _CeoDashboardState._cyan,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(70)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.titleFor(context, 9.5),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailsDynamicPage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> report;

  const _ReportDetailsDynamicPage({required this.userId, required this.report});

  @override
  Widget build(BuildContext context) {
    final title = _displayText(report['title'], fallback: 'Report Details');
    return _CeoShell(
      title: title,
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchDashboard(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              const _PeriodSelector(),
              const SizedBox(height: 14),
              _MetricGrid(
                cards: [
                  _MetricData(
                    'Total Employees',
                    _displayText(data['total_employees'], fallback: '0'),
                    '',
                    Icons.groups_rounded,
                    _CeoDashboardState._cyan,
                  ),
                  _MetricData(
                    'Active Employees',
                    _displayText(data['active_employees'], fallback: '0'),
                    '',
                    Icons.verified_user_rounded,
                    _CeoDashboardState._green,
                  ),
                  _MetricData(
                    'Pending Leaves',
                    _displayText(data['pending_approvals'], fallback: '0'),
                    '',
                    Icons.beach_access_rounded,
                    _CeoDashboardState._pink,
                  ),
                  _MetricData(
                    'Attendance',
                    _displayText(data['attendance'], fallback: '0'),
                    '',
                    Icons.calendar_month_rounded,
                    _CeoDashboardState._gold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ChartCard(
                title: _displayText(report['chart_title'], fallback: title),
                subtitle: _displayText(report['subtitle']),
                trend: _displayText(report['trend']),
                bars: _chartBars(report['bars'] ?? data['revenue_bars']),
                color: _reportColor(_displayText(report['type'])),
              ),
              const SizedBox(height: 14),
              const _ExportButtons(),
            ],
          );
        },
      ),
    );
  }
}

class _DepartmentOverviewFlowPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _DepartmentOverviewFlowPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_DepartmentOverviewFlowPage> createState() =>
      _DepartmentOverviewFlowPageState();
}

class _DepartmentOverviewFlowPageState
    extends State<_DepartmentOverviewFlowPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = CeoService().fetchDepartmentPerformance(widget.userId);
  }

  Future<void> _openList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DepartmentListFlowPage(
          userId: widget.userId,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => _DepartmentFlowShell(
    onNavigate: widget.onNavigate,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _OrganizationFlowError(onRetry: () => setState(_reload));
        }
        final data = snapshot.data!;
        final departments = _mapList(data['departments']);
        final summary = _stringMap(data['summary']);
        final recent = _mapList(data['recent_departments']);
        final populated = departments
            .where((item) => _departmentCount(item) > 0)
            .toList();
        final totalEmployees =
            int.tryParse(
              _displayText(summary['total_employees'], fallback: '0'),
            ) ??
            0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            Text('Department Overview', style: _CeoText.titleFor(context, 18)),
            const SizedBox(height: 3),
            Text(
              'Summary of all departments',
              style: _CeoText.mutedFor(context, 10),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DepartmentOverviewMetric(
                    icon: Icons.apartment_rounded,
                    label: 'Total Departments',
                    value: _displayText(
                      summary['total_departments'],
                      fallback: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DepartmentOverviewMetric(
                    icon: Icons.groups_2_rounded,
                    label: 'Total Employees',
                    value: '$totalEmployees',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employees by Department',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 12),
                  if (populated.isEmpty)
                    Text(
                      'No employee distribution available',
                      style: _CeoText.mutedFor(context, 10),
                    )
                  else
                    _DepartmentDistributionChart(
                      departments: populated,
                      totalEmployees: totalEmployees,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Departments by Status',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DepartmentStatusMetric(
                          label: 'Active',
                          value: _displayText(
                            summary['active_departments'],
                            fallback: '0',
                          ),
                          color: _CeoDashboardState._green,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _DepartmentStatusMetric(
                          label: 'Inactive',
                          value: _displayText(
                            summary['inactive_departments'],
                            fallback: '0',
                          ),
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Departments',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    Text(
                      'No recently configured departments',
                      style: _CeoText.mutedFor(context, 10),
                    )
                  else
                    ...recent.map(
                      (department) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.apartment_rounded,
                          color: _CeoDashboardState._cyan,
                        ),
                        title: Text(
                          _departmentDisplayName(department),
                          style: _CeoText.titleFor(context, 11),
                        ),
                        subtitle: Text(
                          '${_departmentCount(department)} employees',
                          style: _CeoText.mutedFor(context, 9),
                        ),
                        trailing: _OrgBadge(
                          _displayText(
                            department['status'],
                            fallback: 'Active',
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _DepartmentDetailsFlowPage(
                              userId: widget.userId,
                              departmentKey: _displayText(
                                department['department'],
                              ),
                              onNavigate: widget.onNavigate,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Divider(color: _CeoDashboardState._border),
                  InkWell(
                    onTap: _openList,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View All Departments',
                            style: TextStyle(
                              color: _CeoDashboardState._cyan,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _CeoDashboardState._cyan,
                            size: 18,
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
      },
    ),
  );
}

class _DepartmentOverviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DepartmentOverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _CeoDashboardState._cyan.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _CeoDashboardState._cyan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _CeoText.mutedFor(context, 8.5)),
              Text(value, style: _CeoText.titleFor(context, 18)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DepartmentStatusMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DepartmentStatusMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withValues(alpha: .28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: _CeoText.mutedFor(context, 9)),
          ],
        ),
        const SizedBox(height: 5),
        Text(value, style: _CeoText.titleFor(context, 17)),
      ],
    ),
  );
}

class _DepartmentDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> departments;
  final int totalEmployees;

  const _DepartmentDistributionChart({
    required this.departments,
    required this.totalEmployees,
  });

  @override
  Widget build(BuildContext context) {
    final visible = departments.take(6).toList();
    final actualTotal = departments.fold<int>(
      0,
      (sum, department) => sum + _departmentCount(department),
    );
    final chartTotal = actualTotal > 0 ? actualTotal : totalEmployees;
    final visibleTotal = visible.fold<int>(
      0,
      (sum, department) => sum + _departmentCount(department),
    );
    final othersCount = math.max(0, chartTotal - visibleTotal);
    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(132),
                painter: _DepartmentDonutPainter(
                  departments: visible,
                  totalEmployees: chartTotal,
                  othersCount: othersCount,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$chartTotal', style: _CeoText.titleFor(context, 21)),
                  Text('Total', style: _CeoText.mutedFor(context, 8.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              ...visible.map((department) {
                final name = _departmentDisplayName(department);
                final count = _departmentCount(department);
                final percentage = chartTotal == 0
                    ? 0
                    : ((count / chartTotal) * 100).round();
                return _DepartmentDistributionLegendRow(
                  color: _departmentColors(name).$1,
                  label: name,
                  count: count,
                  percentage: percentage,
                );
              }),
              if (othersCount > 0)
                _DepartmentDistributionLegendRow(
                  color: _CeoDashboardState._muted,
                  label: 'Others',
                  count: othersCount,
                  percentage: chartTotal == 0
                      ? 0
                      : ((othersCount / chartTotal) * 100).round(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartmentDistributionLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int percentage;

  const _DepartmentDistributionLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 8.5),
          ),
        ),
        Text('$count ($percentage%)', style: _CeoText.titleFor(context, 8.5)),
      ],
    ),
  );
}

class _DepartmentDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> departments;
  final int totalEmployees;
  final int othersCount;

  const _DepartmentDonutPainter({
    required this.departments,
    required this.totalEmployees,
    required this.othersCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = totalEmployees;
    final rect = Offset.zero & size;
    final track = Paint()
      ..color = _CeoDashboardState._border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawArc(rect.deflate(15), 0, math.pi * 2, false, track);
    if (total == 0) return;
    var start = -math.pi / 2;
    final slices = [
      ...departments.map(
        (department) => (
          count: _departmentCount(department),
          color: _departmentColors(_departmentDisplayName(department)).$1,
        ),
      ),
      if (othersCount > 0)
        (count: othersCount, color: _CeoDashboardState._muted),
    ];
    for (final slice in slices) {
      final count = slice.count;
      if (count == 0) continue;
      final sweep = (count / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(15),
        start + .018,
        math.max(0, sweep - .036),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DepartmentDonutPainter oldDelegate) =>
      oldDelegate.departments != departments ||
      oldDelegate.totalEmployees != totalEmployees ||
      oldDelegate.othersCount != othersCount;
}

class _DepartmentListFlowPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _DepartmentListFlowPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_DepartmentListFlowPage> createState() =>
      _DepartmentListFlowPageState();
}

class _DepartmentListFlowPageState extends State<_DepartmentListFlowPage> {
  late Future<Map<String, dynamic>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = CeoService().fetchDepartmentPerformance(widget.userId);
  }

  Future<void> _openEditor([Map<String, dynamic>? department]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _DepartmentEditFlowPage(
          userId: widget.userId,
          department: department,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => _DepartmentFlowShell(
    onNavigate: widget.onNavigate,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _OrganizationFlowError(onRetry: () => setState(_reload));
        }
        final departments = _mapList(snapshot.data!['departments'])
            .where(
              (department) => _departmentDisplayName(
                department,
              ).toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department List',
                    style: _CeoText.titleFor(context, 18),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Manage and explore departments',
                    style: _CeoText.mutedFor(context, 10),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _OrganizationSearchField(
                          hint: 'Search departments...',
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _CeoDashboardState._card,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _CeoDashboardState._border),
                        ),
                        child: const Icon(
                          Icons.filter_alt_outlined,
                          color: _CeoDashboardState._muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openEditor,
                      style: FilledButton.styleFrom(
                        backgroundColor: _CeoDashboardState._cyan,
                        foregroundColor: const Color(0xFF001321),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add Department',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  final name = _departmentDisplayName(department);
                  final active =
                      _displayText(department['status'], fallback: 'Active') ==
                      'Active';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _GlassCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _DepartmentDetailsFlowPage(
                            userId: widget.userId,
                            departmentKey: _displayText(
                              department['department'],
                            ),
                            onNavigate: widget.onNavigate,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _departmentColors(
                              name,
                            ).$1.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            _departmentIcon(name),
                            color: _departmentColors(name).$1,
                          ),
                        ),
                        title: Text(
                          name,
                          style: _CeoText.titleFor(context, 11.5),
                        ),
                        subtitle: Text(
                          '${_departmentCount(department)} employees',
                          style: _CeoText.mutedFor(context, 9),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OrgBadge(active ? 'ACTIVE' : 'INACTIVE'),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _CeoDashboardState._muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DepartmentDetailsFlowPage extends StatefulWidget {
  final String userId;
  final String departmentKey;
  final ValueChanged<int> onNavigate;

  const _DepartmentDetailsFlowPage({
    required this.userId,
    required this.departmentKey,
    required this.onNavigate,
  });

  @override
  State<_DepartmentDetailsFlowPage> createState() =>
      _DepartmentDetailsFlowPageState();
}

class _DepartmentDetailsFlowPageState
    extends State<_DepartmentDetailsFlowPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = CeoService().fetchDepartmentPerformance(widget.userId);
  }

  Map<String, dynamic> _findDepartment(Map<String, dynamic> data) {
    return _mapList(data['departments']).firstWhere(
      (item) => _displayText(item['department']) == widget.departmentKey,
      orElse: () => <String, dynamic>{},
    );
  }

  Future<void> _edit(Map<String, dynamic> department) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _DepartmentEditFlowPage(
          userId: widget.userId,
          department: department,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => _DepartmentFlowShell(
    onNavigate: widget.onNavigate,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _OrganizationFlowError(onRetry: () => setState(_reload));
        }
        final data = snapshot.data!;
        final department = _findDepartment(data);
        if (department.isEmpty) {
          return const Center(child: Text('Department not found'));
        }
        final name = _departmentDisplayName(department);
        final employees = _mapList(department['employees']);
        final active =
            _displayText(department['status'], fallback: 'Active') == 'Active';
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            Text('Department Details', style: _CeoText.titleFor(context, 18)),
            const SizedBox(height: 12),
            _GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _departmentColors(name).$1.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _departmentIcon(name),
                      color: _departmentColors(name).$1,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _CeoText.titleFor(context, 16)),
                        const SizedBox(height: 3),
                        Text(
                          '${_displayText(department['code'])} Department',
                          style: _CeoText.mutedFor(context, 9),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: active
                                    ? _CeoDashboardState._green
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: active
                                    ? _CeoDashboardState._green
                                    : Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit department',
                    onPressed: () => _edit(department),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _CeoDashboardState._cyan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OrganizationStatRow(
              items: [
                ('Employees', '${employees.length}'),
                ('Teams', _displayText(department['teams'], fallback: '0')),
                (
                  'Locations',
                  _displayText(department['locations'], fallback: '0'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Department',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayText(department['description']),
                    style: _CeoText.mutedFor(context, 10),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: _CeoDashboardState._border),
                  _DepartmentInfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Department Head',
                    value: _displayText(
                      department['head_name'],
                      fallback: 'Not assigned',
                    ),
                  ),
                  _DepartmentInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _displayText(
                      department['email'],
                      fallback: 'Not configured',
                    ),
                  ),
                  _DepartmentInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _displayText(
                      department['phone'],
                      fallback: 'Not configured',
                    ),
                  ),
                  _DepartmentInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: _displayText(
                      department['location'],
                      fallback: 'Not configured',
                    ),
                  ),
                  _DepartmentInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Established',
                    value: _displayText(
                      department['established_date'],
                      fallback: 'Not configured',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Performance',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DepartmentStatusMetric(
                          label: 'Attendance',
                          value: '${_departmentPerformance(department)}%',
                          color: _CeoDashboardState._cyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DepartmentStatusMetric(
                          label: 'Workforce Share',
                          value: '${_departmentStrength(department)}%',
                          color: _CeoDashboardState._purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DepartmentStatusMetric(
                          label: 'Active Staff',
                          value:
                              '${employees.where((e) => _displayText(e['status']) == 'Active').length}',
                          color: _CeoDashboardState._green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _OrganizationNextButton(
              label: 'View Department Employees',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _DepartmentEmployeesFlowPage(
                    userId: widget.userId,
                    departmentKey: widget.departmentKey,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DepartmentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DepartmentInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: _CeoDashboardState._muted, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: _CeoText.mutedFor(context, 9))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: _CeoText.titleFor(context, 9),
          ),
        ),
      ],
    ),
  );
}

class _DepartmentEmployeesFlowPage extends StatefulWidget {
  final String userId;
  final String departmentKey;
  final ValueChanged<int> onNavigate;

  const _DepartmentEmployeesFlowPage({
    required this.userId,
    required this.departmentKey,
    required this.onNavigate,
  });

  @override
  State<_DepartmentEmployeesFlowPage> createState() =>
      _DepartmentEmployeesFlowPageState();
}

class _DepartmentEmployeesFlowPageState
    extends State<_DepartmentEmployeesFlowPage> {
  late Future<Map<String, dynamic>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = CeoService().fetchDepartmentPerformance(widget.userId);
  }

  Future<void> _openEmployeeActions(Map<String, dynamic> data) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _CeoDashboardState._card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Employee', style: _CeoText.titleFor(sheetContext, 17)),
              const SizedBox(height: 5),
              Text(
                'Choose how the employee should be added to this department.',
                style: _CeoText.mutedFor(sheetContext, 10),
              ),
              const SizedBox(height: 14),
              _DepartmentEmployeeActionTile(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Create New Team Member',
                subtitle: 'Open the complete CEO member creation flow',
                onTap: () => Navigator.of(sheetContext).pop('create'),
              ),
              const SizedBox(height: 10),
              _DepartmentEmployeeActionTile(
                icon: Icons.group_add_outlined,
                title: 'Assign Existing Employee',
                subtitle: 'Move an existing member into this department',
                onTap: () => Navigator.of(sheetContext).pop('assign'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'assign') {
      await _assignEmployee(data);
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CeoCreateAdminsPage(createdBy: widget.userId),
      ),
    );
    if (created == true && mounted) setState(_reload);
  }

  Future<void> _assignEmployee(Map<String, dynamic> data) async {
    final available = _mapList(data['available_employees'])
        .where(
          (employee) =>
              _displayText(employee['department']) != widget.departmentKey,
        )
        .toList();
    final employeeId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _CeoDashboardState._card,
        title: Text(
          'Assign Existing Employee',
          style: _CeoText.titleFor(context, 15),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: math
              .max(150, math.min(420, available.length * 62))
              .toDouble(),
          child: available.isEmpty
              ? Center(
                  child: Text(
                    'No employees available',
                    style: _CeoText.mutedFor(context, 10),
                  ),
                )
              : ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final employee = available[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: _CeoDashboardState._cyan,
                      ),
                      title: Text(
                        _displayText(employee['name'], fallback: 'Employee'),
                        style: _CeoText.titleFor(context, 10.5),
                      ),
                      subtitle: Text(
                        '${_displayText(employee['id'])} • ${_displayText(employee['department'])}',
                        style: _CeoText.mutedFor(context, 8.5),
                      ),
                      onTap: () => Navigator.of(
                        dialogContext,
                      ).pop(_displayText(employee['id'])),
                    );
                  },
                ),
        ),
      ),
    );
    if (employeeId == null || !mounted) return;
    final result = await CeoService().saveDepartment(
      widget.userId,
      'assign_employee',
      {'employee_id': employeeId, 'department_key': widget.departmentKey},
    );
    if (!mounted) return;
    _showOrganizationResult(context, result);
    if (result['success'] == true) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => _DepartmentFlowShell(
    onNavigate: widget.onNavigate,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return _OrganizationFlowError(onRetry: () => setState(_reload));
        }
        final data = snapshot.data!;
        final department = _mapList(data['departments']).firstWhere(
          (item) => _displayText(item['department']) == widget.departmentKey,
          orElse: () => <String, dynamic>{},
        );
        final name = _departmentDisplayName(department);
        final allEmployees = _mapList(department['employees']);
        final employees = allEmployees.where((employee) {
          final value =
              '${employee['name']} ${employee['id']} ${employee['designation']}'
                  .toLowerCase();
          return value.contains(_query.toLowerCase());
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employees', style: _CeoText.titleFor(context, 18)),
                  const SizedBox(height: 3),
                  Text(name, style: _CeoText.mutedFor(context, 10)),
                  const SizedBox(height: 10),
                  _OrganizationStatRow(
                    items: [
                      ('Total Employees', '${allEmployees.length}'),
                      (
                        'Teams',
                        _displayText(department['teams'], fallback: '0'),
                      ),
                      (
                        'Locations',
                        _displayText(department['locations'], fallback: '0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _OrganizationSearchField(
                    hint: 'Search employees...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Text(
                        'No employees in this department',
                        style: _CeoText.mutedFor(context, 11),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final attendance = _displayText(
                          employee['attendance_status'],
                          fallback: 'Not Marked',
                        );
                        final present = [
                          'Present',
                          'WFH',
                          'Hybrid',
                          'Work From Home',
                        ].contains(attendance);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _GlassCard(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _EmployeeProfilePage(
                                  employee: _employeeFromMap(employee),
                                ),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: _CeoDashboardState._cyan
                                    .withValues(alpha: .12),
                                child: Text(
                                  _initials(_displayText(employee['name'])),
                                  style: const TextStyle(
                                    color: _CeoDashboardState._cyan,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              title: Text(
                                _displayText(employee['name']),
                                style: _CeoText.titleFor(context, 11),
                              ),
                              subtitle: Text(
                                _displayText(employee['designation']),
                                style: _CeoText.mutedFor(context, 8.5),
                              ),
                              trailing: Text(
                                attendance,
                                style: TextStyle(
                                  color: present
                                      ? _CeoDashboardState._green
                                      : attendance == 'On Leave'
                                      ? _CeoDashboardState._gold
                                      : _CeoDashboardState._muted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openEmployeeActions(data),
                  style: FilledButton.styleFrom(
                    backgroundColor: _CeoDashboardState._cyan,
                    foregroundColor: const Color(0xFF001321),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text(
                    'Add Employee',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DepartmentEmployeeActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DepartmentEmployeeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CeoDashboardState._cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _CeoDashboardState._border),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _CeoDashboardState._cyan.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _CeoDashboardState._cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _CeoText.titleFor(context, 11.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: _CeoText.mutedFor(context, 9)),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    ),
  );
}

class _DepartmentEditFlowPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? department;
  final ValueChanged<int> onNavigate;

  const _DepartmentEditFlowPage({
    required this.userId,
    required this.department,
    required this.onNavigate,
  });

  @override
  State<_DepartmentEditFlowPage> createState() =>
      _DepartmentEditFlowPageState();
}

class _DepartmentEditFlowPageState extends State<_DepartmentEditFlowPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final department = widget.department ?? const <String, dynamic>{};
    final departmentName = _displayText(department['name']);
    _active =
        _displayText(department['status'], fallback: 'Active') == 'Active';
    _controllers = {
      'name': TextEditingController(text: departmentName),
      'code': TextEditingController(
        text: _generateDepartmentCode(departmentName),
      ),
      'description': TextEditingController(
        text: _displayText(department['description']),
      ),
      'head_user_id': TextEditingController(
        text: _displayText(department['head_user_id']),
      ),
      'email': TextEditingController(text: _displayText(department['email'])),
      'phone': TextEditingController(
        text: _displayText(department['phone_edit_value']),
      ),
      'location': TextEditingController(
        text: _displayText(department['location']),
      ),
      'established_date': TextEditingController(
        text: _displayText(department['established_date']),
      ),
    };
    _controllers['name']!.addListener(_syncDepartmentCode);
  }

  String _generateDepartmentCode(String name) {
    final withoutParentheses = name.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    final words = RegExp(
      r'[A-Za-z0-9]+',
    ).allMatches(withoutParentheses).map((match) => match.group(0)!).toList();
    const ignored = {'and', 'of', 'the', 'for'};
    final meaningful = words
        .where((word) => !ignored.contains(word.toLowerCase()))
        .toList();
    final parts = meaningful.isEmpty ? words : meaningful;
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts.first.toUpperCase();
      return word.substring(0, math.min(3, word.length));
    }
    return parts.map((word) => word[0].toUpperCase()).join();
  }

  void _syncDepartmentCode() {
    final generated = _generateDepartmentCode(_controllers['name']!.text);
    final controller = _controllers['code']!;
    if (controller.text == generated) return;
    controller.value = TextEditingValue(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
    );
  }

  @override
  void dispose() {
    _controllers['name']!.removeListener(_syncDepartmentCode);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final result = await CeoService()
        .saveDepartment(widget.userId, 'save_department', {
          'department_key': _displayText(widget.department?['department']),
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
          'status': _active ? 'active' : 'inactive',
        });
    if (!mounted) return;
    setState(() => _saving = false);
    _showOrganizationResult(context, result);
    if (result['success'] == true) Navigator.of(context).pop(true);
  }

  Widget _field(
    String keyName,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[keyName],
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: _CeoText.titleFor(context, 11),
        validator: (value) {
          final clean = value?.trim() ?? '';
          if (required && clean.isEmpty) return '$label is required';
          if (keyboardType == TextInputType.emailAddress &&
              clean.isNotEmpty &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean)) {
            return 'Enter a valid email';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          suffixIcon: readOnly
              ? const Icon(
                  Icons.lock_outline_rounded,
                  color: _CeoDashboardState._muted,
                  size: 18,
                )
              : null,
          helperText: readOnly
              ? 'Automatically generated from department name'
              : null,
          helperStyle: _CeoText.mutedFor(context, 8),
          labelStyle: _CeoText.mutedFor(context, 10),
          hintStyle: _CeoText.mutedFor(context, 9),
          filled: true,
          fillColor: _CeoDashboardState._cardAlt,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _CeoDashboardState._border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _CeoDashboardState._cyan),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _DepartmentFlowShell(
    headerTitle: widget.department == null
        ? 'Add/Edit Department'
        : 'Add/Edit Department',
    onNavigate: widget.onNavigate,
    trailing: TextButton(
      onPressed: _saving ? null : _save,
      child: const Text(
        'Save',
        style: TextStyle(
          color: _CeoDashboardState._cyan,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _field('name', 'Department Name', required: true),
          _field('code', 'Department Code', readOnly: true),
          _field('description', 'Description', maxLines: 4),
          _field(
            'head_user_id',
            'Department Head ID',
            hint: 'Example: BBTL0001',
          ),
          _GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: _CeoText.titleFor(context, 11)),
                      Text(
                        _active ? 'Active department' : 'Inactive department',
                        style: _CeoText.mutedFor(context, 8.5),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _active,
                  activeThumbColor: _CeoDashboardState._cyan,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          _field(
            'email',
            'Department Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _field(
            'phone',
            'Department Phone',
            keyboardType: TextInputType.phone,
          ),
          _field('location', 'Location'),
          _field(
            'established_date',
            'Established Date',
            hint: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _CeoDashboardState._cyan,
                    foregroundColor: const Color(0xFF001321),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Department',
                          style: TextStyle(fontWeight: FontWeight.w900),
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

enum _DepartmentFilter { all, topPerforming, largestTeam, needsAttention }

class _DepartmentPerformanceDynamicPage extends StatefulWidget {
  final String userId;

  const _DepartmentPerformanceDynamicPage({required this.userId});

  @override
  State<_DepartmentPerformanceDynamicPage> createState() =>
      _DepartmentPerformanceDynamicPageState();
}

class _DepartmentPerformanceDynamicPageState
    extends State<_DepartmentPerformanceDynamicPage> {
  final _searchController = TextEditingController();
  late final Future<Map<String, dynamic>> _future;
  _DepartmentFilter _filter = _DepartmentFilter.all;

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchDepartmentPerformance(widget.userId);
    _searchController.addListener(_refreshSearch);
  }

  void _refreshSearch() => setState(() {});

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _selectFilter(_DepartmentFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
  }

  List<Map<String, dynamic>> _filteredDepartments(
    List<Map<String, dynamic>> departments,
  ) {
    var filtered = departments
        .where((item) => _departmentCount(item) > 0)
        .toList();
    switch (_filter) {
      case _DepartmentFilter.topPerforming:
        filtered =
            filtered
                .where((item) => _departmentPerformance(item) >= 80)
                .toList()
              ..sort(
                (a, b) => _departmentPerformance(
                  b,
                ).compareTo(_departmentPerformance(a)),
              );
        break;
      case _DepartmentFilter.largestTeam:
        filtered.sort(
          (a, b) => _departmentStrength(b).compareTo(_departmentStrength(a)),
        );
        break;
      case _DepartmentFilter.needsAttention:
        filtered =
            filtered.where((item) => _departmentPerformance(item) < 70).toList()
              ..sort(
                (a, b) => _departmentPerformance(
                  a,
                ).compareTo(_departmentPerformance(b)),
              );
        break;
      case _DepartmentFilter.all:
        filtered.sort((a, b) {
          final countResult = _departmentCount(
            b,
          ).compareTo(_departmentCount(a));
          return countResult != 0
              ? countResult
              : _departmentDisplayName(a).compareTo(_departmentDisplayName(b));
        });
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered.where((item) {
      if (_departmentDisplayName(item).toLowerCase().contains(query)) {
        return true;
      }
      return _mapList(item['employees']).any(
        (employee) =>
            _displayText(employee['name']).toLowerCase().contains(query) ||
            _displayText(employee['id']).toLowerCase().contains(query),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'All Departments',
      trailing: PopupMenuButton<_DepartmentFilter>(
        tooltip: 'Filter departments',
        initialValue: _filter,
        onSelected: _selectFilter,
        icon: const Icon(Icons.tune_rounded, color: _CeoDashboardState._cyan),
        itemBuilder: (_) => _DepartmentFilter.values
            .map(
              (filter) => PopupMenuItem(
                value: filter,
                child: Text(_departmentFilterLabel(filter)),
              ),
            )
            .toList(),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          if (snapshot.hasError || snapshot.data?['success'] != true) {
            return Center(
              child: Text(
                'Unable to load department data',
                style: _CeoText.mutedFor(context, 12),
              ),
            );
          }
          final departments = _mapList(snapshot.data!['departments']);
          final activeDepartments = departments
              .where((item) => _departmentCount(item) > 0)
              .toList();
          final visibleDepartments = _filteredDepartments(departments);
          final totalEmployees = activeDepartments.fold<int>(
            0,
            (total, item) => total + _departmentCount(item),
          );
          final averagePerformance = activeDepartments.isEmpty
              ? 0
              : (activeDepartments.fold<int>(
                          0,
                          (total, item) => total + _departmentPerformance(item),
                        ) /
                        activeDepartments.length)
                    .round();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: ThemeConfig.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search departments or employees',
                        hintStyle: _CeoText.mutedFor(context, 12),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _CeoDashboardState._muted,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _CeoDashboardState._muted,
                                ),
                              ),
                        filled: true,
                        fillColor: ThemeConfig.getCardBg(context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: ThemeConfig.getCardBorder(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _CeoDashboardState._cyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DepartmentSummaryCard(
                      departments: activeDepartments.length,
                      employees: totalEmployees,
                      averagePerformance: averagePerformance,
                    ),
                    const SizedBox(height: 14),
                    _DepartmentFilterTabs(
                      selected: _filter,
                      onSelected: _selectFilter,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleDepartments.isEmpty
                    ? Center(
                        child: Text(
                          _departmentEmptyText(_filter),
                          textAlign: TextAlign.center,
                          style: _CeoText.mutedFor(context, 12),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        itemCount: visibleDepartments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final department = visibleDepartments[index];
                          return _AllDepartmentTile(
                            item: department,
                            showStrength:
                                _filter == _DepartmentFilter.largestTeam,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _DepartmentDetailPage(
                                  department: department,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DepartmentSummaryCard extends StatelessWidget {
  final int departments;
  final int employees;
  final int averagePerformance;

  const _DepartmentSummaryCard({
    required this.departments,
    required this.employees,
    required this.averagePerformance,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: _DepartmentSummaryValue(
              value: '$departments',
              label: 'Departments',
              color: _CeoDashboardState._cyan,
            ),
          ),
          const SizedBox(
            height: 52,
            child: VerticalDivider(color: _CeoDashboardState._border),
          ),
          Expanded(
            child: _DepartmentSummaryValue(
              value: '$employees',
              label: 'Employees',
              color: _CeoDashboardState._purple,
            ),
          ),
          const SizedBox(
            height: 52,
            child: VerticalDivider(color: _CeoDashboardState._border),
          ),
          Expanded(
            child: _DepartmentSummaryValue(
              value: '$averagePerformance%',
              label: 'Avg. Performance',
              color: _CeoDashboardState._pink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentSummaryValue extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _DepartmentSummaryValue({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: _CeoText.mutedFor(context, 10),
        ),
      ],
    );
  }
}

class _DepartmentFilterTabs extends StatelessWidget {
  final _DepartmentFilter selected;
  final ValueChanged<_DepartmentFilter> onSelected;

  const _DepartmentFilterTabs({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DepartmentFilter.values.map((filter) {
          final active = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF00C6FF),
                            Color(0xFF0072FF),
                          ],
                        )
                      : null,
                  color: active ? null : ThemeConfig.getCardBg(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : ThemeConfig.getCardBorder(context),
                  ),
                ),
                child: Text(
                  _departmentFilterLabel(filter),
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : ThemeConfig.getTextSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AllDepartmentTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showStrength;
  final VoidCallback onTap;

  const _AllDepartmentTile({
    required this.item,
    required this.showStrength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = _departmentDisplayName(item);
    final colors = _departmentColors(name);
    final performance = _departmentPerformance(item);
    final strength = _departmentStrength(item);
    final metric = showStrength ? strength : performance;
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.$1.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.$1.withValues(alpha: 0.55)),
            ),
            child: Icon(_departmentIcon(name), color: colors.$1, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _CeoText.titleFor(context, 13),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$metric%',
                          style: TextStyle(
                            color: colors.$1,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          showStrength ? 'Team Strength' : 'Performance',
                          style: _CeoText.mutedFor(context, 8),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_departmentCount(item)} Employees',
                  style: _CeoText.mutedFor(context, 11),
                ),
                const SizedBox(height: 8),
                _DepartmentProgressBar(value: metric / 100, colors: colors),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

class _DepartmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> department;

  const _DepartmentDetailPage({required this.department});

  @override
  Widget build(BuildContext context) {
    final name = _departmentDisplayName(department);
    final colors = _departmentColors(name);
    final performance = _departmentPerformance(department);
    final strength = _departmentStrength(department);
    final employees = _mapList(department['employees']);
    return _CeoShell(
      title: name,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _GlassCard(
            child: Column(
              children: [
                Icon(_departmentIcon(name), color: colors.$1, size: 44),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: _CeoText.titleFor(context, 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${employees.length} Employees · $performance% Performance · $strength% Strength',
                  style: _CeoText.mutedFor(context, 12),
                ),
                const SizedBox(height: 12),
                _DepartmentProgressBar(
                  value: performance / 100,
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const _SectionTitle('Department Employees'),
          const SizedBox(height: 10),
          if (employees.isEmpty)
            _GlassCard(
              child: Center(
                child: Text(
                  'No employees in this department',
                  style: _CeoText.mutedFor(context, 12),
                ),
              ),
            ),
          ...employees.map(
            (employee) => _GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.$1.withValues(alpha: 0.14),
                    child: Icon(Icons.person_rounded, color: colors.$1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayText(employee['name'], fallback: 'Employee'),
                          style: _CeoText.titleFor(context, 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_displayText(employee['id'])} · ${_displayText(employee['designation'], fallback: 'Employee')}',
                          style: _CeoText.mutedFor(context, 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _displayText(employee['status'], fallback: '-'),
                    style: TextStyle(
                      color:
                          _displayText(employee['status']).toLowerCase() ==
                              'active'
                          ? _CeoDashboardState._green
                          : _CeoDashboardState._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchPerformanceDynamicPage extends StatelessWidget {
  final String userId;

  const _BranchPerformanceDynamicPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Branch Performance',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchBranchPerformance(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final items = snapshot.data!['branches'] is List
              ? snapshot.data!['branches'] as List
              : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              const _PeriodSelector(),
              const SizedBox(height: 14),
              if (items.isEmpty)
                _GlassCard(
                  child: Center(
                    child: Text(
                      'No branch data found',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ...items.map((item) {
                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                return _BranchTile(
                  _displayText(map['name'], fallback: 'Branch'),
                  _displayText(map['score'], fallback: '0 Employees'),
                  _displayText(map['trend'], fallback: '+0%'),
                  _displayText(map['revenue'], fallback: '0'),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _OrganizationDynamicPage extends StatelessWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _OrganizationDynamicPage({
    required this.userId,
    required this.onNavigate,
  });

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Organization Overview',
      titleFontSize: 14,
      showBack: false,
      drawer: _OrganizationMenuDrawer(onNavigate: onNavigate),
      trailing: const Icon(
        Icons.notifications_none_rounded,
        color: _CeoDashboardState._cyan,
      ),
      bottomNavigationBar: _BottomNavBar(
        items: _ceoViewAllNavItems,
        selectedIndex: 3,
        onChanged: (index) {
          Navigator.of(context).pop();
          onNavigate(index);
        },
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchOrganization(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _CeoLoadError(
              message: 'Unable to load organization data.',
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => _OrganizationDynamicPage(
                    userId: userId,
                    onNavigate: onNavigate,
                  ),
                ),
              ),
            );
          }
          final organization = snapshot.data!;
          final distribution = _mapList(organization['employee_distribution']);
          final businessUnits = _mapList(organization['business_units']);
          final leaders = _mapList(organization['leaders']);
          final changes = _mapList(organization['recent_changes']);
          final score =
              int.tryParse(_displayText(organization['health_score'])) ?? 0;
          final totalEmployees = _displayText(
            organization['total_employees'],
            fallback: '0',
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            children: [
              _OrganizationMetricGrid(
                metrics: [
                  _OrganizationMetric(
                    'Total Branches',
                    _displayText(organization['total_branches'], fallback: '0'),
                    Icons.apartment_rounded,
                    _CeoDashboardState._cyan,
                    () => _open(
                      context,
                      _OrganizationBranchesPage(
                        userId: userId,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ),
                  _OrganizationMetric(
                    'Business Units',
                    _displayText(
                      organization['business_unit_count'],
                      fallback: '0',
                    ),
                    Icons.view_in_ar_rounded,
                    _CeoDashboardState._purple,
                    () => _open(
                      context,
                      _CompanyStructurePage(
                        userId: userId,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ),
                  _OrganizationMetric(
                    'Departments',
                    _displayText(
                      organization['department_count'],
                      fallback: '0',
                    ),
                    Icons.account_tree_rounded,
                    _CeoDashboardState._cyan,
                    () => _open(
                      context,
                      _CompanyStructurePage(
                        userId: userId,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ),
                  _OrganizationMetric(
                    'Total Employees',
                    totalEmployees,
                    Icons.groups_rounded,
                    _CeoDashboardState._green,
                    () => _open(
                      context,
                      _EmployeeDirectoryDynamicPage(userId: userId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _OrganizationHealthCard(
                        score: score,
                        label: _displayText(
                          organization['health_label'],
                          fallback: 'No Data',
                        ),
                        description: _displayText(
                          organization['health_description'],
                          fallback: 'No attendance health data available',
                        ),
                        onTap: () => _open(
                          context,
                          _AnalyticsDynamicView(userId: userId),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      flex: 6,
                      child: _EmployeeDistributionCard(
                        items: distribution,
                        totalEmployees: int.tryParse(totalEmployees) ?? 0,
                        onTap: () => _open(
                          context,
                          _BranchPerformanceDynamicPage(userId: userId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _BusinessUnitsCard(
                items: businessUnits,
                onViewAll: () => _open(
                  context,
                  _OrganizationCollectionPage(
                    title: 'Business Units',
                    items: businessUnits,
                    icon: Icons.view_in_ar_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OrganizationStructureCard(
                        businessUnits: businessUnits,
                        departments:
                            int.tryParse(
                              _displayText(organization['department_count']),
                            ) ??
                            0,
                        onTap: () => _open(
                          context,
                          _CompanyStructurePage(
                            userId: userId,
                            onNavigate: onNavigate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _LeadershipOverviewCard(
                        leaders: leaders,
                        onPersonTap: (leader) => _open(
                          context,
                          _EmployeeProfilePage(
                            employee: _employeeFromMap(leader),
                          ),
                        ),
                        onViewAll: () => _open(
                          context,
                          _CeoLeadershipRolesPage(
                            userId: userId,
                            onAssignRole: () => _open(
                              context,
                              CeoCreateAdminsPage(createdBy: userId),
                            ),
                            onNavigate: onNavigate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OrganizationChangesCard(
                items: changes,
                onViewAll: () => _open(
                  context,
                  _OrganizationCollectionPage(
                    title: 'Organization Changes',
                    items: changes,
                    icon: Icons.history_rounded,
                  ),
                ),
                onTap: (change) => _open(
                  context,
                  _CeoDataDetailPage(
                    title: _displayText(
                      change['title'],
                      fallback: 'Organization Change',
                    ),
                    data: change,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _OrganizationQuickActions(
                onCompany: () => _open(
                  context,
                  _OrganizationDetailsPage(
                    userId: userId,
                    onNavigate: onNavigate,
                  ),
                ),
                onBranches: () => _open(
                  context,
                  _OrganizationBranchesPage(
                    userId: userId,
                    onNavigate: onNavigate,
                  ),
                ),
                onUnits: () => _open(
                  context,
                  _CompanyStructurePage(userId: userId, onNavigate: onNavigate),
                ),
                onChart: () => _open(
                  context,
                  _RolesHierarchyPage(userId: userId, onNavigate: onNavigate),
                ),
              ),
              const SizedBox(height: 14),
              _OrganizationNextButton(
                label: 'Company Structure',
                onTap: () => _open(
                  context,
                  _CompanyStructurePage(userId: userId, onNavigate: onNavigate),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DepartmentFlowShell extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final Widget child;
  final String? headerTitle;
  final Widget? trailing;

  const _DepartmentFlowShell({
    required this.onNavigate,
    required this.child,
    this.headerTitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bgStart = ThemeConfig.getBgStart(context);
    final bgEnd = ThemeConfig.getBgEnd(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    return Scaffold(
      backgroundColor: bgStart,
      bottomNavigationBar: _BottomNavBar(
        items: _ceoViewAllNavItems,
        selectedIndex: 3,
        onChanged: (index) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          onNavigate(index);
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart, bgEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textPrimary,
                            size: 19,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Expanded(
                        child: headerTitle == null
                            ? const Center(child: BitByteLogo(compact: true))
                            : Text(
                                headerTitle!,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child:
                              trailing ??
                              IconButton(
                                tooltip: 'Menu',
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: cardBg,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  builder: (sheetContext) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.apartment_rounded,
                                          color: _CeoDashboardState._cyan,
                                        ),
                                        title: Text(
                                          'Departments',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Live organization department data',
                                          style: TextStyle(
                                            color: textSecondary,
                                          ),
                                        ),
                                        onTap: () =>
                                            Navigator.of(sheetContext).pop(),
                                      ),
                                    ),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: textPrimary,
                                  size: 24,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationFlowShell extends StatelessWidget {
  final String title;
  final ValueChanged<int> onNavigate;
  final Widget child;
  final Widget? trailing;

  const _OrganizationFlowShell({
    required this.title,
    required this.onNavigate,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => _CeoShell(
    title: title,
    trailing: trailing,
    bottomNavigationBar: _BottomNavBar(
      items: _ceoViewAllNavItems,
      selectedIndex: 3,
      onChanged: (index) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        onNavigate(index);
      },
    ),
    child: child,
  );
}

class _OrganizationFlowError extends StatelessWidget {
  final VoidCallback onRetry;
  const _OrganizationFlowError({required this.onRetry});

  @override
  Widget build(BuildContext context) => _CeoLoadError(
    message: 'Unable to load organization data.',
    onRetry: onRetry,
  );
}

class _CompanyStructurePage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _CompanyStructurePage({required this.userId, required this.onNavigate});

  @override
  State<_CompanyStructurePage> createState() => _CompanyStructurePageState();
}

class _CompanyStructurePageState extends State<_CompanyStructurePage> {
  late Future<Map<String, dynamic>> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchOrganization(widget.userId);
  }

  void _retry() => setState(() {
    _future = CeoService().fetchOrganization(widget.userId);
  });

  @override
  Widget build(BuildContext context) => _OrganizationFlowShell(
    title: 'Company Structure',
    onNavigate: widget.onNavigate,
    trailing: const Icon(
      Icons.filter_alt_outlined,
      color: _CeoDashboardState._cyan,
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _OrganizationFlowError(onRetry: _retry);
        }
        final data = snapshot.data!;
        final company = _stringMap(data['company']);
        final units = _mapList(data['business_units']);
        final departments = _mapList(data['departments']);
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            _OrganizationSegmentedTabs(
              labels: const ['Structure View', 'List View'],
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 14),
            if (_tab == 0) ...[
              _OrganizationTreeNode(
                icon: Icons.apartment_rounded,
                title: _displayText(company['name'], fallback: 'Organization'),
                subtitle: 'Head Office',
                color: _CeoDashboardState._cyan,
              ),
              const _OrgConnector(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: units
                    .map(
                      (unit) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 44) / 3,
                        child: _OrganizationTreeNode(
                          icon: Icons.account_tree_rounded,
                          title: _displayText(
                            unit['name'],
                            fallback: 'Business Unit',
                          ),
                          subtitle:
                              '${_displayText(unit['count'], fallback: '0')} members',
                          color: _CeoDashboardState._purple,
                          compact: true,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const _OrgConnector(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: departments
                    .map(
                      (department) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 38) / 2,
                        child: _OrganizationTreeNode(
                          icon: Icons.groups_2_outlined,
                          title: _displayText(
                            department['name'],
                            fallback: 'Department',
                          ),
                          subtitle:
                              '${_displayText(department['count'], fallback: '0')} employees',
                          color: _CeoDashboardState._cyan,
                          compact: true,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              ...units.map((unit) {
                final name = _displayText(
                  unit['name'],
                  fallback: 'Business Unit',
                );
                final children = departments
                    .where(
                      (department) =>
                          _displayText(department['business_unit']) == name,
                    )
                    .toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GlassCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      iconColor: _CeoDashboardState._cyan,
                      collapsedIconColor: _CeoDashboardState._muted,
                      leading: const Icon(
                        Icons.view_in_ar_rounded,
                        color: _CeoDashboardState._cyan,
                      ),
                      title: Text(name, style: _CeoText.titleFor(context, 13)),
                      subtitle: Text(
                        '${_displayText(unit['count'], fallback: '0')} employees',
                        style: _CeoText.mutedFor(context, 10),
                      ),
                      children: children
                          .map(
                            (department) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                color: _CeoDashboardState._purple,
                              ),
                              title: Text(
                                _displayText(department['name']),
                                style: _CeoText.titleFor(context, 11),
                              ),
                              trailing: Text(
                                _displayText(
                                  department['count'],
                                  fallback: '0',
                                ),
                                style: _CeoText.mutedFor(context, 10),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 14),
            _OrganizationNextButton(
              label: 'Branches & Locations',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _OrganizationBranchesPage(
                    userId: widget.userId,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _OrganizationBranchesPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _OrganizationBranchesPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_OrganizationBranchesPage> createState() =>
      _OrganizationBranchesPageState();
}

class _OrganizationBranchesPageState extends State<_OrganizationBranchesPage> {
  late Future<Map<String, dynamic>> _future;
  String _query = '';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchOrganization(widget.userId);
  }

  void _retry() =>
      setState(() => _future = CeoService().fetchOrganization(widget.userId));

  Future<void> _addBranch() async {
    final values = await _showOrganizationFormDialog(
      context,
      title: 'Add Branch',
      submitLabel: 'Add Branch',
      fields: const [
        _OrganizationFormFieldSpec('name', 'Branch Name', required: true),
        _OrganizationFormFieldSpec('city', 'City', required: true),
        _OrganizationFormFieldSpec('state', 'State'),
        _OrganizationFormFieldSpec('country', 'Country'),
        _OrganizationFormFieldSpec('address', 'Complete Address', maxLines: 3),
      ],
    );
    if (values == null || !mounted) return;
    final result = await CeoService().saveOrganization(
      widget.userId,
      'add_branch',
      values,
    );
    if (!mounted) return;
    _showOrganizationResult(context, result);
    if (result['success'] == true) _retry();
  }

  @override
  Widget build(BuildContext context) => _OrganizationFlowShell(
    title: 'Branches & Locations',
    onNavigate: widget.onNavigate,
    trailing: IconButton(
      tooltip: 'Add branch',
      onPressed: _addBranch,
      icon: const Icon(Icons.add_rounded, color: _CeoDashboardState._cyan),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || !snapshot.hasData)
          return _OrganizationFlowError(onRetry: _retry);
        final branches = _mapList(snapshot.data!['branches']);
        final filtered = branches.where((branch) {
          final value =
              '${branch['name']} ${branch['city']} ${branch['country']}'
                  .toLowerCase();
          return value.contains(_query.toLowerCase());
        }).toList();
        final countries = branches
            .map((e) => _displayText(e['country']))
            .where((e) => e.isNotEmpty)
            .toSet()
            .length;
        final cities = branches
            .map((e) => _displayText(e['city']))
            .where((e) => e.isNotEmpty)
            .toSet()
            .length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            _OrganizationSearchField(
              hint: 'Search branches or locations',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            _OrganizationStatRow(
              items: [
                ('Total Branches', '${branches.length}'),
                ('Countries', '$countries'),
                ('Cities', '$cities'),
              ],
            ),
            const SizedBox(height: 12),
            _OrganizationSegmentedTabs(
              labels: const ['All Branches', 'Location Summary'],
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _GlassCard(
                child: Center(
                  child: Text(
                    'No branches found',
                    style: _CeoText.mutedFor(context, 11),
                  ),
                ),
              )
            else if (_tab == 0)
              ...filtered.map(
                (branch) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _CeoDashboardState._cyan.withValues(
                            alpha: .09,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _CeoDashboardState._cyan.withValues(
                              alpha: .35,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: _CeoDashboardState._cyan,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayText(branch['name'], fallback: 'Branch'),
                              style: _CeoText.titleFor(context, 12),
                            ),
                          ),
                          if (branch['is_head_office'] == true) ...[
                            const SizedBox(width: 6),
                            const _OrgBadge('HQ'),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        _displayText(
                          branch['city'],
                          fallback: 'Location not set',
                        ),
                        style: _CeoText.mutedFor(context, 9),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Employees',
                            style: _CeoText.mutedFor(context, 8),
                          ),
                          Text(
                            _displayText(branch['employees'], fallback: '0'),
                            style: _CeoText.titleFor(context, 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              _GlassCard(
                child: Column(
                  children: filtered.map((branch) {
                    final employees =
                        int.tryParse(_displayText(branch['employees'])) ?? 0;
                    final maxEmployees = branches.fold<int>(1, (value, row) {
                      final count =
                          int.tryParse(_displayText(row['employees'])) ?? 0;
                      return math.max(value, count);
                    });
                    return _ProgressInfo(
                      _displayText(branch['city'], fallback: 'Location'),
                      '$employees',
                      employees / maxEmployees,
                      _CeoDashboardState._cyan,
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 14),
            _OrganizationNextButton(
              label: 'Roles & Hierarchy',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _RolesHierarchyPage(
                    userId: widget.userId,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RolesHierarchyPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _RolesHierarchyPage({required this.userId, required this.onNavigate});

  @override
  State<_RolesHierarchyPage> createState() => _RolesHierarchyPageState();
}

class _RolesHierarchyPageState extends State<_RolesHierarchyPage> {
  late Future<Map<String, dynamic>> _future;
  int _tab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchOrganization(widget.userId);
  }

  void _retry() =>
      setState(() => _future = CeoService().fetchOrganization(widget.userId));

  void _openRoleDetails(Map<String, dynamic> role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OrganizationRoleDetailsPage(
          role: role,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
  }

  Future<void> _addRole() async {
    final values = await _showOrganizationFormDialog(
      context,
      title: 'Add Organization Role',
      submitLabel: 'Add Role',
      fields: const [
        _OrganizationFormFieldSpec('name', 'Role Name', required: true),
        _OrganizationFormFieldSpec(
          'business_unit',
          'Business Unit',
          required: true,
        ),
        _OrganizationFormFieldSpec('department', 'Department'),
        _OrganizationFormFieldSpec('reports_to', 'Reports To'),
        _OrganizationFormFieldSpec(
          'filled_positions',
          'Filled Positions',
          keyboardType: TextInputType.number,
        ),
        _OrganizationFormFieldSpec(
          'vacant_positions',
          'Vacant Positions',
          keyboardType: TextInputType.number,
        ),
      ],
      initialValues: const {'filled_positions': '0', 'vacant_positions': '0'},
    );
    if (values == null || !mounted) return;
    final result = await CeoService().saveOrganization(
      widget.userId,
      'add_role',
      values,
    );
    if (!mounted) return;
    _showOrganizationResult(context, result);
    if (result['success'] == true) _retry();
  }

  @override
  Widget build(BuildContext context) => _OrganizationFlowShell(
    title: 'Roles & Hierarchy',
    onNavigate: widget.onNavigate,
    trailing: IconButton(
      tooltip: 'Add role',
      onPressed: _addRole,
      icon: const Icon(Icons.add_rounded, color: _CeoDashboardState._cyan),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || !snapshot.hasData)
          return _OrganizationFlowError(onRetry: _retry);
        final data = snapshot.data!;
        final roles = _mapList(data['roles']);
        final leaders = _mapList(data['leaders']);
        final filteredRoles = roles
            .where(
              (role) => _displayText(
                role['name'],
              ).toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
        final totalRoles = roles.fold<int>(
          0,
          (sum, role) => sum + (int.tryParse(_displayText(role['count'])) ?? 0),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            _OrganizationSegmentedTabs(
              labels: const ['Hierarchy View', 'Roles List'],
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 12),
            _OrganizationSearchField(
              hint: 'Search roles',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            if (_tab == 0) ...[
              _OrganizationTreeNode(
                icon: Icons.workspace_premium_rounded,
                title: leaders.isEmpty
                    ? 'Chief Executive Officer'
                    : _displayText(
                        leaders.first['name'],
                        fallback: 'Chief Executive Officer',
                      ),
                subtitle: leaders.isEmpty
                    ? 'CEO'
                    : _displayText(
                        leaders.first['role_label'],
                        fallback: 'CEO',
                      ),
                color: _CeoDashboardState._cyan,
              ),
              const _OrgConnector(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: leaders
                    .skip(1)
                    .map(
                      (leader) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 38) / 2,
                        child: _OrganizationTreeNode(
                          icon: Icons.person_outline_rounded,
                          title: _displayText(
                            leader['name'],
                            fallback: 'Leader',
                          ),
                          subtitle: _displayText(
                            leader['role_label'],
                            fallback: 'Role',
                          ),
                          color: _CeoDashboardState._purple,
                          compact: true,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const _OrgConnector(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredRoles
                    .map(
                      (role) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 46) / 3,
                        child: _OrganizationTreeNode(
                          icon: Icons.badge_outlined,
                          title: _displayText(role['name'], fallback: 'Role'),
                          subtitle:
                              '${_displayText(role['count'], fallback: '0')} filled',
                          color: _CeoDashboardState._cyan,
                          compact: true,
                          onTap: () => _openRoleDetails(role),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              ...filteredRoles.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _GlassCard(
                    onTap: () => _openRoleDetails(role),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.badge_outlined,
                        color: _CeoDashboardState._cyan,
                      ),
                      title: Text(
                        _displayText(role['name'], fallback: 'Role'),
                        style: _CeoText.titleFor(context, 12),
                      ),
                      subtitle: Text(
                        '${_displayText(role['count'], fallback: '0')} filled positions',
                        style: _CeoText.mutedFor(context, 9),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: _CeoDashboardState._muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _OrganizationStatRow(
              items: [
                ('Total Roles', '$totalRoles'),
                ('Filled Positions', '$totalRoles'),
                ('Role Types', '${roles.length}'),
              ],
            ),
            const SizedBox(height: 14),
            _OrganizationNextButton(
              label: 'Organization Details',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _OrganizationDetailsPage(
                    userId: widget.userId,
                    onNavigate: widget.onNavigate,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _OrganizationRoleDetailsPage extends StatelessWidget {
  final Map<String, dynamic> role;
  final ValueChanged<int> onNavigate;

  const _OrganizationRoleDetailsPage({
    required this.role,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final members = _mapList(role['members']);
    final filled =
        int.tryParse(_displayText(role['filled_positions'], fallback: '0')) ??
        members.length;
    final vacant =
        int.tryParse(_displayText(role['vacant_positions'], fallback: '0')) ??
        0;
    final roleName = _displayText(role['name'], fallback: 'Role');
    return _OrganizationFlowShell(
      title: '$roleName Details',
      onNavigate: onNavigate,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _CeoDashboardState._cyan.withValues(alpha: .15),
                  _CeoDashboardState._purple.withValues(alpha: .10),
                  _CeoDashboardState._cardAlt,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _CeoDashboardState._cyan.withValues(alpha: .48),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _CeoDashboardState._cyan.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _CeoDashboardState._cyan.withValues(alpha: .45),
                    ),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: _CeoDashboardState._cyan,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roleName, style: _CeoText.titleFor(context, 18)),
                      const SizedBox(height: 4),
                      Text(
                        _displayText(
                          role['business_unit'],
                          fallback: 'Organization Role',
                        ),
                        style: _CeoText.mutedFor(context, 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OrganizationStatRow(
            items: [
              ('Filled Positions', '$filled'),
              ('Vacant Positions', '$vacant'),
              ('Total Positions', '${filled + vacant}'),
            ],
          ),
          const SizedBox(height: 12),
          _OrganizationDetailsCard(
            title: 'Role Information',
            rows: [
              ('Role Name', roleName),
              ('Business Unit', role['business_unit']),
              ('Department', role['department']),
              ('Reports To', role['reports_to']),
              ('Status', role['is_active'] == false ? 'Inactive' : 'Active'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Members in this Role',
                  style: _CeoText.titleFor(context, 14),
                ),
              ),
              _OrgBadge('${members.length} MEMBERS'),
            ],
          ),
          const SizedBox(height: 9),
          if (members.isEmpty)
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group_off_outlined,
                      color: _CeoDashboardState._muted,
                      size: 35,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No members assigned to this role',
                      style: _CeoText.mutedFor(context, 10),
                    ),
                  ],
                ),
              ),
            )
          else
            ...members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _GlassCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _EmployeeProfilePage(
                        employee: _employeeFromMap(member),
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: _CeoDashboardState._purple.withValues(
                        alpha: .18,
                      ),
                      child: Text(
                        _initials(_displayText(member['name'])),
                        style: const TextStyle(
                          color: _CeoDashboardState._cyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      _displayText(member['name'], fallback: 'Member'),
                      style: _CeoText.titleFor(context, 12),
                    ),
                    subtitle: Text(
                      [
                        _displayText(member['employee_id']),
                        _displayText(member['department']),
                      ].where((value) => value.isNotEmpty).join(' • '),
                      style: _CeoText.mutedFor(context, 9),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: _CeoDashboardState._muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrganizationDetailsPage extends StatefulWidget {
  final String userId;
  final ValueChanged<int> onNavigate;

  const _OrganizationDetailsPage({
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<_OrganizationDetailsPage> createState() =>
      _OrganizationDetailsPageState();
}

class _OrganizationDetailsPageState extends State<_OrganizationDetailsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = CeoService().fetchOrganization(widget.userId);
  }

  void _retry() =>
      setState(() => _future = CeoService().fetchOrganization(widget.userId));

  Future<void> _editDetails() async {
    Map<String, dynamic> data;
    try {
      data = await _future;
    } catch (_) {
      if (mounted) _retry();
      return;
    }
    if (!mounted) return;
    final company = _stringMap(data['company']);
    final values = await _showOrganizationFormDialog(
      context,
      title: 'Edit Organization Details',
      submitLabel: 'Save Changes',
      initialValues: {
        'name': _displayText(company['name']),
        'type': _displayText(company['type']),
        'industry': _displayText(company['industry']),
        'registration_number': _displayText(company['registration_number']),
        'founded_on': _displayText(company['founded_on']),
        'website': _displayText(company['website']),
        'email': _displayText(company['email']),
        'phone': _displayText(company['phone_edit_value']),
        'address': _displayText(company['address']),
        'pan': _displayText(company['pan']),
        'gstin': _displayText(company['gstin']),
        'esi_number': _displayText(company['esi_number']),
        'pf_code': _displayText(company['pf_code']),
      },
      fields: const [
        _OrganizationFormFieldSpec('name', 'Company Name', required: true),
        _OrganizationFormFieldSpec('type', 'Company Type'),
        _OrganizationFormFieldSpec('industry', 'Industry'),
        _OrganizationFormFieldSpec(
          'registration_number',
          'Registration Number',
        ),
        _OrganizationFormFieldSpec('founded_on', 'Founded On'),
        _OrganizationFormFieldSpec(
          'website',
          'Website',
          keyboardType: TextInputType.url,
        ),
        _OrganizationFormFieldSpec(
          'email',
          'Organization Email',
          keyboardType: TextInputType.emailAddress,
        ),
        _OrganizationFormFieldSpec(
          'phone',
          'Organization Phone',
          keyboardType: TextInputType.phone,
        ),
        _OrganizationFormFieldSpec(
          'address',
          'Registered Address',
          maxLines: 3,
        ),
        _OrganizationFormFieldSpec('pan', 'PAN'),
        _OrganizationFormFieldSpec('gstin', 'GSTIN'),
        _OrganizationFormFieldSpec('esi_number', 'ESI Number'),
        _OrganizationFormFieldSpec('pf_code', 'PF Code'),
      ],
    );
    if (values == null || !mounted) return;
    final result = await CeoService().saveOrganization(
      widget.userId,
      'update_details',
      values,
    );
    if (!mounted) return;
    _showOrganizationResult(context, result);
    if (result['success'] == true) _retry();
  }

  @override
  Widget build(BuildContext context) => _OrganizationFlowShell(
    title: 'Organization Details',
    onNavigate: widget.onNavigate,
    trailing: TextButton(
      onPressed: _editDetails,
      child: const Text(
        'Edit',
        style: TextStyle(
          color: _CeoDashboardState._cyan,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        if (snapshot.hasError || !snapshot.hasData)
          return _OrganizationFlowError(onRetry: _retry);
        final company = _stringMap(snapshot.data!['company']);
        final documents = _mapList(company['documents']);
        final stats = _mapList(company['stats']);
        final services = _mapList(company['services']);
        final highlights = company['highlights'] is List
            ? List<String>.from(
                (company['highlights'] as List).map(_displayText),
              )
            : <String>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _CeoDashboardState._cyan.withValues(alpha: .16),
                    _CeoDashboardState._purple.withValues(alpha: .10),
                    _CeoDashboardState._cardAlt,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _CeoDashboardState._cyan.withValues(alpha: .55),
                ),
              ),
              child: Column(
                children: [
                  const BitByteLogo(size: 72, showSubtitle: false),
                  const SizedBox(height: 12),
                  Text(
                    _displayText(
                      company['name'],
                      fallback: 'Bit Byte Technologies',
                    ),
                    textAlign: TextAlign.center,
                    style: _CeoText.titleFor(context, 20),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        _CeoDashboardState._cyan,
                        _CeoDashboardState._purple,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      _displayText(company['tagline']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _displayText(company['summary']),
                    textAlign: TextAlign.center,
                    style: _CeoText.mutedFor(context, 10),
                  ),
                ],
              ),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 10),
              _OrganizationStatRow(
                items: stats
                    .map(
                      (item) => (
                        _displayText(item['label']),
                        _displayText(item['value']),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: _CeoDashboardState._purple,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text('Our Story', style: _CeoText.titleFor(context, 13)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _displayText(company['story']),
                    style: _CeoText.mutedFor(context, 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Core Service Systems', style: _CeoText.titleFor(context, 14)),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services
                  .map(
                    (service) => SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 36) / 2,
                      child: _OrganizationWebsiteServiceCard(service: service),
                    ),
                  )
                  .toList(),
            ),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Choose Bit Byte',
                      style: _CeoText.titleFor(context, 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: highlights
                          .map(
                            (label) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _CeoDashboardState._cyan.withValues(
                                  alpha: .08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _CeoDashboardState._cyan.withValues(
                                    alpha: .28,
                                  ),
                                ),
                              ),
                              child: Text(
                                label,
                                style: _CeoText.titleFor(context, 8.5),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Official Contact',
                    style: _CeoText.titleFor(context, 13),
                  ),
                  const SizedBox(height: 6),
                  _OrganizationWebsiteContactTile(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    value: _displayText(company['website']),
                  ),
                  _OrganizationWebsiteContactTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _displayText(company['email']),
                  ),
                  _OrganizationWebsiteContactTile(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    value: _displayText(company['phone']),
                    note: _displayText(company['phone_note']),
                  ),
                  _OrganizationWebsiteContactTile(
                    icon: Icons.location_on_outlined,
                    label: 'Head Office',
                    value: _displayText(company['address']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OrganizationDetailsCard(
              title: 'Company & Legal Information',
              rows: [
                ('Company Name', company['name']),
                ('Registration Number', company['registration_number']),
                ('Founded On', company['founded_on']),
                ('Company Type', company['type']),
                ('Industry', company['industry']),
              ],
            ),
            const SizedBox(height: 10),
            _OrganizationDetailsCard(
              title: 'Statutory Details',
              rows: [
                ('PAN', company['pan']),
                ('GSTIN', company['gstin']),
                ('ESI Number', company['esi_number']),
                ('PF Code', company['pf_code']),
              ],
            ),
            const SizedBox(height: 10),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organization Documents',
                    style: _CeoText.titleFor(context, 12),
                  ),
                  const SizedBox(height: 10),
                  if (documents.isEmpty)
                    Text(
                      'No organization documents uploaded',
                      style: _CeoText.mutedFor(context, 10),
                    )
                  else
                    ...documents.map(
                      (document) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.description_outlined,
                          color: _CeoDashboardState._cyan,
                        ),
                        title: Text(
                          _displayText(document['name'], fallback: 'Document'),
                          style: _CeoText.titleFor(context, 11),
                        ),
                        trailing: const Icon(
                          Icons.download_rounded,
                          color: _CeoDashboardState._muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _OrganizationFormFieldSpec {
  final String keyName;
  final String label;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;

  const _OrganizationFormFieldSpec(
    this.keyName,
    this.label, {
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
}

Future<Map<String, String>?> _showOrganizationFormDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required List<_OrganizationFormFieldSpec> fields,
  Map<String, String> initialValues = const {},
}) async {
  final formKey = GlobalKey<FormState>();
  final controllers = {
    for (final field in fields)
      field.keyName: TextEditingController(
        text: initialValues[field.keyName] ?? '',
      ),
  };
  final result = await showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _CeoDashboardState._card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _CeoDashboardState._border),
      ),
      title: Text(title, style: _CeoText.titleFor(dialogContext, 16)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: controllers[field.keyName],
                    keyboardType: field.keyboardType,
                    maxLines: field.maxLines,
                    style: _CeoText.titleFor(dialogContext, 11),
                    validator: (value) {
                      final clean = value?.trim() ?? '';
                      if (field.required && clean.isEmpty) {
                        return '${field.label} is required';
                      }
                      if (field.keyboardType == TextInputType.emailAddress &&
                          clean.isNotEmpty &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(clean)) {
                        return 'Enter a valid email address';
                      }
                      if (field.keyboardType == TextInputType.number &&
                          clean.isNotEmpty &&
                          (int.tryParse(clean) == null ||
                              int.parse(clean) < 0)) {
                        return 'Enter a valid non-negative number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: field.required
                          ? '${field.label} *'
                          : field.label,
                      labelStyle: _CeoText.mutedFor(dialogContext, 10),
                      filled: true,
                      fillColor: _CeoDashboardState._cardAlt,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: _CeoDashboardState._border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: _CeoDashboardState._cyan,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(dialogContext).pop({
              for (final field in fields)
                field.keyName: controllers[field.keyName]?.text.trim() ?? '',
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: _CeoDashboardState._cyan,
            foregroundColor: const Color(0xFF001321),
          ),
          child: Text(submitLabel),
        ),
      ],
    ),
  );
  for (final controller in controllers.values) {
    controller.dispose();
  }
  return result;
}

void _showOrganizationResult(
  BuildContext context,
  Map<String, dynamic> result,
) {
  final success = result['success'] == true;
  var message = _displayText(
    result['message'],
    fallback: success ? 'Saved successfully.' : 'Unable to save changes.',
  );
  final errors = result['errors'];
  if (!success && errors is Map && errors.isNotEmpty) {
    message = errors.values
        .map(_displayText)
        .where((text) => text.isNotEmpty)
        .join('\n');
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? _CeoDashboardState._green : Colors.redAccent,
    ),
  );
}

Map<String, dynamic> _stringMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

class _OrganizationSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _OrganizationSegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _CeoDashboardState._cardAlt,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _CeoDashboardState._border),
    ),
    child: Row(
      children: labels
          .asMap()
          .entries
          .map(
            (entry) => Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected == entry.key
                        ? ThemeConfig.blueGradient
                        : null,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == entry.key
                          ? Colors.white
                          : _CeoDashboardState._muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _OrganizationSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _OrganizationSearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: _CeoText.titleFor(context, 11),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: _CeoText.mutedFor(context, 11),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: _CeoDashboardState._muted,
      ),
      filled: true,
      fillColor: _CeoDashboardState._cardAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _CeoDashboardState._border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _CeoDashboardState._border),
      ),
    ),
  );
}

class _OrganizationStatRow extends StatelessWidget {
  final List<(String, String)> items;
  const _OrganizationStatRow({required this.items});

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Row(
      children: items
          .asMap()
          .entries
          .expand(
            (entry) => [
              if (entry.key > 0)
                Container(
                  width: 1,
                  height: 42,
                  color: _CeoDashboardState._border,
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      entry.value.$2,
                      style: const TextStyle(
                        color: _CeoDashboardState._cyan,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.value.$1,
                      textAlign: TextAlign.center,
                      style: _CeoText.mutedFor(context, 8.5),
                    ),
                  ],
                ),
              ),
            ],
          )
          .toList(),
    ),
  );
}

class _OrganizationTreeNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  const _OrganizationTreeNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: _CeoDashboardState._cardAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .06), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 21 : 28),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _CeoText.titleFor(context, compact ? 9 : 12),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _CeoText.mutedFor(context, compact ? 7.5 : 9),
          ),
        ],
      ),
    ),
  );
}

class _OrgConnector extends StatelessWidget {
  const _OrgConnector();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 2,
      height: 24,
      color: _CeoDashboardState._cyan.withValues(alpha: .75),
    ),
  );
}

class _OrgBadge extends StatelessWidget {
  final String label;
  const _OrgBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: _CeoDashboardState._cyan.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _CeoDashboardState._cyan,
        fontSize: 7,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _OrganizationNextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OrganizationNextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: _CeoDashboardState._cyan,
      side: const BorderSide(color: _CeoDashboardState._cyan),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    icon: const Icon(Icons.account_tree_rounded, size: 19),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _OrganizationWebsiteServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;

  const _OrganizationWebsiteServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final category = _displayText(service['category']);
    final icon = switch (category.toLowerCase()) {
      'software' => Icons.code_rounded,
      'identity' => Icons.fingerprint_rounded,
      'growth' => Icons.trending_up_rounded,
      'insight' => Icons.analytics_outlined,
      'prototype' => Icons.rocket_launch_outlined,
      _ => Icons.query_stats_rounded,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CeoDashboardState._cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _CeoDashboardState._cyan.withValues(alpha: .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _CeoDashboardState._cyan.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _CeoDashboardState._cyan, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              color: _CeoDashboardState._purple,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _displayText(service['name']),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.titleFor(context, 10),
          ),
        ],
      ),
    );
  }
}

class _OrganizationWebsiteContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String note;

  const _OrganizationWebsiteContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.note = '',
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: value.isEmpty
        ? null
        : () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$label copied')));
          },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _CeoDashboardState._cyan.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _CeoDashboardState._cyan, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _CeoText.mutedFor(context, 8.5)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not configured' : value,
                  style: _CeoText.titleFor(context, 9.5),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(
                      color: _CeoDashboardState._green,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          if (value.isNotEmpty)
            const Icon(
              Icons.copy_rounded,
              color: _CeoDashboardState._muted,
              size: 15,
            ),
        ],
      ),
    ),
  );
}

class _OrganizationDetailsCard extends StatelessWidget {
  final String title;
  final List<(String, Object?)> rows;
  final IconData? icon;

  const _OrganizationDetailsCard({
    required this.title,
    required this.rows,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: _CeoDashboardState._cyan, size: 18),
              const SizedBox(width: 7),
            ],
            Text(title, style: _CeoText.titleFor(context, 12)),
          ],
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          final value = _displayText(row.$2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 126,
                  child: Text(row.$1, style: _CeoText.mutedFor(context, 9)),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Not configured' : value,
                    style: _CeoText.titleFor(context, 9.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class _CeoLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CeoLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: _CeoDashboardState._muted,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(message, style: _CeoText.mutedFor(context, 12)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _OrganizationMenuDrawer extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _OrganizationMenuDrawer({required this.onNavigate});

  void _go(BuildContext context, int index) {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    onNavigate(index);
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const BitByteLogo(compact: true),
                  const SizedBox(width: 12),
                  Text(
                    'CEO Navigation',
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: border),
            _OrganizationDrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => _go(context, 0),
            ),
            _OrganizationDrawerItem(
              icon: Icons.groups_2_rounded,
              label: 'People',
              onTap: () => _go(context, 1),
            ),
            _OrganizationDrawerItem(
              icon: Icons.approval_rounded,
              label: 'Approvals',
              onTap: () => _go(context, 2),
            ),
            _OrganizationDrawerItem(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              selected: true,
              onTap: () => _go(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _OrganizationDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      icon,
      color: selected ? _CeoDashboardState._cyan : _CeoDashboardState._muted,
    ),
    title: Text(
      label,
      style: TextStyle(
        color: selected
            ? _CeoDashboardState._cyan
            : ThemeConfig.getTextPrimary(context),
        fontWeight: FontWeight.w800,
      ),
    ),
    selected: selected,
    selectedTileColor: _CeoDashboardState._cyan.withValues(alpha: 0.08),
    onTap: onTap,
  );
}

class _OrganizationMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OrganizationMetric(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.onTap,
  );
}

class _OrganizationMetricGrid extends StatelessWidget {
  final List<_OrganizationMetric> metrics;

  const _OrganizationMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 116,
    child: Row(
      children: metrics.asMap().entries.expand((entry) {
        final metric = entry.value;
        return [
          if (entry.key > 0) const SizedBox(width: 8),
          Expanded(
            child: _GlassCard(
              onTap: metric.onTap,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(metric.icon, color: metric.color, size: 25),
                  const SizedBox(height: 7),
                  Text(
                    metric.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: _CeoText.titleFor(context, 8.5),
                  ),
                  const SizedBox(height: 4),
                  Text(metric.value, style: _CeoText.titleFor(context, 18)),
                ],
              ),
            ),
          ),
        ];
      }).toList(),
    ),
  );
}

class _OrganizationHealthCard extends StatelessWidget {
  final int score;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _OrganizationHealthCard({
    required this.score,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? _CeoDashboardState._green
        : score >= 70
        ? _CeoDashboardState._gold
        : Colors.redAccent;
    return _GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NumberedOrgTitle(
            number: 1,
            title: 'Organization Health',
            icon: Icons.monitor_heart_outlined,
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: score.clamp(0, 100) / 100,
                      strokeWidth: 7,
                      backgroundColor: _CeoDashboardState._border,
                      color: color,
                    ),
                  ),
                  Text('$score%', style: _CeoText.titleFor(context, 25)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: _CeoText.mutedFor(context, 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDistributionCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int totalEmployees;
  final VoidCallback onTap;

  const _EmployeeDistributionCard({
    required this.items,
    required this.totalEmployees,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      _CeoDashboardState._cyan,
      _CeoDashboardState._purple,
      _CeoDashboardState._green,
      _CeoDashboardState._pink,
      _CeoDashboardState._gold,
    ];
    return _GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NumberedOrgTitle(
            number: 2,
            title: 'Employee Distribution',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No branch/location data',
                  style: _CeoText.mutedFor(context, 11),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                    painter: _DistributionDonutPainter(
                      values: items
                          .take(5)
                          .map(
                            (item) =>
                                int.tryParse(_displayText(item['count'])) ?? 0,
                          )
                          .toList(),
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: items.take(5).toList().asMap().entries.map((
                      entry,
                    ) {
                      final item = entry.value;
                      final count =
                          int.tryParse(_displayText(item['count'])) ?? 0;
                      final color = colors[entry.key % colors.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
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
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _displayText(
                                  item['name'],
                                  fallback: 'Location',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _CeoText.titleFor(context, 8.5),
                              ),
                            ),
                            Text(
                              '$count',
                              style: _CeoText.titleFor(context, 8.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DistributionDonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  const _DistributionDonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final background = Paint()
      ..color = _CeoDashboardState._border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 21;
    canvas.drawCircle(center, radius, background);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / total) * math.pi * 2;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 21
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionDonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _NumberedOrgTitle extends StatelessWidget {
  final int number;
  final String title;
  final IconData icon;

  const _NumberedOrgTitle({
    required this.number,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _CeoDashboardState._cyan, size: 14),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          '$number.  $title',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _CeoText.titleFor(context, 8.5),
        ),
      ),
    ],
  );
}

class _BusinessUnitsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onViewAll;

  const _BusinessUnitsCard({required this.items, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final colors = [
      _CeoDashboardState._cyan,
      _CeoDashboardState._purple,
      _CeoDashboardState._green,
      _CeoDashboardState._gold,
    ];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onViewAll,
            child: const _NumberedOrgTitle(
              number: 3,
              title: 'Business Units',
              icon: Icons.chevron_right_rounded,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 105,
            child: Row(
              children: items.take(4).toList().asMap().entries.expand((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = colors[index % colors.length];
                final name = _displayText(item['name'], fallback: 'Unit');
                final icon = name.toLowerCase().contains('technology')
                    ? Icons.developer_mode_rounded
                    : name.toLowerCase().contains('operations')
                    ? Icons.settings_outlined
                    : name.toLowerCase().contains('sales')
                    ? Icons.trending_up_rounded
                    : Icons.headset_mic_outlined;
                return [
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.titleFor(context, 8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayText(item['count'], fallback: '0'),
                            style: _CeoText.titleFor(context, 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationStructureCard extends StatelessWidget {
  final List<Map<String, dynamic>> businessUnits;
  final int departments;
  final VoidCallback onTap;

  const _OrganizationStructureCard({
    required this.businessUnits,
    required this.departments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUnits = businessUnits
        .where((item) => (int.tryParse(_displayText(item['count'])) ?? 0) > 0)
        .take(3)
        .toList();
    return _GlassCard(
      child: Column(
        children: [
          const _NumberedOrgTitle(
            number: 4,
            title: 'Organization Structure',
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: 15),
          _StructureNode(
            label: 'CEO',
            color: _CeoDashboardState._cyan,
            width: 102,
          ),
          Container(width: 1, height: 18, color: _CeoDashboardState._muted),
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: _CeoDashboardState._muted),
              ),
              Expanded(
                child: Container(height: 1, color: _CeoDashboardState._muted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: visibleUnits.isEmpty
                ? [
                    Expanded(
                      child: _StructureNode(
                        label: '$departments\nDepartments',
                        color: _CeoDashboardState._green,
                      ),
                    ),
                  ]
                : visibleUnits.asMap().entries.expand((entry) {
                    final colors = [
                      _CeoDashboardState._purple,
                      _CeoDashboardState._green,
                      _CeoDashboardState._gold,
                    ];
                    final unit = entry.value;
                    return [
                      if (entry.key > 0) const SizedBox(width: 7),
                      Expanded(
                        child: _StructureNode(
                          label:
                              '${_displayText(unit['count'], fallback: '0')}\n${_displayText(unit['name'], fallback: 'Unit')}',
                          color: colors[entry.key % colors.length],
                        ),
                      ),
                    ];
                  }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: _CeoDashboardState._cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _CeoDashboardState._cyan.withValues(alpha: 0.55),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 12,
                  color: _CeoDashboardState._cyan,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.account_tree_rounded, size: 17),
              label: const Text('View Org Chart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _CeoDashboardState._cyan,
                side: const BorderSide(color: _CeoDashboardState._cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureNode extends StatelessWidget {
  final String label;
  final Color color;
  final double? width;

  const _StructureNode({required this.label, required this.color, this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: 0.65)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: _CeoText.titleFor(context, 9),
    ),
  );
}

class _LeadershipOverviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> leaders;
  final ValueChanged<Map<String, dynamic>> onPersonTap;
  final VoidCallback onViewAll;

  const _LeadershipOverviewCard({
    required this.leaders,
    required this.onPersonTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(
      children: [
        InkWell(
          onTap: onViewAll,
          child: const _NumberedOrgTitle(
            number: 5,
            title: 'Leadership Overview',
            icon: Icons.groups_2_outlined,
          ),
        ),
        const SizedBox(height: 8),
        if (leaders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 45),
            child: Text(
              'No leadership records found',
              style: _CeoText.mutedFor(context, 11),
            ),
          )
        else
          ...leaders.take(3).map((leader) {
            final name = _displayText(leader['name'], fallback: 'Leader');
            return InkWell(
              onTap: () => onPersonTap(leader),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: _CeoDashboardState._cyan.withValues(
                        alpha: 0.13,
                      ),
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: _CeoDashboardState._cyan,
                          fontSize: 10,
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
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.titleFor(context, 11),
                          ),
                          Text(
                            _displayText(
                              leader['role_label'],
                              fallback: _displayText(leader['role']),
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.mutedFor(context, 9),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _CeoDashboardState._muted,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
      .toUpperCase();
}

class _OrganizationChangesCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onTap;
  final VoidCallback onViewAll;

  const _OrganizationChangesCard({
    required this.items,
    required this.onTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _NumberedOrgTitle(
          number: 6,
          title: 'Recent Organization Changes',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 9),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                'No recent organization changes',
                style: _CeoText.mutedFor(context, 11),
              ),
            ),
          )
        else
          ...items.take(4).toList().asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.take(4).length - 1;
            return InkWell(
              onTap: () => onTap(item),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          if (!isLast)
                            Positioned(
                              top: 28,
                              bottom: 0,
                              child: Container(
                                width: 1,
                                color: _CeoDashboardState._muted,
                              ),
                            ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _CeoDashboardState._cyan.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _CeoDashboardState._cyan,
                              ),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: _CeoDashboardState._cyan,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayText(item['title'], fallback: 'Change'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.titleFor(context, 10),
                          ),
                          Text(
                            _displayText(item['subtitle']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.mutedFor(context, 8),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _displayText(item['time']),
                      style: _CeoText.mutedFor(context, 8),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (items.isNotEmpty) ...[
          Divider(color: _CeoDashboardState._border, height: 12),
          Center(
            child: TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View All Changes  ›',
                style: TextStyle(
                  color: _CeoDashboardState._cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _OrganizationQuickActions extends StatelessWidget {
  final VoidCallback onCompany;
  final VoidCallback onBranches;
  final VoidCallback onUnits;
  final VoidCallback onChart;

  const _OrganizationQuickActions({
    required this.onCompany,
    required this.onBranches,
    required this.onUnits,
    required this.onChart,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.apartment_rounded, 'Company Profile', onCompany),
      (Icons.location_on_outlined, 'Branches', onBranches),
      (Icons.view_in_ar_rounded, 'Business Units', onUnits),
      (Icons.account_tree_rounded, 'Org Chart', onChart),
    ];
    return SizedBox(
      height: 72,
      child: Row(
        children: actions.asMap().entries.expand((entry) {
          final action = entry.value;
          return [
            if (entry.key > 0) const SizedBox(width: 8),
            Expanded(
              child: _GlassCard(
                onTap: action.$3,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.$1, color: _CeoDashboardState._cyan, size: 21),
                    const SizedBox(height: 5),
                    Text(
                      action.$2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.titleFor(context, 7.5),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }).toList(),
      ),
    );
  }
}

class _OrganizationCollectionPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final IconData icon;

  const _OrganizationCollectionPage({
    required this.title,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => _CeoShell(
    title: title,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        if (items.isEmpty)
          _GlassCard(
            child: Center(
              child: Text(
                'No data available',
                style: _CeoText.mutedFor(context, 12),
              ),
            ),
          ),
        ...items.map((item) {
          final titleText = _displayText(
            item['name'],
            fallback: _displayText(item['title'], fallback: 'Item'),
          );
          final subtitle = _displayText(
            item['role_label'],
            fallback: _displayText(
              item['subtitle'],
              fallback: '${_displayText(item['count'], fallback: '0')} members',
            ),
          );
          return _CeoFlowListTile(
            icon: icon,
            title: titleText,
            subtitle: subtitle,
            color: _CeoDashboardState._cyan,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    _CeoDataDetailPage(title: titleText, data: item),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class _BudgetOverviewDynamicPage extends StatelessWidget {
  final String userId;

  const _BudgetOverviewDynamicPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Budget Directory',
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchBudget(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _BudgetCard(
                'Total Budget',
                _displayText(data['total_budget'], fallback: '0'),
                null,
              ),
              _BudgetCard(
                'Total Spent',
                _displayText(data['total_spent'], fallback: '0'),
                _displayText(data['spent_percent']),
              ),
              _BudgetCard(
                'Remaining Budget',
                _displayText(data['remaining_budget'], fallback: '0'),
                _displayText(data['remaining_percent']),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Budget vs Actual',
                bars: _chartBars(data['budget_bars']),
                color: _CeoDashboardState._cyan,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeDirectoryDynamicPage extends StatefulWidget {
  final String userId;
  final bool embedded;

  const _EmployeeDirectoryDynamicPage({
    required this.userId,
    this.embedded = false,
  });

  @override
  State<_EmployeeDirectoryDynamicPage> createState() =>
      _EmployeeDirectoryDynamicPageState();
}

class _EmployeeDirectoryDynamicPageState
    extends State<_EmployeeDirectoryDynamicPage> {
  final _search = TextEditingController();
  String _roleFilter = 'All';
  String _departmentFilter = 'All';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<Map<String, dynamic>>(
      future: CeoService().fetchEmployees(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
          );
        }
        final items = _roleMembers(snapshot.data!['role_members']);
        final query = _search.text.trim().toLowerCase();
        final employees = items.map(_employeeFromMap).where((employee) {
          final matchesQuery =
              query.isEmpty ||
              employee.name.toLowerCase().contains(query) ||
              employee.role.toLowerCase().contains(query) ||
              employee.department.toLowerCase().contains(query) ||
              employee.id.toLowerCase().contains(query);
          final matchesRole =
              _roleFilter == 'All' || employee.role == _roleFilter;
          final matchesDepartment =
              _departmentFilter == 'All' ||
              employee.department == _departmentFilter;
          final matchesStatus =
              _statusFilter == 'All' || employee.status == _statusFilter;
          return matchesQuery &&
              matchesRole &&
              matchesDepartment &&
              matchesStatus;
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            _EmployeeSearchBox(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _PeopleFilterChips(total: employees.length),
            if (_roleFilter != 'All' ||
                _departmentFilter != 'All' ||
                _statusFilter != 'All') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_roleFilter != 'All')
                    InputChip(
                      label: Text('Role: $_roleFilter'),
                      onDeleted: () => setState(() => _roleFilter = 'All'),
                    ),
                  if (_departmentFilter != 'All')
                    InputChip(
                      label: Text('Dept: $_departmentFilter'),
                      onDeleted: () =>
                          setState(() => _departmentFilter = 'All'),
                    ),
                  if (_statusFilter != 'All')
                    InputChip(
                      label: Text('Status: $_statusFilter'),
                      onDeleted: () => setState(() => _statusFilter = 'All'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (employees.isEmpty)
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No members found',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ),
            ...employees.map(
              (e) => _EmployeeTile(
                employee: e,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _EmployeeProfilePage(employee: e),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return body;
    return _CeoShell(
      title: 'People Intelligence',
      trailing: IconButton(
        tooltip: 'Filter people',
        icon: const Icon(
          Icons.filter_list_rounded,
          color: _CeoDashboardState._cyan,
        ),
        onPressed: () async {
          final data = await CeoService().fetchEmployees(widget.userId);
          if (!mounted) return;
          final employees = _roleMembers(
            data['role_members'],
          ).map(_employeeFromMap).toList();
          await _showPeopleFilters(
            roles: _employeeFilterOptions(employees, (e) => e.role),
            departments: _employeeFilterOptions(employees, (e) => e.department),
            statuses: _employeeFilterOptions(employees, (e) => e.status),
          );
        },
      ),
      child: body,
    );
  }

  List<String> _employeeFilterOptions(
    List<_Employee> employees,
    String Function(_Employee employee) selector,
  ) {
    final options = <String>{
      'All',
      ...employees
          .map(selector)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty && value != '-'),
    }.toList();
    return options;
  }

  Future<void> _showPeopleFilters({
    required List<String> roles,
    required List<String> departments,
    required List<String> statuses,
  }) async {
    var role = roles.contains(_roleFilter) ? _roleFilter : 'All';
    var department = departments.contains(_departmentFilter)
        ? _departmentFilter
        : 'All';
    var status = statuses.contains(_statusFilter) ? _statusFilter : 'All';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              Text('Filter People', style: _CeoText.titleFor(context, 18)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: role,
                items: roles
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => role = value ?? 'All'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: department,
                items: departments
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => department = value ?? 'All'),
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                items: statuses
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => status = value ?? 'All'),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _roleFilter = 'All';
                          _departmentFilter = 'All';
                          _statusFilter = 'All';
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _roleFilter = role;
                          _departmentFilter = department;
                          _statusFilter = status;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmployeeProfilePage extends StatefulWidget {
  final _Employee employee;
  const _EmployeeProfilePage({required this.employee});

  @override
  State<_EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<_EmployeeProfilePage> {
  bool _showAttendance = false;
  late Future<Map<String, dynamic>> _attendanceFuture;

  _Employee get employee => widget.employee;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = CeoService().fetchEmployeeAttendance(employee.id);
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Employee 360',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _ProfileHeader(
            firstName: employee.name,
            email: employee.email,
            role: employee.role,
            imageUrl: employee.photoUrl,
          ),
          const SizedBox(height: 16),
          _SegmentTabs(
            left: 'Overview',
            right: 'Attendance',
            rightActive: _showAttendance,
            onLeftTap: () => setState(() => _showAttendance = false),
            onRightTap: () => setState(() => _showAttendance = true),
          ),
          const SizedBox(height: 14),
          if (_showAttendance)
            _EmployeeAttendancePanel(
              employee: employee,
              attendanceFuture: _attendanceFuture,
            )
          else
            Column(
              children: [
                _EmployeeOverviewPanel(employee: employee),
                if (employee.children.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _CreatedMembersPanel(
                    title: employee.role.toLowerCase().contains('tl')
                        ? 'Employees Under This TL'
                        : 'Created Members',
                    members: employee.children,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _NotificationsDynamicPage extends StatefulWidget {
  final String userId;

  const _NotificationsDynamicPage({required this.userId});

  @override
  State<_NotificationsDynamicPage> createState() =>
      _NotificationsDynamicPageState();
}

class _NotificationsDynamicPageState extends State<_NotificationsDynamicPage> {
  bool _unreadOnly = false;

  Future<void> _openApprovalNotification(Map<String, dynamic> notification) async {
    final referenceId = '${notification['reference_id'] ?? ''}';
    try {
      final data = await CeoService().fetchApprovals(widget.userId);
      Map<String, dynamic>? approval;
      for (final key in ['approvals', 'history']) {
        final values = data[key];
        if (values is! List) continue;
        for (final raw in values.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          if ('${item['id'] ?? ''}' == referenceId &&
              const {'daily_report', 'social_media_post', 'leave_request'}
                  .contains(item['approval_type'])) {
            approval = item;
            break;
          }
        }
        if (approval != null) break;
      }
      if (!mounted) return;
      if (approval == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This approval is not awaiting CEO action.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeApprovalDetailScreen(
            item: approval!,
            userId: widget.userId,
            service: EmployeeService(),
            received: '${approval!['status'] ?? ''}'.toLowerCase() == 'requested' &&
                '${approval!['current_stage'] ?? ''}' == '1',
          ),
        ),
      );
      final notificationId = notification['id'];
      if (notificationId is int) {
        await CeoService().markNotificationRead(notificationId, widget.userId);
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open approval: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Notifications',
      trailing: const Icon(
        Icons.more_vert_rounded,
        color: _CeoDashboardState._muted,
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: CeoService().fetchNotifications(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final items = snapshot.data!['notifications'] is List
              ? snapshot.data!['notifications'] as List
              : const [];
          final filteredItems = _unreadOnly
              ? items.where((item) {
                  final map = item is Map
                      ? Map<String, dynamic>.from(item)
                      : <String, dynamic>{};
                  return map['is_read'] != true;
                }).toList()
              : items;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              _SegmentTabs(
                left: 'All',
                right: 'Unread',
                rightActive: _unreadOnly,
                onLeftTap: () => setState(() => _unreadOnly = false),
                onRightTap: () => setState(() => _unreadOnly = true),
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                _GlassCard(
                  child: Center(
                    child: Text(
                      _unreadOnly
                          ? 'No unread notifications found'
                          : 'No notifications found',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ...filteredItems.map((item) {
                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                final type = _displayText(
                  map['type'],
                  fallback: _displayText(map['notification_type']),
                );
                return _NotificationTile(
                  _notificationIcon(type),
                  _displayText(map['title'], fallback: 'Notification'),
                  _displayText(
                    map['subtitle'],
                    fallback: _displayText(map['message']),
                  ),
                  _displayText(
                    map['time'],
                    fallback: _displayText(map['trailing']),
                  ),
                  _notificationColor(type),
                  onTap: _displayText(map['module']) == 'approval'
                      ? () => _openApprovalNotification(map)
                      : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _MeetingsDynamicPage extends StatefulWidget {
  final String userId;

  const _MeetingsDynamicPage({required this.userId});

  @override
  State<_MeetingsDynamicPage> createState() => _MeetingsDynamicPageState();
}

class _MeetingsDynamicPageState extends State<_MeetingsDynamicPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CeoService().fetchMeetings(widget.userId);
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

  String _timeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  List<Map<String, dynamic>> _participantOptions(Map<String, dynamic> data) {
    final raw = data['available_participants'] is List
        ? data['available_participants'] as List
        : data['participants'] is List
        ? data['participants'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _displayText(item['id']).isNotEmpty)
        .toList();
  }

  Future<void> _openSchedule(Map<String, dynamic> data) async {
    final options = _participantOptions(data);
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users are available under this CEO.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '30 minutes');
    final linkController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String platform = 'Online';
    final selectedIds = <String>{};

    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setSheetState(() => selectedDate = picked);
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: sheetContext,
                initialTime: selectedTime,
              );
              if (picked != null) setSheetState(() => selectedTime = picked);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              maxChildSize: 0.94,
              minChildSize: 0.55,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      18 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                      Text(
                        'Schedule Meeting',
                        style: _CeoText.titleFor(context, 18),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: platform,
                        items:
                            const [
                                  'Online',
                                  'Google Meet',
                                  'Zoom',
                                  'Microsoft Teams',
                                  'Office',
                                ]
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setSheetState(() => platform = value ?? platform),
                        decoration: const InputDecoration(
                          labelText: 'Meeting type',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickDate,
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(_dateLabel(selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickTime,
                              icon: const Icon(Icons.schedule_rounded),
                              label: Text(_timeLabel(selectedTime)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting link / location',
                          hintText: 'Leave empty to auto-create online link',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scheduled users',
                        style: _CeoText.titleFor(context, 13),
                      ),
                      const SizedBox(height: 8),
                      ...options.map((person) {
                        final id = _displayText(person['id']);
                        final checked = selectedIds.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          contentPadding: EdgeInsets.zero,
                          activeColor: _CeoDashboardState._cyan,
                          title: Text(
                            _displayText(person['name'], fallback: id),
                          ),
                          subtitle: Text(
                            [
                              _displayText(
                                person['role_label'],
                                fallback: _displayText(person['role']),
                              ),
                              _displayText(person['department']),
                            ].where((value) => value.isNotEmpty).join(' • '),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty || selectedIds.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter title and select at least one user.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(sheetContext, {
                            'title': title,
                            'platform': platform,
                            'meeting_platform': platform,
                            'meeting_type': platform,
                            'meeting_link': linkController.text.trim(),
                            'location': linkController.text.trim(),
                            'date_label': _dateLabel(selectedDate),
                            'time_label': _timeLabel(selectedTime),
                            'duration': durationController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'participants': options
                                .where(
                                  (person) => selectedIds.contains(
                                    _displayText(person['id']),
                                  ),
                                )
                                .toList(),
                          });
                        },
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('Schedule & Notify Users'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    titleController.dispose();
    durationController.dispose();
    linkController.dispose();
    descriptionController.dispose();

    if (payload == null) return;
    final result = await CeoService().scheduleMeeting(widget.userId, payload);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meeting scheduled. ${result['notified_to'] ?? 0} user(s) notified.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['message'] ?? 'Unable to schedule meeting.'}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Meetings',
      trailing: IconButton(
        tooltip: 'Schedule meeting',
        icon: const Icon(Icons.add_circle_rounded),
        color: _CeoDashboardState._cyan,
        onPressed: () async {
          final data = await _future;
          if (!mounted) return;
          await _openSchedule(data);
        },
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            );
          }
          final items = snapshot.data!['meetings'] is List
              ? snapshot.data!['meetings'] as List
              : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              if (items.isEmpty)
                _GlassCard(
                  child: Center(
                    child: Text(
                      'No meetings found',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              ...items.map((item) {
                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                return _MeetingTile(
                  _displayText(map['title'], fallback: 'Meeting'),
                  '${_displayText(map['date_label'])} ${_displayText(map['time_label'])}'
                      .trim(),
                  _displayText(
                    map['location'],
                    fallback: _displayText(map['meeting_type'], fallback: '-'),
                  ),
                  _CeoDashboardState._cyan,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileSettingsPage extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final String fallbackEmail;
  final VoidCallback onLogout;

  const _ProfileSettingsPage({
    required this.userId,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.onLogout,
  });

  @override
  State<_ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<_ProfileSettingsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CeoService().fetchProfile(widget.userId);
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Profile & Settings',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildProfile(
              context,
              const <String, dynamic>{},
              loading: true,
            );
          }
          if (snapshot.hasError) {
            return _buildProfile(
              context,
              const <String, dynamic>{},
              warning: 'Backend profile is unavailable. Showing login profile.',
            );
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final profile = _stringMap(data['profile']);
          return _buildProfile(context, profile);
        },
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    Map<String, dynamic> profile, {
    bool loading = false,
    String warning = '',
  }) {
    final name = _displayText(
      profile['name'],
      fallback: widget.fallbackName.isEmpty ? 'CEO' : widget.fallbackName,
    );
    final role = _displayText(
      profile['designation_label'],
      fallback: _displayText(
        profile['role_label'],
        fallback: 'Chief Executive Officer',
      ),
    );
    final id = _displayText(profile['id'], fallback: widget.userId);
    final email = _displayText(
      profile['email'],
      fallback: widget.fallbackEmail,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        if (loading) ...[
          const LinearProgressIndicator(
            color: _CeoDashboardState._cyan,
            backgroundColor: Colors.transparent,
            minHeight: 2,
          ),
          const SizedBox(height: 12),
        ],
        if (warning.isNotEmpty) ...[
          _GlassCard(
            child: Text(warning, style: _CeoText.mutedFor(context, 12)),
          ),
          const SizedBox(height: 12),
        ],
        _ProfileHeader(
          firstName: name,
          email: id.isEmpty ? email : id,
          role: role,
          imageUrl: _displayText(profile['photo_url']),
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: loading ? 'Backend Profile (loading...)' : 'Backend Profile',
          children: [
            _SettingsRow(Icons.badge_outlined, 'Employee ID', id),
            _SettingsRow(Icons.mail_outline_rounded, 'Email', email),
            _SettingsRow(
              Icons.phone_outlined,
              'Phone',
              _displayText(profile['phone'], fallback: '-'),
            ),
            _SettingsRow(Icons.work_outline_rounded, 'Role', role),
            _SettingsRow(
              Icons.location_city_outlined,
              'Location',
              _displayText(profile['address'], fallback: '-'),
            ),
            _SettingsRow(
              Icons.verified_user_outlined,
              'Status',
              _displayText(profile['status'], fallback: '-'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: MyApp.themeNotifier,
          builder: (context, mode, _) => _SettingsGroup(
            title: 'Preferences',
            children: [
              const _SettingsRow(Icons.language_rounded, 'Language', 'English'),
              _SettingsRow(
                mode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                'Theme',
                mode == ThemeMode.dark ? 'Dark' : 'Light',
              ),
              const _SettingsRow(
                Icons.notifications_none_rounded,
                'Notification Settings',
                'Backend',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE1622),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: widget.onLogout,
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutConfirmPage extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutConfirmPage({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    return _CeoShell(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardBg,
                border: Border.all(color: border),
              ),
              child: Icon(Icons.logout_rounded, color: textPrimary, size: 42),
            ),
            const SizedBox(height: 22),
            Text(
              'Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBE1622),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onLogout,
                    child: const Text('Logout'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
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

class _CeoShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final Widget? trailing;
  final Widget? roleBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final double titleFontSize;

  const _CeoShell({
    required this.title,
    required this.child,
    this.showBack = true,
    this.trailing,
    this.roleBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.titleFontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final bgStart = ThemeConfig.getBgStart(context);
    final bgEnd = ThemeConfig.getBgEnd(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bgStart,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart, bgEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rightWidth = trailing == null
                        ? 48.0
                        : (constraints.maxWidth < 360 ? 88.0 : 96.0);
                    return Row(
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: showBack
                              ? IconButton(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 42,
                                    height: 42,
                                  ),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textPrimary,
                                    size: 18,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                )
                              : Builder(
                                  builder: (ctx) => IconButton(
                                    constraints: const BoxConstraints.tightFor(
                                      width: 42,
                                      height: 42,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Menu',
                                    icon: Icon(
                                      Icons.menu_rounded,
                                      color: textPrimary,
                                      size: 26,
                                    ),
                                    onPressed: () =>
                                        Scaffold.of(ctx).openDrawer(),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Semantics(
                            label: title,
                            header: true,
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: BitByteLogo(compact: true),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: rightWidth,
                          height: 42,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (trailing != null)
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: trailing,
                                  ),
                                ),
                              const _ThemeToggleButton(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (roleBar != null) roleBar!,
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          constraints: const BoxConstraints.tightFor(width: 40, height: 42),
          padding: EdgeInsets.zero,
          tooltip: isDark ? 'Light theme' : 'Dark theme',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: ThemeConfig.getTextPrimary(context),
            size: 20,
          ),
          onPressed: () {
            MyApp.themeNotifier.value = isDark
                ? ThemeMode.light
                : ThemeMode.dark;
          },
        );
      },
    );
  }
}

class _CeoRoleBasedBar extends StatelessWidget {
  final String role;
  final String userId;
  final ValueChanged<String> onChanged;

  const _CeoRoleBasedBar({
    required this.role,
    required this.userId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<String>(
            value: role,
            isExpanded: true,
            dropdownColor: bg,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _CeoDashboardState._cyan,
            ),
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            selectedItemBuilder: (context) {
              return const ['Employee', 'CEO'].map((_) {
                return Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: _CeoDashboardState._cyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Role Based',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(role, overflow: TextOverflow.ellipsis),
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
                value: 'CEO',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('CEO'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xF2071A2D);
    const borderColor = Color(0xFF123A5C);
    const textSecondary = _CeoDashboardState._muted;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final selectedIconColor = Theme.of(context).colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected
                            ? selectedIconColor
                            : _CeoDashboardState._muted,
                        size: 21,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? selectedColor : textSecondary,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> cards;
  const _MetricGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _GlassCard(
          onTap: card.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(card.icon, color: card.color, size: 20),
                  const Spacer(),
                  if (card.trend.isNotEmpty)
                    Text(
                      card.trend,
                      style: const TextStyle(
                        color: _CeoDashboardState._green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: _CeoText.mutedFor(context, 11)),
                  const SizedBox(height: 4),
                  Text(card.value, style: _CeoText.titleFor(context, 20)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trend;
  final List<double> bars;
  final List<String> labels;
  final Color color;
  final VoidCallback? onTap;

  const _ChartCard({
    required this.title,
    this.subtitle,
    this.trend,
    required this.bars,
    this.labels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: _CeoText.mutedFor(context, 11)),
          Row(
            children: [
              Expanded(
                child: Text(title, style: _CeoText.titleFor(context, 18)),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: const TextStyle(
                    color: _CeoDashboardState._green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.35), color],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (m) => Text(
                    m,
                    style: const TextStyle(
                      color: _CeoDashboardState._muted,
                      fontSize: 10,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ExecutiveProfileCard extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;
  final File? image;
  final String selectedRole;
  final VoidCallback onPickImage;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onRoleChanged;

  const _ExecutiveProfileCard({
    required this.firstName,
    required this.email,
    required this.userId,
    required this.image,
    required this.selectedRole,
    required this.onPickImage,
    required this.onOpenProfile,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onOpenProfile,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CeoProfileAvatar(image: image, radius: 30, onTap: onPickImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppGreeting.current().label},',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                    Text(
                      firstName,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.titleFor(context, 18),
                    ),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.mutedFor(context, 11),
                    ),
                    if (userId.isNotEmpty)
                      Text(
                        userId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _CeoDashboardState._cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                color: _CeoDashboardState._green,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _CeoDashboardState._cardAlt.withOpacity(0.82),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _CeoDashboardState._border),
            ),
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                dropdownColor: _CeoDashboardState._card,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _CeoDashboardState._purple,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CEO',
                    child: Text('Chief Executive Officer'),
                  ),
                  DropdownMenuItem(
                    value: 'Employee',
                    child: Text('Employee View'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onRoleChanged(value);
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CeoHomeHealthCard extends StatelessWidget {
  final int score;
  final String healthLabel;
  final String totalMembers;
  final String joinedThisMonth;
  final String presentToday;
  final String onLeave;
  final String growth;
  final List<double> trendPoints;
  final VoidCallback onTap;

  const _CeoHomeHealthCard({
    required this.score,
    required this.healthLabel,
    required this.totalMembers,
    required this.joinedThisMonth,
    required this.presentToday,
    required this.onLeave,
    required this.growth,
    required this.trendPoints,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = score >= 85
        ? _CeoDashboardState._green
        : score >= 70
        ? _CeoDashboardState._cyan
        : score >= 50
        ? _CeoDashboardState._gold
        : Colors.redAccent;
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Attendance Health Score')),
              Icon(
                Icons.close_rounded,
                color: ThemeConfig.getTextSecondary(context),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 9,
                        backgroundColor: _CeoDashboardState._border,
                        valueColor: const AlwaysStoppedAnimation(
                          _CeoDashboardState._cyan,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$score', style: _CeoText.titleFor(context, 30)),
                        Text('/100', style: _CeoText.mutedFor(context, 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthLabel,
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$growth vs last month',
                      style: _CeoText.mutedFor(context, 11),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: CustomPaint(
                        painter: _SparkLinePainter(
                          color: _CeoDashboardState._cyan,
                          values: trendPoints,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HealthStatTile(
                  'Total Members',
                  totalMembers,
                  '+$joinedThisMonth this month',
                  _CeoDashboardState._cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HealthStatTile(
                  'Present Today',
                  presentToday,
                  'Live',
                  _CeoDashboardState._green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HealthStatTile(
                  'On Leave',
                  onLeave,
                  'Approved today',
                  _CeoDashboardState._purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;

  const _HealthStatTile(this.label, this.value, this.caption, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 9),
          ),
          const SizedBox(height: 6),
          Text(value, style: _CeoText.titleFor(context, 18)),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  final Color color;
  final List<double> values;

  const _SparkLinePainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final points = List<Offset>.generate(values.length, (index) {
      final value = values[index].clamp(0, 100);
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height * (1 - value / 100);
      return Offset(x, y.clamp(2, size.height - 2));
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.values != values;
}

class _BusinessOverviewCard extends StatelessWidget {
  final String revenue;
  final String expenses;
  final String netProfit;
  final String payrollCost;
  final String growth;
  final List<double> bars;
  final List<String> labels;
  final VoidCallback onTap;

  const _BusinessOverviewCard({
    required this.revenue,
    required this.expenses,
    required this.netProfit,
    required this.payrollCost,
    required this.growth,
    required this.bars,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Business Overview')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _CeoDashboardState._green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _CeoDashboardState._green.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  growth,
                  style: const TextStyle(
                    color: _CeoDashboardState._green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FinancePill('Revenue', revenue, _CeoDashboardState._green),
              _FinancePill('Expenses', expenses, _CeoDashboardState._pink),
              _FinancePill('Net Profit', netProfit, _CeoDashboardState._cyan),
              _FinancePill(
                'Payroll Cost',
                payrollCost,
                _CeoDashboardState._gold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ExecutiveBarChart(
            bars: bars,
            labels: labels,
            color: _CeoDashboardState._green,
          ),
        ],
      ),
    );
  }
}

class _ExecutiveBarChart extends StatelessWidget {
  final List<double> bars;
  final List<String> labels;
  final Color color;

  const _ExecutiveBarChart({
    required this.bars,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars.isEmpty ? const <double>[0, 0, 0, 0, 0, 0] : bars;
    final visibleLabels = labels.length == visibleBars.length
        ? labels
        : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Month wise revenue', style: _CeoText.mutedFor(context, 11)),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: visibleBars.map((height) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: height <= 0 ? 8 : height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.28), color],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: visibleLabels
              .map(
                (label) => Text(label, style: _CeoText.mutedFor(context, 10)),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _FinancePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinancePill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 66) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHealthCard extends StatelessWidget {
  final int score;
  final String activeEmployees;
  final String pendingApprovals;

  const _CompanyHealthCard({
    required this.score,
    required this.activeEmployees,
    required this.pendingApprovals,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    backgroundColor: _CeoDashboardState._border,
                    valueColor: const AlwaysStoppedAnimation(
                      _CeoDashboardState._cyan,
                    ),
                  ),
                ),
                Text('$score%', style: _CeoText.titleFor(context, 20)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Company Health Score'),
                const SizedBox(height: 8),
                Text(
                  'Executive pulse based on workforce, approvals, and attendance.',
                  style: _CeoText.mutedFor(context, 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        'Active',
                        activeEmployees,
                        _CeoDashboardState._green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        'Pending',
                        pendingApprovals,
                        _CeoDashboardState._pink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 10),
          ),
        ],
      ),
    );
  }
}

class _WorkforceTodayCard extends StatelessWidget {
  final String present;
  final String absent;
  final String late;
  final String wfh;
  final String hybrid;
  final String onsite;

  const _WorkforceTodayCard({
    required this.present,
    required this.absent,
    required this.late,
    required this.wfh,
    required this.hybrid,
    required this.onsite,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Workforce Today'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.65,
            children: [
              _WorkforceTile(
                'Present',
                present,
                Icons.how_to_reg_rounded,
                _CeoDashboardState._green,
              ),
              _WorkforceTile(
                'Absent',
                absent,
                Icons.person_off_rounded,
                _CeoDashboardState._pink,
              ),
              _WorkforceTile(
                'Late Entry',
                late,
                Icons.schedule_rounded,
                _CeoDashboardState._gold,
              ),
              _WorkforceTile(
                'WFH',
                wfh,
                Icons.home_work_rounded,
                _CeoDashboardState._cyan,
              ),
              _WorkforceTile(
                'Hybrid',
                hybrid,
                Icons.sync_alt_rounded,
                _CeoDashboardState._purple,
              ),
              _WorkforceTile(
                'Onsite',
                onsite,
                Icons.apartment_rounded,
                _CeoDashboardState._green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkforceTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WorkforceTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _CeoDashboardState._cardAlt.withOpacity(0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 17),
          Text(value, style: _CeoText.titleFor(context, 15)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 10),
          ),
        ],
      ),
    );
  }
}

class _DepartmentPerformanceExecutiveCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onTap;

  const _DepartmentPerformanceExecutiveCard({
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final departments = items.take(4).toList();
    final totalEmployees = items.fold<int>(
      0,
      (total, item) => total + _departmentCount(item),
    );
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Department Overview',
                  style: _CeoText.titleFor(context, 18),
                ),
              ),
              TextButton.icon(
                onPressed: onTap,
                label: const Text('View All'),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: _CeoDashboardState._cyan,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Text(
            '${items.length} Departments · $totalEmployees Employees',
            style: _CeoText.mutedFor(context, 12),
          ),
          const SizedBox(height: 14),
          const Divider(color: _CeoDashboardState._border, height: 1),
          if (departments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No department data from backend',
                  style: _CeoText.mutedFor(context, 12),
                ),
              ),
            )
          else
            ...departments.indexed.map(
              (entry) => _DepartmentPerformanceRow(
                item: entry.$2,
                showDivider: entry.$1 < departments.length - 1,
              ),
            ),
          const SizedBox(height: 4),
          _DepartmentViewAllButton(onTap: onTap),
        ],
      ),
    );
  }
}

class _DepartmentPerformanceRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showDivider;

  const _DepartmentPerformanceRow({
    required this.item,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final title = _displayText(item['label'], fallback: 'Department');
    final count = _departmentCount(item);
    final strength = _departmentStrength(item);
    final colors = _departmentColors(title);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.$1.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: colors.$1.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.$1.withValues(alpha: 0.10),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(_departmentIcon(title), color: colors.$1, size: 28),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _CeoText.titleFor(context, 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$strength%',
                          style: _CeoText.titleFor(context, 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: _CeoDashboardState._muted,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$count Employees',
                          style: _CeoText.mutedFor(context, 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _DepartmentProgressBar(
                      value: strength / 100,
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: _CeoDashboardState._border, height: 1),
      ],
    );
  }
}

class _DepartmentProgressBar extends StatelessWidget {
  final double value;
  final (Color, Color) colors;

  const _DepartmentProgressBar({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: const Color(0xFF1A2C49),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.$1, colors.$2]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentViewAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DepartmentViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labelColor = ThemeConfig.getTextPrimary(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_CeoDashboardState._cyan, _CeoDashboardState._purple],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Material(
        color: ThemeConfig.getCardBg(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: _CeoDashboardState._cyan,
                ),
                const SizedBox(width: 9),
                Text(
                  'View All Departments',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _ApprovalsExecutiveCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onTap;
  final ValueChanged<Map<String, dynamic>> onItemTap;

  const _ApprovalsExecutiveCard({
    required this.items,
    required this.onTap,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum + (int.tryParse(_displayText(item['count'], fallback: '0')) ?? 0),
    );
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Approvals')),
              Text(
                '$total pending',
                style: const TextStyle(
                  color: _CeoDashboardState._pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No approval data from backend',
              style: _CeoText.mutedFor(context, 12),
            )
          else
            ...items.map(
              (item) => _ApprovalBadgeRow(
                _displayText(item['title'], fallback: 'Approval'),
                '${_displayText(item['count'], fallback: '0')} · ${_displayText(item['priority'], fallback: 'Clear')}',
                _priorityColor(_displayText(item['priority'])),
                () => onItemTap(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalBadgeRow extends StatelessWidget {
  final String title;
  final String priority;
  final Color color;
  final VoidCallback onTap;

  const _ApprovalBadgeRow(this.title, this.priority, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(Icons.approval_rounded, color: color, size: 17),
            const SizedBox(width: 9),
            Expanded(child: Text(title, style: _CeoText.titleFor(context, 12))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                priority,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: _CeoDashboardState._muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectOverviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ProjectOverviewCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Project Overview'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProjectMiniCard(
                  'Active',
                  _displayText(data['active'], fallback: '0'),
                  _CeoDashboardState._cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProjectMiniCard(
                  'Completed',
                  _displayText(data['completed'], fallback: '0'),
                  _CeoDashboardState._green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ProjectMiniCard(
                  'Delayed',
                  _displayText(data['delayed'], fallback: '0'),
                  _CeoDashboardState._gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProjectMiniCard(
                  'At Risk',
                  _displayText(data['at_risk'], fallback: '0'),
                  _CeoDashboardState._pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProjectMiniCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 11),
          ),
        ],
      ),
    );
  }
}

class _DashboardTextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DashboardTextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _CeoDashboardState._cyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_forward_rounded,
            color: _CeoDashboardState._cyan,
            size: 15,
          ),
        ],
      ),
    ),
  );
}

class _DashboardPill extends StatelessWidget {
  final String label;
  final Color color;

  const _DashboardPill(this.label, {this.color = _CeoDashboardState._muted});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: 0.65)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _LeadershipStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _LeadershipStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: color, size: 25),
      const SizedBox(width: 7),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: _CeoText.titleFor(context, 14)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _CeoText.mutedFor(context, 9),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DashboardDivider extends StatelessWidget {
  const _DashboardDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: _CeoDashboardState._border,
  );
}

class _RoleBadge extends StatelessWidget {
  final Map<String, dynamic> person;

  const _RoleBadge({required this.person});

  @override
  Widget build(BuildContext context) {
    final role = _displayText(person['role']).toLowerCase();
    final color = role == 'admin'
        ? _CeoDashboardState._purple
        : role == 'tl'
        ? _CeoDashboardState._cyan
        : _CeoDashboardState._green;
    final label = _displayText(
      person['role_label'],
      fallback: role.toUpperCase(),
    );
    return _DashboardPill(label, color: color);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
              .toUpperCase();
    final palette = const [
      _CeoDashboardState._cyan,
      _CeoDashboardState._purple,
      _CeoDashboardState._green,
      _CeoDashboardState._pink,
    ];
    final color = palette[name.hashCode.abs() % palette.length];
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CriticalAlertsCard extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback onTap;
  final ValueChanged<Map<String, dynamic>> onAlertTap;

  const _CriticalAlertsCard({
    required this.alerts,
    required this.onTap,
    required this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Critical Alerts')),
              if (alerts.isNotEmpty)
                _DashboardPill(
                  '${alerts.length} Urgent',
                  color: Colors.redAccent,
                ),
              const SizedBox(width: 8),
              _DashboardTextAction(label: 'View All', onTap: onTap),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Text(
              'No critical alerts from backend',
              style: _CeoText.mutedFor(context, 12),
            )
          else
            ...alerts.map(
              (alert) =>
                  _AlertRow(alert: alert, onTap: () => onAlertTap(alert)),
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  const _AlertRow({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = _displayText(alert['type']).toLowerCase();
    final color = type == 'payroll'
        ? _CeoDashboardState._gold
        : type == 'project'
        ? _CeoDashboardState._purple
        : Colors.redAccent;
    final icon = type == 'payroll'
        ? Icons.request_quote_outlined
        : type == 'project'
        ? Icons.trending_up_rounded
        : Icons.warning_amber_rounded;
    final action = type == 'payroll'
        ? 'Approve'
        : type == 'project'
        ? 'View'
        : 'Review';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 27),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayText(alert['title'], fallback: 'Alert'),
                          style: _CeoText.titleFor(context, 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayText(alert['subtitle']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _CeoText.mutedFor(context, 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      action,
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
          ),
        ),
      ),
    );
  }
}

class _BackendPeopleSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> people;
  final int departmentCount;
  final String emptyText;
  final VoidCallback onTap;
  final ValueChanged<Map<String, dynamic>> onPersonTap;

  const _BackendPeopleSection({
    required this.title,
    required this.people,
    required this.departmentCount,
    required this.emptyText,
    required this.onTap,
    required this.onPersonTap,
  });

  @override
  Widget build(BuildContext context) {
    final hrMembers = people
        .where((person) => _displayText(person['role']).toLowerCase() == 'hr')
        .toList();
    final visible = [
      ...hrMembers,
      ...people.where(
        (person) => _displayText(person['role']).toLowerCase() != 'hr',
      ),
    ].take(4).toList();
    final adminCount = people
        .where(
          (person) => _displayText(person['role']).toLowerCase() == 'admin',
        )
        .length;
    final tlCount = people
        .where((person) => _displayText(person['role']).toLowerCase() == 'tl')
        .length;
    final hrCount = hrMembers.length;
    final roleCount = people
        .map((person) => _displayText(person['role']))
        .where((role) => role.isNotEmpty)
        .toSet()
        .length;
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(title)),
              _DashboardPill('$roleCount Roles'),
              const SizedBox(width: 8),
              _DashboardTextAction(label: 'View All', onTap: onTap),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(
              color: _CeoDashboardState._cardAlt.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _CeoDashboardState._border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LeadershipStat(
                    icon: Icons.group_rounded,
                    value: '$adminCount',
                    label: 'Admins',
                    color: const Color(0xFF4895FF),
                  ),
                ),
                const _DashboardDivider(),
                Expanded(
                  child: _LeadershipStat(
                    icon: Icons.badge_rounded,
                    value: '$hrCount',
                    label: 'HR',
                    color: _CeoDashboardState._green,
                  ),
                ),
                const _DashboardDivider(),
                Expanded(
                  child: _LeadershipStat(
                    icon: Icons.groups_rounded,
                    value: '$tlCount',
                    label: 'Team Leads',
                    color: _CeoDashboardState._purple,
                  ),
                ),
                const _DashboardDivider(),
                Expanded(
                  child: _LeadershipStat(
                    icon: Icons.apartment_rounded,
                    value: '$departmentCount',
                    label: 'Departments',
                    color: _CeoDashboardState._cyan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text(emptyText, style: _CeoText.mutedFor(context, 12))
          else
            ...visible.map(
              (person) => InkWell(
                onTap: () => onPersonTap(person),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _AvatarBadge(
                        icon: Icons.person_rounded,
                        small: true,
                        imageUrl: _displayText(person['doc_passport_photo']),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayText(person['name'], fallback: 'Member'),
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.titleFor(context, 12),
                            ),
                            Text(
                              '${_displayText(person['role_label'], fallback: _displayText(person['role']))} · ${_displayText(person['department_label'], fallback: _displayText(person['department'], fallback: '-'))}',
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.mutedFor(context, 10),
                            ),
                            Text(
                              'Reports to: ${_displayText(person['working_under'], fallback: _displayText(person['reporting_to'], fallback: '-'))}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _CeoDashboardState._cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _displayText(person['id']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.mutedFor(context, 9),
                            ),
                            const SizedBox(height: 5),
                            _RoleBadge(person: person),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _CeoDashboardState._muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardSummaryList extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<_SummaryItem> items;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardSummaryList({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(12).toList();
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 10),
          if (visibleItems.isEmpty)
            Text(emptyText, style: _CeoText.mutedFor(context, 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleItems
                  .map((item) => _SummaryPill(item: item, color: color))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final _SummaryItem item;
  final Color color;

  const _SummaryPill({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.title, style: _CeoText.mutedFor(context, 11)),
          const SizedBox(width: 8),
          Text(
            item.value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final VoidCallback onTap;
  final VoidCallback onAddMember;
  final ValueChanged<Map<String, dynamic>> onMemberTap;

  const _RecentMembersList({
    required this.members,
    required this.onTap,
    required this.onAddMember,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(4).toList();
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Recently Created Members')),
              InkWell(
                onTap: onAddMember,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: _CeoDashboardState._cyan,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Add Member',
                        style: TextStyle(
                          color: _CeoDashboardState._cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _DashboardTextAction(label: 'View All', onTap: onTap),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleMembers.isEmpty)
            Text(
              'No members created yet',
              style: _CeoText.mutedFor(context, 12),
            )
          else
            ...visibleMembers.map(
              (member) => InkWell(
                onTap: () => onMemberTap(member),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _InitialsAvatar(
                        name: _displayText(member['name'], fallback: 'Member'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayText(member['name'], fallback: 'Member'),
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.titleFor(context, 13),
                            ),
                            Text(
                              '${_displayText(member['role_label'], fallback: 'Role')} ${_displayText(member['department_label']).isEmpty ? '' : '· ${_displayText(member['department_label'])}'}',
                              overflow: TextOverflow.ellipsis,
                              style: _CeoText.mutedFor(context, 11),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 88,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _displayText(member['id']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _CeoDashboardState._muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _DashboardPill(
                              _displayText(
                                member['status'],
                                fallback: 'Active',
                              ),
                              color:
                                  _displayText(
                                        member['status'],
                                      ).toLowerCase() ==
                                      'active'
                                  ? _CeoDashboardState._green
                                  : _CeoDashboardState._gold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _CeoDashboardState._muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DepartmentDonutCard extends StatelessWidget {
  const _DepartmentDonutCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Department Performance'),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(painter: _DonutPainter()),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  children: [
                    _LegendRow('HR', '28%', _CeoDashboardState._cyan),
                    _LegendRow('Finance', '25%', _CeoDashboardState._green),
                    _LegendRow('Sales', '20%', _CeoDashboardState._gold),
                    _LegendRow('IT', '17%', _CeoDashboardState._pink),
                    _LegendRow('Operations', '10%', _CeoDashboardState._purple),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentBarsCard extends StatelessWidget {
  const _DepartmentBarsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle('Department Wise Employees'),
          SizedBox(height: 12),
          _ProgressInfo('HR', '120', 0.42, _CeoDashboardState._green),
          _ProgressInfo('Finance', '200', 0.70, _CeoDashboardState._gold),
          _ProgressInfo('Sales', '300', 0.82, _CeoDashboardState._pink),
          _ProgressInfo('IT', '250', 0.74, _CeoDashboardState._purple),
          _ProgressInfo('Operations', '200', 0.64, _CeoDashboardState._cyan),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              ThemeConfig.isDark(context) ? 0.30 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: _CeoText.titleFor(context, 15));
}

class _MiniSummary extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final Color color;
  final VoidCallback? onTap;

  const _MiniSummary(
    this.title,
    this.value,
    this.caption,
    this.color, {
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _CeoText.mutedFor(context, 10),
          ),
          const SizedBox(height: 5),
          Text(value, style: _CeoText.titleFor(context, 16)),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _CeoDashboardState._cyan, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(label, style: _CeoText.mutedFor(context, 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconSquare(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _CeoText.titleFor(context, 14)),
                const SizedBox(height: 3),
                Text(subtitle, style: _CeoText.mutedFor(context, 11)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: ThemeConfig.getTextPrimary(context),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ApprovalTile(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) =>
      _ReportTile(icon, title, subtitle, color, onTap);
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _MenuTile(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : _CeoDashboardState._cyan;
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: danger
                        ? Colors.redAccent
                        : ThemeConfig.getTextPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: _CeoText.mutedFor(context, 11)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: danger ? Colors.redAccent : _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _CeoDashboardState._cardAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _CeoDashboardState._border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This Month',
              style: TextStyle(
                color: _CeoDashboardState._muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _CeoDashboardState._muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final String left;
  final String right;
  final bool rightActive;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  const _SegmentTabs({
    required this.left,
    required this.right,
    this.rightActive = false,
    this.onLeftTap,
    this.onRightTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: InkWell(
          onTap: onLeftTap,
          child: _TabLabel(left, active: !rightActive),
        ),
      ),
      Expanded(
        child: InkWell(
          onTap: onRightTap,
          child: _TabLabel(right, active: rightActive),
        ),
      ),
    ],
  );
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool active;
  const _TabLabel(this.text, {required this.active});

  @override
  Widget build(BuildContext context) {
    final inactive = ThemeConfig.getTextSecondary(context);
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: active
                ? ThemeConfig.loginButtonColor
                : _CeoDashboardState._muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: active ? null : inactive.withAlpha(70),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _DetailsCard({required this.rows});

  @override
  Widget build(BuildContext context) =>
      _GlassCard(child: Column(children: rows));
}

class _EmployeeOverviewPanel extends StatelessWidget {
  final _Employee employee;
  const _EmployeeOverviewPanel({required this.employee});

  @override
  Widget build(BuildContext context) {
    final attendancePercent = _displayText(
      employee.attendanceSummary['percentage'],
      fallback: '0',
    );
    return Column(
      children: [
        _DetailsCard(
          rows: [
            _InfoRow('Member ID', employee.id.isEmpty ? '-' : employee.id),
            _InfoRow('Email', employee.email),
            _InfoRow(
              'Phone',
              employee.phone.isEmpty ? '-' : maskMobileNumber(employee.phone),
            ),
            _InfoRow('Department', employee.department),
            _InfoRow('Role', employee.role),
            _InfoRow(
              'Designation',
              employee.designation.isEmpty
                  ? employee.role
                  : employee.designation,
            ),
            _InfoRow('Gender', employee.gender.isEmpty ? '-' : employee.gender),
            _InfoRow(
              'Date of Birth',
              employee.dob.isEmpty ? '-' : employee.dob,
            ),
            _InfoRow('Status', employee.status),
            _InfoRow(
              'Leader',
              employee.reportingTo.isEmpty ? '-' : employee.reportingTo,
            ),
            _InfoRow(
              'Created By',
              employee.createdBy.isEmpty ? '-' : employee.createdBy,
            ),
            _InfoRow('Source', employee.source),
          ],
        ),
        const SizedBox(height: 14),
        _DetailsCard(
          rows: [
            _InfoRow(
              'Door / Flat No.',
              employee.doorNo.isEmpty ? '-' : employee.doorNo,
            ),
            _InfoRow(
              'Street / Area',
              employee.street.isEmpty ? '-' : employee.street,
            ),
            _InfoRow('City', employee.city.isEmpty ? '-' : employee.city),
            _InfoRow('State', employee.state.isEmpty ? '-' : employee.state),
            _InfoRow(
              'Pincode',
              employee.pincode.isEmpty ? '-' : employee.pincode,
            ),
            _InfoRow(
              'Address',
              employee.address.isEmpty ? '-' : employee.address,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DetailsCard(
          rows: [
            _InfoRow('PAN Number', employee.pan.isEmpty ? '-' : employee.pan),
            _InfoRow(
              'Aadhar Number',
              employee.aadhar.isEmpty ? '-' : employee.aadhar,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniSummary(
                'Attendance',
                '$attendancePercent%',
                'This Month',
                _CeoDashboardState._green,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _MiniSummary(
                'Leave Balance',
                '12 Days',
                'Remaining',
                _CeoDashboardState._cyan,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _MiniSummary(
                'Performance',
                '4.5',
                'Rating',
                _CeoDashboardState._gold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmployeeAttendancePanel extends StatelessWidget {
  final _Employee employee;
  final Future<Map<String, dynamic>> attendanceFuture;

  const _EmployeeAttendancePanel({
    required this.employee,
    required this.attendanceFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: attendanceFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final summary = data['summary'] is Map
            ? Map<String, dynamic>.from(data['summary'] as Map)
            : employee.attendanceSummary;
        final records = data['records'] is List
            ? (data['records'] as List)
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : employee.attendanceRecords;

        if (snapshot.connectionState == ConnectionState.waiting &&
            records.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 28),
            child: Center(
              child: CircularProgressIndicator(color: _CeoDashboardState._cyan),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MiniSummary(
                    'Present',
                    _displayText(summary['present'], fallback: '0'),
                    'Last 30 days',
                    _CeoDashboardState._green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniSummary(
                    'Late',
                    _displayText(summary['late'], fallback: '0'),
                    'Last 30 days',
                    _CeoDashboardState._gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniSummary(
                    'Absent',
                    _displayText(summary['absent'], fallback: '0'),
                    'Last 30 days',
                    _CeoDashboardState._pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Text(
                      'No attendance records found for this employee',
                      style: _CeoText.mutedFor(context, 12),
                    ),
                  ),
                ),
              )
            else
              ...records.map((record) => _AttendanceRecordTile(record: record)),
          ],
        );
      },
    );
  }
}

class _CreatedMembersPanel extends StatelessWidget {
  final String title;
  final List<_Employee> members;

  const _CreatedMembersPanel({required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(title)),
              Text(
                '${members.length}',
                style: const TextStyle(
                  color: _CeoDashboardState._cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EmployeeTile(
                employee: member,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _EmployeeProfilePage(employee: member),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final status = _displayText(record['status'], fallback: '-');
    final color = status.toLowerCase().contains('late')
        ? _CeoDashboardState._gold
        : status.toLowerCase().contains('absent')
        ? _CeoDashboardState._pink
        : _CeoDashboardState._green;
    return _GlassCard(
      child: Row(
        children: [
          _IconSquare(icon: Icons.event_available_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayText(record['date'], fallback: '-'),
                  style: _CeoText.titleFor(context, 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'In ${_displayText(record['check_in'], fallback: '--')}  Out ${_displayText(record['check_out'], fallback: '--')}',
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _displayText(record['working_hours'], fallback: '--'),
                style: _CeoText.mutedFor(context, 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _CeoText.mutedFor(context, 12))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DecisionButton(
          'Approve',
          _CeoDashboardState._green,
          Icons.check_rounded,
        ),
        SizedBox(height: 10),
        _DecisionButton('Reject', Color(0xFFBE1622), Icons.close_rounded),
        SizedBox(height: 10),
        _DecisionButton(
          'Escalate',
          Colors.transparent,
          Icons.trending_up_rounded,
          outlined: true,
        ),
      ],
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;
  final VoidCallback? onPressed;
  const _DecisionButton(
    this.label,
    this.color,
    this.icon, {
    this.outlined = false,
    this.onPressed,
  });

  void _handlePressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label flow is not connected for this item.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isReject = normalized.contains('reject');
    final isApprove = normalized.contains('approve');
    final foreground = isReject
        ? const Color(0xFFB42318)
        : isApprove
        ? const Color(0xFF047857)
        : ThemeConfig.getTextPrimary(context);
    final background = isReject
        ? const Color(0xFFFFE4E6)
        : isApprove
        ? const Color(0xFFDCFCE7)
        : color.withAlpha(34);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConfig.getTextPrimary(context),
                side: BorderSide(color: ThemeConfig.getCardBorder(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _handlePressed(context),
              icon: Icon(icon, size: 18),
              label: Text(label),
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                elevation: 0,
                side: BorderSide(color: foreground.withAlpha(90)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _handlePressed(context),
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color color;
  const _PerformanceRow(this.label, this.value, this.trend, this.color);

  @override
  Widget build(BuildContext context) {
    final progress = double.tryParse(value.replaceAll('%', '')) ?? 0;
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: _CeoText.titleFor(context, 13)),
              ),
              Text(value, style: _CeoText.titleFor(context, 14)),
              const SizedBox(width: 8),
              Text(
                trend,
                style: const TextStyle(
                  color: _CeoDashboardState._green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 5,
              color: color,
              backgroundColor: _CeoDashboardState._border,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallPerformanceCard extends StatelessWidget {
  const _OverallPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  value: 0.84,
                  strokeWidth: 8,
                  color: _CeoDashboardState._green,
                  backgroundColor: _CeoDashboardState._border,
                ),
                Text('84%', style: _CeoText.titleFor(context, 18)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Overall Performance\n+10.2%',
              style: _CeoText.titleFor(context, 16).copyWith(height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final String city;
  final String score;
  final String trend;
  final String revenue;
  const _BranchTile(this.city, this.score, this.trend, this.revenue);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: _CeoText.titleFor(context, 14)),
                const SizedBox(height: 5),
                Text('Revenue', style: _CeoText.mutedFor(context, 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: _CeoText.titleFor(context, 16)),
              Text(
                trend,
                style: const TextStyle(
                  color: _CeoDashboardState._green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(revenue, style: _CeoText.mutedFor(context, 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String value;
  final String? percent;
  const _BudgetCard(this.title, this.value, this.percent);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _CeoText.mutedFor(context, 12)),
                const SizedBox(height: 8),
                Text(value, style: _CeoText.titleFor(context, 18)),
              ],
            ),
          ),
          if (percent != null)
            CircleAvatar(
              radius: 24,
              backgroundColor: _CeoDashboardState._border,
              child: Text(
                percent!,
                style: const TextStyle(
                  color: _CeoDashboardState._green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: ThemeConfig.getTextPrimary(context),
            ),
        ],
      ),
    );
  }
}

class _OrgChartCard extends StatelessWidget {
  final String ceoName;
  final List<Map<String, dynamic>> leaders;
  final int employeeCount;

  const _OrgChartCard({
    required this.ceoName,
    required this.leaders,
    required this.employeeCount,
  });

  @override
  Widget build(BuildContext context) {
    final visibleLeaders = leaders.isEmpty
        ? const <Map<String, dynamic>>[]
        : leaders.take(4).toList();
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _OrgNode(
            name: ceoName,
            role: 'CEO',
            color: _CeoDashboardState._gold,
            highlighted: true,
          ),
          Container(width: 1, height: 24, color: _CeoDashboardState._border),
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: _CeoDashboardState._border),
              ),
              Container(
                width: 1,
                height: 12,
                color: _CeoDashboardState._border,
              ),
              Expanded(
                child: Container(height: 1, color: _CeoDashboardState._border),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleLeaders.isEmpty)
            _OrgNode(
              name: 'Leadership',
              role: 'No leaders found',
              color: _CeoDashboardState._cyan,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: visibleLeaders.map((leader) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 70) / 2,
                  child: _OrgNode(
                    name: _displayText(leader['name'], fallback: 'Leader'),
                    role: _displayText(
                      leader['role_label'],
                      fallback: _displayText(
                        leader['role'],
                        fallback: 'Leader',
                      ),
                    ),
                    color: _CeoDashboardState._cyan,
                  ),
                );
              }).toList(),
            ),
          Container(width: 1, height: 24, color: _CeoDashboardState._border),
          _OrgNode(
            name: 'Employees',
            role: '$employeeCount Members',
            color: _CeoDashboardState._green,
          ),
        ],
      ),
    );
  }
}

class _OrgNode extends StatelessWidget {
  final String name;
  final String role;
  final Color color;
  final bool highlighted;

  const _OrgNode({
    required this.name,
    required this.role,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(highlighted ? 42 : 20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(highlighted ? 150 : 70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarBadge(icon: Icons.person_rounded, small: true),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 12),
                ),
                const SizedBox(height: 3),
                Text(
                  role,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _OrganizationSummaryCard extends StatelessWidget {
  final int departments;
  final int leaders;
  final int employees;

  const _OrganizationSummaryCard({
    required this.departments,
    required this.leaders,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Organization Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniSummary(
                  'Departments',
                  '$departments',
                  'Units',
                  _CeoDashboardState._gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSummary(
                  'Team Leads',
                  '$leaders',
                  'Leaders',
                  _CeoDashboardState._cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSummary(
                  'Employees',
                  '$employees',
                  'Members',
                  _CeoDashboardState._green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrgGroupTile extends StatelessWidget {
  final Map<String, dynamic> group;

  const _OrgGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final title = _displayText(
      group['label'],
      fallback: _displayText(group['role'], fallback: 'Team'),
    );
    final members = _mapList(group['members']);
    return _GlassCard(
      child: Row(
        children: [
          _IconSquare(
            icon: Icons.account_tree_rounded,
            color: _CeoDashboardState._purple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${members.length} people',
                  style: _CeoText.mutedFor(context, 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final _Employee employee;
  final VoidCallback onTap;
  const _EmployeeTile({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = employee.status.toLowerCase().contains('active')
        ? _CeoDashboardState._green
        : _CeoDashboardState._gold;
    final attendance =
        double.tryParse(
          _displayText(employee.attendanceSummary['percentage'], fallback: '0'),
        ) ??
        0;
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          _AvatarBadge(
            icon: Icons.person_rounded,
            small: true,
            imageUrl: employee.photoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.titleFor(context, 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${employee.role} - ${employee.department}',
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      employee.id,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CeoDashboardState._muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      employee.status.isEmpty ? 'Active' : employee.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value:
                      (attendance <= 0 ? 87 : attendance).clamp(0, 100) / 100,
                  strokeWidth: 3,
                  backgroundColor: _CeoDashboardState._border,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
                Text(
                  '${attendance <= 0 ? 87 : attendance.round()}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final VoidCallback? onTap;
  const _NotificationTile(
    this.icon,
    this.title,
    this.subtitle,
    this.time,
    this.color, {
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconSquare(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _CeoText.titleFor(context, 13)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _CeoText.mutedFor(context, 11),
                ),
              ],
            ),
          ),
          Text(time, style: _CeoText.mutedFor(context, 10)),
        ],
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final String title;
  final String time;
  final String place;
  final Color color;
  const _MeetingTile(this.title, this.time, this.place, this.color);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _CeoText.titleFor(context, 14)),
                const SizedBox(height: 5),
                Text(time, style: _CeoText.mutedFor(context, 11)),
                Text(place, style: _CeoText.mutedFor(context, 11)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: ThemeConfig.getTextPrimary(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _CeoText.mutedFor(context, 12)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _SettingsRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: ThemeConfig.getTextPrimary(context), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: _CeoText.titleFor(context, 13))),
          if (value != null)
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: _CeoText.mutedFor(context, 11),
              ),
            ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: _CeoDashboardState._muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String firstName;
  final String email;
  final String role;
  final String imageUrl;
  const _ProfileHeader({
    required this.firstName,
    required this.email,
    required this.role,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarBadge(icon: Icons.person_rounded, imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.titleFor(context, 18),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.mutedFor(context, 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: _CeoText.mutedFor(context, 11),
                    ),
                  ],
                ),
              ),
              const _StatusPill(
                label: 'Active',
                color: _CeoDashboardState._green,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProfileAction(
                  icon: Icons.email_rounded,
                  label: 'Contact by Email',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: email));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email address copied')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ProfileAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF09233C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _CeoDashboardState._border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 5),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: _CeoText.mutedFor(context, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String name;
  final String role;
  const _PersonCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) =>
      _ProfileHeader(firstName: name, email: 'Active request', role: role);
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: _CeoDashboardState._muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text('Search member...', style: _CeoText.mutedFor(context, 12)),
        ],
      ),
    );
  }
}

class _EmployeeSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const _EmployeeSearchBox({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search member...',
  });

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: ThemeConfig.getTextPrimary(context),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _CeoDashboardState._muted,
          size: 20,
        ),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _CeoDashboardState._cyan),
        ),
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip();

  @override
  Widget build(BuildContext context) {
    final days = const ['19', '20', '21', '22', '23', '24', '25'];
    return Row(
      children: days.map((day) {
        final active = day == '22';
        return Expanded(
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: active
                  ? _CeoDashboardState._purple
                  : _CeoDashboardState._card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _CeoDashboardState._border),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                color: Colors.white,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  const _ExportButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientButton(
            label: 'Download PDF',
            icon: Icons.picture_as_pdf_rounded,
            colors: const [_CeoDashboardState._purple, Color(0xFF6C1BFF)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientButton(
            label: 'Export Excel',
            icon: Icons.table_chart_rounded,
            colors: const [_CeoDashboardState._cyan, Color(0xFF009AAE)],
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onPressed;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed:
            onPressed ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label is not available for this report.'),
                ),
              );
            },
        icon: Icon(icon, color: Colors.white, size: 18),
        label: FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconSquare({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final IconData icon;
  final bool small;
  final String imageUrl;
  const _AvatarBadge({
    required this.icon,
    this.small = false,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 42.0 : 58.0;
    final hasImage = imageUrl.trim().isNotEmpty && imageUrl.trim() != 'null';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFD7B3), Color(0xFF8E4B2E)],
              ),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl.trim()),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: hasImage
          ? null
          : Icon(icon, color: Colors.white, size: small ? 22 : 30),
    );
  }
}

class _CeoProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _CeoProfileAvatar({
    required this.image,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: image == null ? null : FileImage(image!),
        child: image == null
            ? Icon(Icons.person_rounded, color: Colors.white, size: radius)
            : null,
      ),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  const _ProgressInfo(this.label, this.value, this.progress, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: _CeoText.mutedFor(context, 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: color,
                backgroundColor: _CeoDashboardState._border,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _CeoText.titleFor(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LegendRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: _CeoText.mutedFor(context, 11))),
          Text(value, style: _CeoText.titleFor(context, 11)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    const values = [0.28, 0.25, 0.20, 0.17, 0.10];
    const colors = [
      _CeoDashboardState._cyan,
      _CeoDashboardState._green,
      _CeoDashboardState._gold,
      _CeoDashboardState._pink,
      _CeoDashboardState._purple,
    ];
    var start = -1.57;
    for (var i = 0; i < values.length; i++) {
      paint.color = colors[i];
      final sweep = values[i] * 6.28;
      canvas.drawArc(rect, start, sweep - 0.08, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CeoText {
  static TextStyle title(double size) => TextStyle(
    color: Colors.white,
    fontSize: size,
    fontWeight: FontWeight.w800,
  );
  static TextStyle muted(double size) => TextStyle(
    color: _CeoDashboardState._muted,
    fontSize: size,
    fontWeight: FontWeight.w500,
  );

  static TextStyle titleFor(BuildContext context, double size) => TextStyle(
    color: ThemeConfig.getTextPrimary(context),
    fontSize: size,
    fontWeight: FontWeight.w800,
  );
  static TextStyle mutedFor(BuildContext context, double size) => TextStyle(
    color: ThemeConfig.getTextSecondary(context),
    fontSize: size,
    fontWeight: FontWeight.w500,
  );
}

String _displayText(dynamic value, {String fallback = ''}) {
  final text = value == null ? '' : '$value'.trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}

List<double> _chartBars(dynamic value) {
  if (value is! List) return const <double>[];
  return value
      .map((item) => double.tryParse('$item') ?? 0)
      .where((item) => item > 0)
      .toList();
}

List<double> _numberList(dynamic value) {
  if (value is! List) return const <double>[];
  return value.map((item) => double.tryParse('$item') ?? 0).toList();
}

List<String> _chartLabels(dynamic value) {
  if (value is! List) return const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final labels = value
      .map((item) => _displayText(item))
      .where((item) => item.isNotEmpty)
      .toList();
  return labels.isEmpty
      ? const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
      : labels;
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _mapFromDynamic(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _roleMembers(dynamic value) {
  final people = <Map<String, dynamic>>[];
  for (final roleGroup in _mapList(value)) {
    for (final member in _mapList(roleGroup['members'])) {
      people.add(member);
    }
  }
  return people;
}

List<Map<String, dynamic>> _peopleFromMaps(dynamic value) => _mapList(value);

_Employee _employeeFromMap(Map<String, dynamic> map) {
  return _Employee(
    _displayText(map['name'], fallback: 'Member'),
    _displayText(
      map['role_label'],
      fallback: _displayText(map['role'], fallback: 'Team Member'),
    ),
    _displayText(map['email']),
    _displayText(map['id']),
    department: _displayText(
      map['department_label'],
      fallback: _displayText(map['department'], fallback: '-'),
    ),
    status: _displayText(map['status'], fallback: '-'),
    phone: '${_displayText(map['country_code'])} ${_displayText(map['phone'])}'
        .trim(),
    gender: _displayText(map['gender']),
    dob: _displayText(map['dob']),
    designation: _displayText(
      map['designation_label'],
      fallback: _displayText(map['designation']),
    ),
    address: _displayText(map['address']),
    doorNo: _displayText(map['door_no']),
    street: _displayText(map['street']),
    city: _displayText(map['city']),
    state: _displayText(map['state']),
    pincode: _displayText(map['pincode']),
    pan: _displayText(map['pan']),
    aadhar: _displayText(map['aadhar']),
    createdBy: _displayText(map['created_by']),
    reportingTo: _displayText(
      map['working_under'],
      fallback: _displayText(
        map['reporting_to'],
        fallback: _displayText(map['reporting_tl']),
      ),
    ),
    source: _displayText(map['source'], fallback: 'CEO Created'),
    photoUrl: _displayText(map['doc_passport_photo']),
    attendanceSummary: map['attendance_summary'] is Map
        ? Map<String, dynamic>.from(map['attendance_summary'] as Map)
        : const <String, dynamic>{},
    attendanceRecords: map['recent_attendance'] is List
        ? (map['recent_attendance'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const <Map<String, dynamic>>[],
    children: _mapList(map['children']).map(_employeeFromMap).toList(),
  );
}

List<_SummaryItem> _summaryItems(
  dynamic value, {
  required String titleKey,
  required String valueKey,
}) {
  return _mapList(value)
      .map(
        (item) => _SummaryItem(
          _displayText(item[titleKey], fallback: '-'),
          _displayText(item[valueKey], fallback: '0'),
        ),
      )
      .where((item) => item.title != '-')
      .toList();
}

int _departmentCount(Map<String, dynamic> item) {
  return int.tryParse(_displayText(item['count'], fallback: '0')) ?? 0;
}

String _departmentDisplayName(Map<String, dynamic> item) {
  return _displayText(
    item['name'],
    fallback: _displayText(item['label'], fallback: 'Department'),
  );
}

String _departmentFilterLabel(_DepartmentFilter filter) {
  switch (filter) {
    case _DepartmentFilter.all:
      return 'All';
    case _DepartmentFilter.topPerforming:
      return 'Top Performing';
    case _DepartmentFilter.largestTeam:
      return 'Largest Team';
    case _DepartmentFilter.needsAttention:
      return 'Needs Attention';
  }
}

String _departmentEmptyText(_DepartmentFilter filter) {
  switch (filter) {
    case _DepartmentFilter.topPerforming:
      return 'No departments currently have 80% or higher performance';
    case _DepartmentFilter.needsAttention:
      return 'No departments currently need attention';
    case _DepartmentFilter.largestTeam:
    case _DepartmentFilter.all:
      return 'No departments match your search';
  }
}

int _departmentPerformance(Map<String, dynamic> item) {
  final value =
      int.tryParse(_displayText(item['performance'], fallback: '0')) ?? 0;
  return value.clamp(0, 100).toInt();
}

int _departmentStrength(Map<String, dynamic> item) {
  final value =
      int.tryParse(_displayText(item['strength'], fallback: '0')) ?? 0;
  return value.clamp(0, 100).toInt();
}

IconData _departmentIcon(String department) {
  final value = department.toLowerCase();
  if (value.contains('web')) return Icons.language_rounded;
  if (value.contains('mobile')) return Icons.phone_android_rounded;
  if (value.contains('ui') || value.contains('design')) {
    return Icons.palette_outlined;
  }
  if (value.contains('quality') || value.contains('testing')) {
    return Icons.science_outlined;
  }
  if (value.contains('marketing')) return Icons.campaign_outlined;
  if (value.contains('support')) return Icons.support_agent_rounded;
  if (value.contains('human') || value == 'hr') return Icons.groups_rounded;
  if (value.contains('management')) return Icons.business_center_outlined;
  if (value.contains('sales')) return Icons.trending_up_rounded;
  if (value.contains('intern')) return Icons.school_outlined;
  return Icons.apartment_rounded;
}

(Color, Color) _departmentColors(String department) {
  final value = department.toLowerCase();
  if (value.contains('mobile')) {
    return (const Color(0xFF3B9BFF), const Color(0xFF9B4DFF));
  }
  if (value.contains('ui') || value.contains('design')) {
    return (const Color(0xFFE44BC4), const Color(0xFFF06BFF));
  }
  if (value.contains('quality') || value.contains('testing')) {
    return (const Color(0xFF18C7B5), const Color(0xFF10E5D0));
  }
  if (value.contains('marketing')) {
    return (const Color(0xFFFF7B54), const Color(0xFFFFB347));
  }
  if (value.contains('management')) {
    return (const Color(0xFF9B72FF), const Color(0xFFCF76FF));
  }
  return (const Color(0xFF08C8F6), const Color(0xFF12E1DF));
}

Color _priorityColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('urgent') || normalized.contains('high'))
    return _CeoDashboardState._pink;
  if (normalized.contains('medium')) return _CeoDashboardState._gold;
  if (normalized.contains('clear')) return _CeoDashboardState._green;
  return _CeoDashboardState._cyan;
}

IconData _approvalCategoryIcon(String category) {
  switch (category) {
    case 'leave':
      return Icons.event_available_rounded;
    case 'claim':
      return Icons.receipt_long_rounded;
    case 'salary':
      return Icons.payments_rounded;
    case 'hiring':
      return Icons.person_add_alt_1_rounded;
    case 'budget':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.approval_rounded;
  }
}

IconData _reportIcon(String type) {
  switch (type) {
    case 'finance':
      return Icons.account_balance_wallet_rounded;
    case 'attendance':
      return Icons.calendar_month_rounded;
    case 'leave':
      return Icons.beach_access_rounded;
    case 'payroll':
      return Icons.payments_rounded;
    case 'performance':
      return Icons.query_stats_rounded;
    default:
      return Icons.badge_rounded;
  }
}

Color _reportColor(String type) {
  switch (type) {
    case 'finance':
      return _CeoDashboardState._purple;
    case 'attendance':
      return _CeoDashboardState._cyan;
    case 'leave':
      return _CeoDashboardState._pink;
    case 'payroll':
      return _CeoDashboardState._green;
    case 'performance':
      return _CeoDashboardState._gold;
    default:
      return _CeoDashboardState._green;
  }
}

IconData _notificationIcon(String type) {
  switch (type) {
    case 'success':
      return Icons.check_box_rounded;
    case 'warning':
      return Icons.warning_rounded;
    case 'error':
      return Icons.error_outline_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _notificationColor(String type) {
  switch (type) {
    case 'success':
      return _CeoDashboardState._green;
    case 'warning':
      return _CeoDashboardState._gold;
    case 'error':
      return Colors.redAccent;
    default:
      return _CeoDashboardState._cyan;
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _MetricData {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _MetricData(
    this.title,
    this.value,
    this.trend,
    this.icon,
    this.color, {
    this.onTap,
  });
}

class _SummaryItem {
  final String title;
  final String value;
  const _SummaryItem(this.title, this.value);
}

class _Employee {
  final String name;
  final String role;
  final String email;
  final String id;
  final String department;
  final String status;
  final String phone;
  final String gender;
  final String dob;
  final String designation;
  final String address;
  final String doorNo;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String pan;
  final String aadhar;
  final String createdBy;
  final String reportingTo;
  final String source;
  final String photoUrl;
  final Map<String, dynamic> attendanceSummary;
  final List<Map<String, dynamic>> attendanceRecords;
  final List<_Employee> children;

  const _Employee(
    this.name,
    this.role,
    this.email,
    this.id, {
    this.department = '-',
    this.status = '-',
    this.phone = '',
    this.gender = '',
    this.dob = '',
    this.designation = '',
    this.address = '',
    this.doorNo = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.pan = '',
    this.aadhar = '',
    this.createdBy = '',
    this.reportingTo = '',
    this.source = 'Employee',
    this.photoUrl = '',
    this.attendanceSummary = const {},
    this.attendanceRecords = const [],
    this.children = const [],
  });
}
