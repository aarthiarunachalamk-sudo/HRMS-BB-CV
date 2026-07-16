import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_attendance_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_employees_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_flow_screens.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_home_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_leave_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_meetings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_palette.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_dashboard.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────
//  Bottom nav items
// ─────────────────────────────────────────────────────────────
enum _AdminTab { dashboard, employees, attendance, leave, meetings }

const List<List<IconData>> _tabIcons = [
  [Icons.dashboard_outlined, Icons.dashboard_rounded],
  [Icons.people_outline_rounded, Icons.people_rounded],
  [Icons.calendar_month_outlined, Icons.calendar_month_rounded],
  [Icons.beach_access_outlined, Icons.beach_access_rounded],
  [Icons.event_outlined, Icons.event_rounded],
];
const _tabLabels = ['Dashboard', 'Employees', 'Attendance', 'Leave', 'Meetings'];

// ─────────────────────────────────────────────────────────────
//  Role options
// ─────────────────────────────────────────────────────────────
enum _AdminRole { admin, employee }

// ─────────────────────────────────────────────────────────────
//  Root widget
// ─────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const AdminDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _AdminTab _tab = _AdminTab.dashboard;
  _AdminRole _role = _AdminRole.admin;
  File? _profileImage;

  // ── helpers ─────────────────────────────────────────────────
  void _logout() => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

  void _toggleTheme() {
    MyApp.themeNotifier.value =
        MyApp.themeNotifier.value == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
    setState(() {});
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _profileImage = File(picked.path));
  }

  void _setTab(_AdminTab t) {
    Navigator.of(context).maybePop();
    setState(() => _tab = t);
  }

  void _openAdminPage(Widget page) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  // ── role switch ──────────────────────────────────────────────
  void _switchRole(_AdminRole role) {
    if (role == _AdminRole.employee) {
      // Push EmployeeDashboard on top — admin can come back via back button
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeDashboard(
            email: widget.email,
            firstName: widget.firstName,
            userId: widget.userId,
            roleSwitchLabel: 'Admin',
            roleSwitchBuilder: (_) => AdminDashboard(
              email: widget.email,
              firstName: widget.firstName,
              userId: widget.userId,
            ),
          ),
        ),
      );
    } else {
      setState(() => _role = _AdminRole.admin);
    }
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: c.bg,
        drawer: _buildDrawer(c),
        body: Container(
          decoration: BoxDecoration(gradient: c.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────
                _TopBar(
                  c: c,
                  title: _tabLabels[_tab.index],
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onTheme: _toggleTheme,
                ),

                // ── Role-based dropdown ──────────────────────
                _RoleDropdown(
                  c: c,
                  role: _role,
                  onChanged: _switchRole,
                ),

                // ── Page content ─────────────────────────────
                Expanded(child: _buildPage(c)),

                // ── Bottom nav ───────────────────────────────
                _BottomNav(c: c, tab: _tab, onTap: _setTab),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(AdminPalette c) {
    switch (_tab) {
      case _AdminTab.dashboard:
        return AdminHomeScreen(
          firstName: widget.firstName,
          email: widget.email,
          userId: widget.userId,
          onOpenEmployees: () => setState(() => _tab = _AdminTab.employees),
          onOpenAttendance: () => setState(() => _tab = _AdminTab.attendance),
          onOpenLeaves: () => setState(() => _tab = _AdminTab.leave),
          onOpenMeetings: () => setState(() => _tab = _AdminTab.meetings),
        );
      case _AdminTab.employees:
        return AdminEmployeesScreen(userId: widget.userId);
      case _AdminTab.attendance:
        return AdminAttendanceScreen(userId: widget.userId);
      case _AdminTab.leave:
        return AdminLeaveScreen(userId: widget.userId);
      case _AdminTab.meetings:
        return AdminMeetingsScreen(userId: widget.userId);
    }
  }

  // ── Drawer ───────────────────────────────────────────────────
  Widget _buildDrawer(AdminPalette c) {
    final name =
        widget.firstName.isEmpty ? 'Admin' : widget.firstName;

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: c.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white24,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const Text('Admin',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(widget.userId,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _DrawerTile(
                    c: c,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    selected: _tab == _AdminTab.dashboard,
                    onTap: () => _setTab(_AdminTab.dashboard),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.people_rounded,
                    label: 'Employees',
                    selected: _tab == _AdminTab.employees,
                    onTap: () => _setTab(_AdminTab.employees),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.calendar_month_rounded,
                    label: 'Attendance',
                    selected: _tab == _AdminTab.attendance,
                    onTap: () => _setTab(_AdminTab.attendance),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.beach_access_rounded,
                    label: 'Leave Requests',
                    selected: _tab == _AdminTab.leave,
                    onTap: () => _setTab(_AdminTab.leave),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.event_rounded,
                    label: 'Meetings',
                    selected: _tab == _AdminTab.meetings,
                    onTap: () => _setTab(_AdminTab.meetings),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    selected: false,
                    onTap: () => _openAdminPage(AdminTasksScreen(userId: widget.userId)),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.devices_rounded,
                    label: 'Assets',
                    selected: false,
                    onTap: () => _openAdminPage(AdminAssetsScreen(userId: widget.userId)),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.insert_chart_outlined_rounded,
                    label: 'Reports',
                    selected: false,
                    onTap: () => _openAdminPage(AdminReportsScreen(userId: widget.userId)),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    selected: false,
                    onTap: () => _openAdminPage(AdminNotificationsScreen(userId: widget.userId)),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: false,
                    onTap: () => _openAdminPage(AdminSettingsScreen(userId: widget.userId)),
                  ),
                  _DrawerTile(
                    c: c,
                    icon: Icons.account_circle_rounded,
                    label: 'Profile',
                    selected: false,
                    onTap: () => _openAdminPage(AdminProfileScreen(userId: widget.userId)),
                  ),
                ],
              ),
            ),

            Divider(color: c.border),

            // Theme toggle
            ListTile(
              leading: Icon(
                c.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: c.primary,
              ),
              title: Text(
                c.isDark ? 'Light Mode' : 'Dark Mode',
                style: TextStyle(
                    color: c.text, fontWeight: FontWeight.w600),
              ),
              onTap: _toggleTheme,
            ),

            // Logout
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700)),
              onTap: () => _openAdminPage(const AdminLogoutConfirmScreen()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AdminPalette c;
  final String title;
  final VoidCallback onMenu;
  final VoidCallback onTheme;

  const _TopBar({
    required this.c,
    required this.title,
    required this.onMenu,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(children: [
        IconButton(
          onPressed: onMenu,
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
                color: c.text, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: onTheme,
          icon: Icon(
            c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: c.primary,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Role-based dropdown  (Admin ↔ Employee view)
// ─────────────────────────────────────────────────────────────
class _RoleDropdown extends StatelessWidget {
  final AdminPalette c;
  final _AdminRole role;
  final ValueChanged<_AdminRole> onChanged;

  const _RoleDropdown({
    required this.c,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: DropdownButtonHideUnderline(
          child: AppDropdownButton<_AdminRole>(
            value: role,
            isExpanded: true,
            dropdownColor: c.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.primary),
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w800),
            // What shows when closed
            selectedItemBuilder: (context) => _AdminRole.values.map((_) {
              return Row(children: [
                Icon(Icons.manage_accounts_outlined,
                    color: c.primary, size: 18),
                const SizedBox(width: 8),
                Text('Role View',
                    style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    role == _AdminRole.admin ? 'Admin' : 'Employee',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ]);
            }).toList(),
            // Drop-down items
            items: [
              DropdownMenuItem(
                value: _AdminRole.admin,
                child: Row(children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: c.primary, size: 18),
                  const SizedBox(width: 10),
                  Text('Admin',
                      style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w700)),
                ]),
              ),
              DropdownMenuItem(
                value: _AdminRole.employee,
                child: Row(children: [
                  Icon(Icons.person_outline_rounded,
                      color: c.green, size: 18),
                  const SizedBox(width: 10),
                  Text('Employee',
                      style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Bottom navigation bar
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final AdminPalette c;
  final _AdminTab tab;
  final ValueChanged<_AdminTab> onTap;

  const _BottomNav({
    required this.c,
    required this.tab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
      child: Row(
        children: _AdminTab.values.map((t) {
          final selected = t == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(t),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected
                          ? _tabIcons[t.index][1]
                          : _tabIcons[t.index][0],
                      color: selected ? c.primary : c.muted,
                      size: 20,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        _tabLabels[t.index],
                        style: TextStyle(
                          color: selected ? c.primary : c.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────
//  Drawer tile
// ─────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final AdminPalette c;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.c,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor:
            selected ? c.primary.withValues(alpha: 0.12) : Colors.transparent,
        leading: Icon(icon,
            color: selected ? c.primary : c.muted, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? c.primary : c.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
