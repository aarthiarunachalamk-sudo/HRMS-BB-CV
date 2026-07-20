import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Superadmin/Create_admins.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Superadmin/sa_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const SuperAdminDashboard({
    super.key,
    required this.email,
    this.firstName = '',
    this.userId = '',
  });

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _dashboardRole = 'SuperAdmin';
  String _usersFocus = 'employees';
  String _workflowFocus = 'attendance';

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

  void _openCreateAdmins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAdminsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _SaColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.background,
        drawer: _buildDrawer(colors),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.background, colors.backgroundAlt],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(colors),
                if (_selectedIndex == 0)
                  _SuperAdminRoleBasedBar(
                    colors: colors,
                    email: widget.email,
                    role: _dashboardRole,
                    onChanged: (role) => setState(() => _dashboardRole = role),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _DashboardView(
                        colors: colors,
                        email: widget.email,
                        name: widget.firstName,
                        onOpenCreateUser: _openCreateAdmins,
                        onOpenSection: _setSection,
                        onOpenUsersFocus: _openUsersFocus,
                        onOpenWorkflowFocus: _openWorkflowFocus,
                      ),
                      _UsersView(
                        colors: colors,
                        onOpenCreateUser: _openCreateAdmins,
                        focus: _usersFocus,
                      ),
                      _WorkflowView(colors: colors, focus: _workflowFocus),
                      _ReportsView(colors: colors),
                      _SettingsView(
                        colors: colors,
                        email: widget.email,
                        onLogout: _logout,
                      ),
                    ],
                  ),
                ),
                _BottomNav(
                  colors: colors,
                  selectedIndex: _selectedIndex,
                  onTap: _setSection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setSection(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openUsersFocus(String focus) {
    setState(() {
      _usersFocus = focus;
      _selectedIndex = 1;
    });
  }

  void _openWorkflowFocus(String focus) {
    setState(() {
      _workflowFocus = focus;
      _selectedIndex = 2;
    });
  }

  Widget _buildTopBar(_SaColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(colors.isDark ? 0.78 : 0.94),
        border: Border(bottom: BorderSide(color: colors.border)),
        boxShadow: colors.shadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(Icons.menu_rounded, color: colors.text, size: 26),
            tooltip: 'Menu',
          ),
          const BitByteLogo(compact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppGreeting.current().label},',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.firstName.trim().isEmpty
                      ? 'Super Admin'
                      : widget.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => _setSection(4),
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: colors.text,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              colors.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: colors.primary,
            ),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(_SaColors colors) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: colors.surface,
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
                        color: colors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.muted,
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
                        colors: [colors.primary, colors.teal, colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: colors.isDark
                          ? const Color(0xFF031A2C)
                          : const Color(0xFFF2F7FF),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: colors.primary,
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
                          widget.firstName.trim().isEmpty
                              ? 'Super Admin'
                              : widget.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Super Administrator',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.muted,
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
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 4),

              // ── Nav items ─────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _setSection(0);
                      },
                    ),
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.people_alt_rounded,
                      title: 'User Management',
                      onTap: () {
                        Navigator.pop(context);
                        _setSection(1);
                      },
                    ),
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.account_tree_outlined,
                      title: 'Workflow',
                      onTap: () {
                        Navigator.pop(context);
                        _setSection(2);
                      },
                    ),
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.insert_chart_outlined_rounded,
                      title: 'Reports',
                      onTap: () {
                        Navigator.pop(context);
                        _setSection(3);
                      },
                    ),
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Create Admins',
                      onTap: () {
                        Navigator.pop(context);
                        _openCreateAdmins();
                      },
                    ),
                    _DrawerActionTile(
                      colors: colors,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        _setSection(4);
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),

              // ── Theme toggle ──────────────────────────────────
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Icon(
                  colors.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: colors.primary,
                  size: 20,
                ),
                title: Text(
                  colors.isDark ? 'Light Mode' : 'Dark Mode',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleTheme();
                },
              ),

              // ── Logout ────────────────────────────────────────
              _DrawerActionTile(
                colors: colors,
                icon: Icons.logout_rounded,
                title: 'Logout',
                danger: true,
                onTap: _logout,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperAdminRoleBasedBar extends StatelessWidget {
  final _SaColors colors;
  final String email;
  final String role;
  final ValueChanged<String> onChanged;

  const _SuperAdminRoleBasedBar({
    required this.colors,
    required this.email,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
          boxShadow: colors.shadow,
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<String>(
            value: role,
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
              return const ['Employee', 'SuperAdmin'].map((_) {
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
                      child: Text(role, overflow: TextOverflow.ellipsis),
                    ),
                    if (email.trim().isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                value: 'SuperAdmin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('SuperAdmin'),
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

class _DashboardView extends StatelessWidget {
  final _SaColors colors;
  final String email;
  final String name;
  final VoidCallback onOpenCreateUser;
  final ValueChanged<int> onOpenSection;
  final ValueChanged<String> onOpenUsersFocus;
  final ValueChanged<String> onOpenWorkflowFocus;

  const _DashboardView({
    required this.colors,
    required this.email,
    this.name = '',
    required this.onOpenCreateUser,
    required this.onOpenSection,
    required this.onOpenUsersFocus,
    required this.onOpenWorkflowFocus,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load data. Please try again.',
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }
        final data = snapshot.data!;
        return _ScreenScroll(
          colors: colors,
          children: [
            _IdentityCard(colors: colors, email: email, name: name),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _MetricCard(
                  colors: colors,
                  title: 'Total Employees',
                  value: '${data['total_employees']}',
                  icon: Icons.groups_rounded,
                  color: colors.primary,
                  onTap: () => onOpenUsersFocus('employees'),
                ),
                _MetricCard(
                  colors: colors,
                  title: 'Total Departments',
                  value: '${data['total_departments']}',
                  icon: Icons.apartment_rounded,
                  color: colors.blue,
                  onTap: () => onOpenUsersFocus('departments'),
                ),
                _MetricCard(
                  colors: colors,
                  title: 'Active Users',
                  value: '${data['active_users']}',
                  icon: Icons.verified_user_outlined,
                  color: colors.success,
                  onTap: () => onOpenUsersFocus('active_users'),
                ),
                _MetricCard(
                  colors: colors,
                  title: 'Attendance',
                  value: '${data['attendance']}',
                  icon: Icons.calendar_month_outlined,
                  color: colors.teal,
                  onTap: () => onOpenWorkflowFocus('attendance'),
                ),
                _MetricCard(
                  colors: colors,
                  title: 'Pending Leaves',
                  value: '${data['pending_leaves']}',
                  icon: Icons.event_busy_outlined,
                  color: colors.warning,
                  onTap: () => onOpenWorkflowFocus('leaves'),
                ),
                _MetricCard(
                  colors: colors,
                  title: 'Open Tasks',
                  value: '${data['open_tasks']}',
                  icon: Icons.task_alt_rounded,
                  color: colors.danger,
                  onTap: () => onOpenWorkflowFocus('tasks'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionHeader(
              colors: colors,
              title: 'Analytics Overview',
              action: 'View All',
            ),
            const SizedBox(height: 10),
            _AnalyticsCard(colors: colors, data: data),
            const SizedBox(height: 14),
            _SectionHeader(colors: colors, title: 'Quick Actions'),
            const SizedBox(height: 10),
            _QuickActionGrid(
              colors: colors,
              onOpenCreateUser: onOpenCreateUser,
              onOpenSection: onOpenSection,
            ),
          ],
        );
      },
    );
  }
}

class _UsersView extends StatelessWidget {
  final _SaColors colors;
  final VoidCallback onOpenCreateUser;
  final String focus;

  const _UsersView({
    required this.colors,
    required this.onOpenCreateUser,
    required this.focus,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load data. Please try again.',
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }
        final data = snapshot.data!;
        final rawEmployees = data['employees'];
        final rawUsers = data['users'];
        final rawRows = focus == 'employees'
            ? (rawEmployees is List && rawEmployees.isNotEmpty
                  ? rawEmployees
                  : rawUsers)
            : rawUsers;
        final users = rawRows is List
            ? rawRows.map((item) {
                final user = Map<String, dynamic>.from(item as Map);
                return _PersonData(
                  '${user['name']}',
                  '${user['subtitle'] ?? user['role'] ?? user['designation'] ?? ''}',
                  '${user['detail'] ?? user['email'] ?? ''}',
                  '${user['trailing'] ?? user['employee_id'] ?? user['id'] ?? ''}',
                  '${user['status'] ?? ''}',
                );
              }).toList()
            : <_PersonData>[];
        final visibleUsers = focus == 'active_users'
            ? users
                  .where((user) => user.status.toLowerCase() == 'active')
                  .toList()
            : users;
        final title = focus == 'departments'
            ? 'Department Management'
            : focus == 'active_users'
            ? 'Active Users'
            : 'Employee Directory';

        return _ScreenScroll(
          colors: colors,
          children: [
            _PageHeader(
              colors: colors,
              title: title,
              icon: focus == 'departments'
                  ? Icons.apartment_rounded
                  : Icons.group_outlined,
            ),
            const SizedBox(height: 10),
            if (focus == 'departments') ...[
              _DepartmentsCard(colors: colors, data: data),
            ] else ...[
              _SearchBar(
                colors: colors,
                hint:
                    'Search ${focus == 'employees' ? 'employees' : 'users'}...',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FilterChipBox(
                      colors: colors,
                      text: 'All Departments',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChipBox(colors: colors, text: 'All Roles'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (visibleUsers.isEmpty)
                _EmptyPanelText(
                  colors: colors,
                  text: focus == 'employees'
                      ? 'No employee data found in backend'
                      : 'No user data found in backend',
                )
              else
                ...visibleUsers.map(
                  (user) => _UserTile(colors: colors, user: user),
                ),
              const SizedBox(height: 12),
              _PrimaryActionButton(
                colors: colors,
                label: 'Create User',
                icon: Icons.add_rounded,
                onTap: onOpenCreateUser,
              ),
              if (focus == 'active_users') ...[
                const SizedBox(height: 18),
                _RolesPermissionsCard(colors: colors, data: data),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _WorkflowView extends StatelessWidget {
  final _SaColors colors;
  final String focus;

  const _WorkflowView({required this.colors, required this.focus});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }
        final data = snapshot.data!;
        return _ScreenScroll(
          colors: colors,
          children: [
            _PageHeader(
              colors: colors,
              title: 'Workflow',
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 12),
            if (focus == 'attendance') ...[
              _AttendanceCard(colors: colors, data: data),
            ] else if (focus == 'leaves') ...[
              _LeaveManagementCard(colors: colors, data: data),
            ] else if (focus == 'tasks') ...[
              _TaskManagementCard(colors: colors, data: data),
            ] else ...[
              _AttendanceCard(colors: colors, data: data),
              const SizedBox(height: 14),
              _LeaveManagementCard(colors: colors, data: data),
              const SizedBox(height: 14),
              _TaskManagementCard(colors: colors, data: data),
              const SizedBox(height: 14),
              _MeetingManagementCard(colors: colors, data: data),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _ReportsView extends StatelessWidget {
  final _SaColors colors;

  const _ReportsView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SaService().fetchDashboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }
        final data = snapshot.data!;
        return _ScreenScroll(
          colors: colors,
          children: [
            _PageHeader(
              colors: colors,
              title: 'Reports & Analytics',
              icon: Icons.insert_chart_outlined_rounded,
            ),
            const SizedBox(height: 12),
            _PayrollOverviewCard(colors: colors, data: data),
            const SizedBox(height: 14),
            _ReportListCard(colors: colors, data: data),
          ],
        );
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  final _SaColors colors;
  final String email;
  final VoidCallback onLogout;

  const _SettingsView({
    required this.colors,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _ScreenScroll(
      colors: colors,
      children: [
        _PageHeader(
          colors: colors,
          title: 'Notifications & Settings',
          icon: Icons.settings_outlined,
        ),
        const SizedBox(height: 12),
        _NotificationsCard(colors: colors),
        const SizedBox(height: 14),
        _ProfileCard(colors: colors, email: email, onLogout: onLogout),
        const SizedBox(height: 14),
        _SettingsCard(colors: colors),
      ],
    );
  }
}

class _ScreenScroll extends StatelessWidget {
  final _SaColors colors;
  final List<Widget> children;

  const _ScreenScroll({required this.colors, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: children,
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final _SaColors colors;
  final String email;
  final String name;

  const _IdentityCard({
    required this.colors,
    required this.email,
    this.name = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: colors.logoBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: const BitByteLogo(compact: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppGreeting.current().label},',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                Text(
                  name.trim().isEmpty ? 'Super Admin' : name,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: colors.primarySoft,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.colors,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(11),
          decoration: _box(colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _IconBadge(colors: colors, icon: icon, color: color),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withAlpha(colors.isDark ? 34 : 20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: colors.success,
                      size: 12,
                    ),
                  ),
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
                      color: colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _AnalyticsCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _AnalyticsCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final present =
        double.tryParse('${data['present']}'.replaceAll(',', '')) ?? 0;
    final absent =
        double.tryParse('${data['absent']}'.replaceAll(',', '')) ?? 0;
    final late = double.tryParse('${data['late']}'.replaceAll(',', '')) ?? 0;
    final maxValue = [present, absent, late, 1].reduce((a, b) => a > b ? a : b);
    final bars = [
      present,
      absent,
      late,
    ].map((value) => (value / maxValue).clamp(0.05, 1.0)).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  colors: colors,
                  title: 'Attendance',
                  value: '${data['present']}',
                  color: colors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  colors: colors,
                  title: 'Absent',
                  value: '${data['absent']}',
                  color: colors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  colors: colors,
                  title: 'Late',
                  value: '${data['late']}',
                  color: colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (index) {
                final color = index % 3 == 0
                    ? colors.teal
                    : index % 3 == 1
                    ? colors.blue
                    : colors.warning;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FractionallySizedBox(
                      heightFactor: bars[index],
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withAlpha(110), color],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final _SaColors colors;
  final VoidCallback onOpenCreateUser;
  final ValueChanged<int> onOpenSection;

  const _QuickActionGrid({
    required this.colors,
    required this.onOpenCreateUser,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        Icons.person_add_alt_1_rounded,
        'Create User',
        onOpenCreateUser,
      ),
      _ActionData(Icons.groups_2_outlined, 'Users', () => onOpenSection(1)),
      _ActionData(
        Icons.account_tree_outlined,
        'Workflow',
        () => onOpenSection(2),
      ),
      _ActionData(
        Icons.insert_chart_outlined_rounded,
        'Reports',
        () => onOpenSection(3),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.55,
      children: actions
          .map(
            (action) => InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _box(colors).copyWith(color: colors.subtle),
                child: Row(
                  children: [
                    _IconBadge(
                      colors: colors,
                      icon: action.icon,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RolesPermissionsCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _RolesPermissionsCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final roles = _list(data['roles']);
    return _Panel(
      colors: colors,
      title: 'Role & Permission',
      child: roles.isEmpty
          ? _EmptyPanelText(
              colors: colors,
              text: 'No role permission data found in backend',
            )
          : Column(
              children: roles
                  .take(8)
                  .map(
                    (role) => _SimpleRow(
                      colors: colors,
                      icon: Icons.badge_outlined,
                      title: '${role['name'] ?? 'Role'}',
                      value: '${role['filled_positions'] ?? 0} Users',
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

List<Map<String, dynamic>> _list(Object? value) {
  return ((value as List?) ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

void _openDetail(
  BuildContext context,
  String title,
  Map<dynamic, dynamic> data,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _RecordDetailScreen(
        title: title,
        data: Map<String, dynamic>.from(data),
      ),
    ),
  );
}

class _RecordDetailScreen extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _RecordDetailScreen({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = _SaColors.of(context);
    final entries = data.entries
        .where((entry) => '${entry.value}'.trim().isNotEmpty)
        .toList();
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _Panel(
            colors: colors,
            title: title,
            child: entries.isEmpty
                ? _EmptyPanelText(colors: colors, text: 'No detail data')
                : Column(
                    children: entries.map((entry) {
                      return _SimpleRow(
                        colors: colors,
                        icon: Icons.info_outline_rounded,
                        title: entry.key.replaceAll('_', ' ').toUpperCase(),
                        value: '${entry.value}',
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentsCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _DepartmentsCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    var departments = _list(data['departments']);
    if (departments.isEmpty) {
      final grouped = <String, int>{};
      for (final employee in _list(data['employees'])) {
        final department = '${employee['department'] ?? ''}'.trim();
        if (department.isEmpty) continue;
        grouped[department] = (grouped[department] ?? 0) + 1;
      }
      departments = grouped.entries
          .map((entry) => {'name': entry.key, 'employees': entry.value})
          .toList();
    }
    return _Panel(
      colors: colors,
      title: 'Department Management',
      child: departments.isEmpty
          ? _EmptyPanelText(
              colors: colors,
              text: 'No department data found in backend',
            )
          : Column(
              children: departments
                  .take(8)
                  .map(
                    (dept) => _SimpleRow(
                      colors: colors,
                      icon: Icons.apartment_outlined,
                      title: '${dept['name'] ?? 'Department'}',
                      value: '${dept['employees'] ?? 0} Employees',
                      onTap: () => _showDepartmentEmployees(context, dept),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _showDepartmentEmployees(
    BuildContext context,
    Map<String, dynamic> dept,
  ) {
    final name = '${dept['name'] ?? ''}'.trim();
    var employees = _list(data['employees']).where((employee) {
      final department = '${employee['department'] ?? ''}'.trim().toLowerCase();
      return department == name.toLowerCase();
    }).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Department Employees' : name,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${employees.length} working employees',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: employees.map((employee) {
                    final person = _PersonData(
                      '${employee['name'] ?? 'Employee'}',
                      '${employee['designation'] ?? employee['role'] ?? ''}',
                      '${employee['email'] ?? ''}',
                      '${employee['employee_id'] ?? employee['id'] ?? ''}',
                      '${employee['status'] ?? 'Active'}',
                    );
                    return _UserTile(colors: colors, user: person);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _AttendanceCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final attendance = Map<String, dynamic>.from(
      (data['attendance_detail'] as Map?) ?? const {},
    );
    final details = attendance;
    final total = int.tryParse('${details['total'] ?? 0}') ?? 0;
    return _Panel(
      colors: colors,
      title: 'Attendance Monitoring',
      child: total == 0
          ? _EmptyPanelText(
              colors: colors,
              text: 'No attendance data found in backend',
            )
          : Column(
              children: [
                _LegendRow(
                  colors: colors,
                  label: 'Present',
                  value: '${details['present'] ?? 0}',
                  color: colors.primary,
                  onTap: () =>
                      _openDetail(context, 'Present Attendance', details),
                ),
                _LegendRow(
                  colors: colors,
                  label: 'Absent',
                  value: '${details['absent'] ?? 0}',
                  color: colors.danger,
                  onTap: () =>
                      _openDetail(context, 'Absent Attendance', details),
                ),
                _LegendRow(
                  colors: colors,
                  label: 'Late',
                  value: '${details['late'] ?? 0}',
                  color: colors.warning,
                  onTap: () => _openDetail(context, 'Late Attendance', details),
                ),
              ],
            ),
    );
  }
}

class _LeaveManagementCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _LeaveManagementCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final leaves = _list(data['leaves']);
    return _Panel(
      colors: colors,
      title: 'Leave Management',
      child: leaves.isEmpty
          ? _EmptyPanelText(colors: colors, text: 'No leave requests found')
          : Column(
              children: leaves.take(10).map((leave) {
                return _SimpleRow(
                  colors: colors,
                  icon: Icons.event_busy_outlined,
                  title:
                      '${leave['name'] ?? leave['employee_id'] ?? 'Employee'}',
                  value:
                      '${leave['leave_type'] ?? ''} • ${leave['status'] ?? ''}',
                  onTap: () => _openDetail(context, 'Leave Request', leave),
                );
              }).toList(),
            ),
    );
  }
}

class _TaskManagementCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _TaskManagementCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final tasks = _list(data['tasks']);
    return _Panel(
      colors: colors,
      title: 'Task Management',
      child: tasks.isEmpty
          ? _EmptyPanelText(
              colors: colors,
              text: 'No task data found in backend',
            )
          : Column(
              children: tasks
                  .take(6)
                  .map(
                    (task) => _SimpleRow(
                      colors: colors,
                      icon: Icons.task_alt_rounded,
                      title: '${task['title'] ?? 'Task'}',
                      value: '${task['status'] ?? ''}',
                      onTap: () => _openDetail(context, 'Task Details', task),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _MeetingManagementCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _MeetingManagementCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final meetings = _list(data['meetings']);
    return _Panel(
      colors: colors,
      title: 'Meeting Management',
      child: meetings.isEmpty
          ? _EmptyPanelText(
              colors: colors,
              text: 'No meeting data found in backend',
            )
          : Column(
              children: meetings
                  .take(6)
                  .map(
                    (meeting) => _SimpleRow(
                      colors: colors,
                      icon: Icons.calendar_month_outlined,
                      title: '${meeting['title'] ?? 'Meeting'}',
                      value: '${meeting['status'] ?? ''}',
                      onTap: () =>
                          _openDetail(context, 'Meeting Details', meeting),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _PayrollOverviewCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _PayrollOverviewCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final payroll = Map<String, dynamic>.from(
      (data['payroll'] as Map?) ?? const {},
    );
    final paid = '${payroll['employees_paid'] ?? 0}';
    return _Panel(
      colors: colors,
      title: 'Payroll Overview',
      child: paid == '0'
          ? _EmptyPanelText(
              colors: colors,
              text: 'No payroll data found in backend',
            )
          : Column(
              children: [
                _LegendRow(
                  colors: colors,
                  label: 'Payroll Processed',
                  value: 'Rs. ${payroll['processed'] ?? 0}',
                  color: colors.success,
                  onTap: () =>
                      _openDetail(context, 'Payroll Processed', payroll),
                ),
                _LegendRow(
                  colors: colors,
                  label: 'Employees Paid',
                  value: paid,
                  color: colors.warning,
                  onTap: () => _openDetail(context, 'Employees Paid', payroll),
                ),
                _LegendRow(
                  colors: colors,
                  label: 'Average Salary',
                  value: 'Rs. ${payroll['average_salary'] ?? 0}',
                  color: colors.blue,
                  onTap: () => _openDetail(context, 'Average Salary', payroll),
                ),
              ],
            ),
    );
  }
}

class _ReportListCard extends StatelessWidget {
  final _SaColors colors;
  final Map<String, dynamic> data;

  const _ReportListCard({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final reports = _list(data['reports']);
    return _Panel(
      colors: colors,
      title: 'Reports & Analytics',
      child: reports.isEmpty
          ? _EmptyPanelText(
              colors: colors,
              text: 'No reports data found in backend',
            )
          : Column(
              children: reports
                  .take(6)
                  .map(
                    (report) => _SimpleRow(
                      colors: colors,
                      icon: Icons.description_outlined,
                      title: '${report['report_type'] ?? 'Report'}',
                      value: '${report['status'] ?? ''}',
                      onTap: () =>
                          _openDetail(context, 'Report Details', report),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  final _SaColors colors;

  const _NotificationsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      colors: colors,
      title: 'Notifications & Announcements',
      child: _EmptyPanelText(colors: colors, text: 'No notifications found'),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _SaColors colors;
  final String email;
  final VoidCallback onLogout;

  const _ProfileCard({
    required this.colors,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      colors: colors,
      title: 'Profile',
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primarySoft,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Super Admin',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SimpleRow(
            colors: colors,
            icon: Icons.badge_outlined,
            title: 'Employee ID',
            value: 'EMP001',
          ),
          _SimpleRow(
            colors: colors,
            icon: Icons.work_outline_rounded,
            title: 'Designation',
            value: 'Super Administrator',
          ),
          _SimpleRow(
            colors: colors,
            icon: Icons.apartment_outlined,
            title: 'Department',
            value: 'Management',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.danger,
              side: BorderSide(color: colors.danger.withAlpha(120)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final _SaColors colors;

  const _SettingsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final settings = const [
      'Company Profile',
      'Theme Settings',
      'Security Settings',
      'Backup & Restore',
      'Notification Settings',
      'App Version 1.0.0',
    ];
    return _Panel(
      colors: colors,
      title: 'Settings',
      child: Column(
        children: settings
            .map(
              (setting) => _SimpleRow(
                colors: colors,
                icon: Icons.settings_outlined,
                title: setting,
                value: '',
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final Widget child;

  const _Panel({
    required this.colors,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(colors: colors, title: title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final IconData icon;

  const _PageHeader({
    required this.colors,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(colors: colors, icon: icon, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String? action;

  const _SectionHeader({
    required this.colors,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: TextStyle(
              color: colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final _SaColors colors;
  final String hint;

  const _SearchBar({required this.colors, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _box(colors).copyWith(color: colors.input),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.muted, size: 18),
          const SizedBox(width: 8),
          Text(hint, style: TextStyle(color: colors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilterChipBox extends StatelessWidget {
  final _SaColors colors;
  final String text;

  const _FilterChipBox({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _box(colors).copyWith(color: colors.input),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _EmptyPanelText extends StatelessWidget {
  final _SaColors colors;
  final String text;

  const _EmptyPanelText({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: _box(colors).copyWith(color: colors.row),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _SaColors colors;
  final _PersonData user;

  const _UserTile({required this.colors, required this.user});

  @override
  Widget build(BuildContext context) {
    final active = user.trailing == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(colors).copyWith(color: colors.row),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primarySoft,
            child: Text(
              user.name.substring(0, 1),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  user.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (active ? colors.success : colors.danger).withAlpha(
                colors.isDark ? 36 : 22,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.trailing,
              style: TextStyle(
                color: active ? colors.success : colors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final _SaColors colors;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _SimpleRow({
    required this.colors,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            _IconBadge(
              colors: colors,
              icon: icon,
              color: colors.primary,
              compact: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: colors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String subtitle;
  final IconData icon;

  const _DepartmentTile({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _IconBadge(colors: colors, icon: icon, color: colors.teal),
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
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert_rounded, color: colors.muted, size: 18),
        ],
      ),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  final _SaColors colors;
  final _PersonData leave;

  const _LeaveTile({required this.colors, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primarySoft,
                child: Text(
                  leave.name.substring(0, 1),
                  style: TextStyle(color: colors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.name,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      leave.subtitle,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      leave.detail,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                leave.trailing,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              _SmallButton(
                colors: colors,
                label: 'Approve',
                color: colors.success,
              ),
              const SizedBox(width: 8),
              _SmallButton(
                colors: colors,
                label: 'Reject',
                color: colors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskMiniCard {
  final String title;
  final String team;
  final String priority;

  const _TaskMiniCard({
    required this.title,
    required this.team,
    required this.priority,
  });

  Widget buildWith(_SaColors colors) {
    final color = priority == 'High'
        ? colors.danger
        : priority == 'Medium'
        ? colors.warning
        : colors.success;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  final _SaColors colors;

  const _CalendarStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final active = index == 3;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.row,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? colors.primary : colors.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${20 + index}',
                  style: TextStyle(
                    color: active ? Colors.white : colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                  style: TextStyle(
                    color: active ? Colors.white70 : colors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String time;
  final String status;

  const _MeetingTile({
    required this.colors,
    required this.title,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(time, style: TextStyle(color: colors.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: status == 'Ongoing' ? colors.success : colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final _SaColors colors;

  const _LineChart({required this.colors});

  @override
  Widget build(BuildContext context) {
    final bars = [0.38, 0.5, 0.78, 0.48, 0.42, 0.66, 0.82, 0.73, 0.96];
    return SizedBox(
      height: 110,
      child: CustomPaint(
        painter: _SparklinePainter(colors: colors, values: bars),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final _SaColors colors;
  final List<double> values;

  const _SparklinePainter({required this.colors, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colors.border
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = colors.primary.withAlpha(40)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = colors.primary;
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] * size.height);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.values != values;
  }
}

class _ReportChip extends StatelessWidget {
  final _SaColors colors;
  final String label;

  const _ReportChip({required this.colors, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final _SaColors colors;
  final String label;
  final IconData icon;
  final Color color;

  const _ExportButton({
    required this.colors,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: colors.row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationTile({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _IconBadge(
            colors: colors,
            icon: Icons.notifications_none_rounded,
            color: colors.primary,
            compact: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: colors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final _SaColors colors;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _LegendRow({
    required this.colors,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: colors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final _SaColors colors;
  final String title;
  final String value;
  final Color color;

  const _MiniStat({
    required this.colors,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(colors.isDark ? 26 : 14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final _SaColors colors;
  final String label;
  final Color color;

  const _SmallButton({
    required this.colors,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final _SaColors colors;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.colors,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final _SaColors colors;
  final IconData icon;
  final Color color;
  final bool compact;

  const _IconBadge({
    required this.colors,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(colors.isDark ? 40 : 20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: compact ? 16 : 20),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final _SaColors colors;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.colors,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavData(Icons.dashboard_outlined, 'Dashboard', 0),
      _NavData(Icons.group_outlined, 'Users', 1),
      _NavData(Icons.account_tree_outlined, 'Workflow', 2),
      _NavData(Icons.insert_chart_outlined_rounded, 'Reports', 3),
      _NavData(Icons.settings_outlined, 'Settings', 4),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: items.map((item) {
          final active = item.index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(item.index),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 18 : 0,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Icon(
                      item.icon,
                      color: active ? colors.primary : colors.muted,
                      size: 19,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: active ? colors.primary : colors.muted,
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

class _DrawerActionTile extends StatelessWidget {
  final _SaColors colors;
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? colors.danger : colors.primary;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? colors.danger : colors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  final int index;

  const _NavData(this.icon, this.label, this.index);
}

class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionData(this.icon, this.label, this.onTap);
}

class _PersonData {
  final String name;
  final String subtitle;
  final String detail;
  final String trailing;
  final String status;

  const _PersonData(
    this.name,
    this.subtitle,
    this.detail,
    this.trailing,
    this.status,
  );
}

class _LabelValue {
  final String label;
  final String value;

  const _LabelValue(this.label, this.value);
}

class _DepartmentData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DepartmentData(this.title, this.subtitle, this.icon);
}

class _NotificationData {
  final String title;
  final String subtitle;
  final String time;

  const _NotificationData(this.title, this.subtitle, this.time);
}

BoxDecoration _box(_SaColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: colors.border),
    boxShadow: colors.shadow,
  );
}

class _SaColors {
  final bool isDark;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color subtle;
  final Color row;
  final Color input;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Color primarySoft;
  final Color logoBg;
  final Color success;
  final Color danger;
  final Color warning;
  final Color teal;
  final Color blue;
  final Color purple;
  final List<BoxShadow> shadow;

  const _SaColors({
    required this.isDark,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.subtle,
    required this.row,
    required this.input,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.primarySoft,
    required this.logoBg,
    required this.success,
    required this.danger,
    required this.warning,
    required this.teal,
    required this.blue,
    required this.purple,
    required this.shadow,
  });

  factory _SaColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SaColors(
        isDark: true,
        background: Color(0xFF001525),
        backgroundAlt: Color(0xFF05243A),
        surface: Color(0xFF052035),
        subtle: Color(0xFF08283F),
        row: Color(0xFF07263D),
        input: Color(0xFF031A2C),
        text: Color(0xFFF8FAFC),
        muted: Color(0xFF8DA1B7),
        border: Color(0xFF17405A),
        primary: Color(0xFF19D3E8),
        primarySoft: Color(0x3319D3E8),
        logoBg: Color(0xFF092C45),
        success: Color(0xFF22C55E),
        danger: Color(0xFFEF4444),
        warning: Color(0xFFF59E0B),
        teal: Color(0xFF14B8A6),
        blue: Color(0xFF3B82F6),
        purple: Color(0xFF8B5CF6),
        shadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      );
    }
    return _SaColors(
      isDark: false,
      background: const Color(0xFFF6F9FF),
      backgroundAlt: const Color(0xFFEFF5FF),
      surface: Colors.white,
      subtle: const Color(0xFFF8FBFF),
      row: const Color(0xFFFFFFFF),
      input: const Color(0xFFF8FBFF),
      text: const Color(0xFF0F172A),
      muted: const Color(0xFF64748B),
      border: const Color(0xFFE1E8F3),
      primary: const Color(0xFF1677FF),
      primarySoft: const Color(0x1F1677FF),
      logoBg: const Color(0xFFF2F7FF),
      success: const Color(0xFF16A34A),
      danger: const Color(0xFFEF4444),
      warning: const Color(0xFFF59E0B),
      teal: const Color(0xFF14B8A6),
      blue: const Color(0xFF3B82F6),
      purple: const Color(0xFF8B5CF6),
      shadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
