import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Admin_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/CEO_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Employee_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Finance_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/HR_dadhborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/ITTeam_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/MD_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Manager-dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/MarketingTeam_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/TL_dashborad.dart';

class RoleDashboard extends StatefulWidget {
  const RoleDashboard({super.key});

  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  int _selectedRoleIndex = 0;
  int _selectedTabIndex = 0;
  bool _rememberLastRole = true;
  late String _clockLabel;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockLabel = _formatClock(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockLabel = _formatClock(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  static String _formatClock(DateTime now) {
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  final List<_RoleOption> _roles = const [
    _RoleOption(
      key: 'admin',
      title: 'Admin',
      subtitle: 'Admin Operations',
      icon: Icons.admin_panel_settings_outlined,
      accent: Color(0xFF38BDF8),
    ),
    _RoleOption(
      key: 'ceo',
      title: 'CEO',
      subtitle: 'Chief Executive',
      icon: Icons.workspace_premium_outlined,
      accent: Color(0xFF4B8DFF),
    ),
    _RoleOption(
      key: 'md',
      title: 'MD',
      subtitle: 'Managing Director',
      icon: Icons.business_center_outlined,
      accent: Color(0xFF7C3AED),
    ),
    _RoleOption(
      key: 'director',
      title: 'Director',
      subtitle: 'Leadership',
      icon: Icons.apartment_outlined,
      accent: Color(0xFF06B6D4),
    ),
    _RoleOption(
      key: 'hr',
      title: 'HR',
      subtitle: 'Human Resources',
      icon: Icons.badge_outlined,
      accent: Color(0xFF8B5CF6),
    ),
    _RoleOption(
      key: 'tl',
      title: 'Team Lead',
      subtitle: 'TL',
      icon: Icons.groups_2_outlined,
      accent: Color(0xFFEC4899),
    ),
    _RoleOption(
      key: 'employee',
      title: 'Employee',
      subtitle: 'Staff Member',
      icon: Icons.person_outline_rounded,
      accent: Color(0xFF22C55E),
    ),
    _RoleOption(
      key: 'finance',
      title: 'Finance',
      subtitle: 'Accounts & Payroll',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFFF59E0B),
    ),
    _RoleOption(
      key: 'manager',
      title: 'Manager',
      subtitle: 'Team Manager',
      icon: Icons.manage_accounts_outlined,
      accent: Color(0xFF0EA5E9),
    ),
    _RoleOption(
      key: 'marketing',
      title: 'Marketing',
      subtitle: 'Marketing Team',
      icon: Icons.campaign_outlined,
      accent: Color(0xFF14B8A6),
    ),
  ];

  final _RoleOption _itDepartment = const _RoleOption(
    key: 'it',
    title: 'IT Department',
    subtitle: 'Technology & Infrastructure',
    icon: Icons.dns_outlined,
    accent: Color(0xFF3B82F6),
  );

  bool get _isDark => MyApp.themeNotifier.value == ThemeMode.dark;

  void _toggleTheme() {
    MyApp.themeNotifier.value = _isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  void _openSelectedDashboard() {
    _openDashboard(_roles[_selectedRoleIndex]);
  }

  void _openDashboard(_RoleOption role) {
    // RoleDashboard is a dev-only role-switcher screen.
    // It is not reachable from real login — real login routes directly
    // to the appropriate dashboard with live user data.
    // Passing empty strings here causes each dashboard to show its
    // loading/empty state rather than any fake names or IDs.
    const email = '';
    const firstName = '';
    const userId = '';

    final Widget dashboard = switch (role.key) {
      'admin' => AdminDashboard(email: email, firstName: firstName, userId: userId),
      'ceo' => CeoDashboard(email: email, firstName: firstName, userId: userId),
      'md' => MdDashboard(email: email, firstName: firstName, userId: userId),
      'director' => MdDashboard(email: email, firstName: firstName, userId: userId),
      'hr' => HrDashboard(email: email, firstName: firstName, userId: userId),
      'tl' => TLDashboard(email: email, firstName: firstName, userId: userId),
      'employee' => EmployeeDashboard(email: email, firstName: firstName, userId: userId),
      'finance' => FinanceDashboard(email: email, firstName: firstName, userId: userId),
      'manager' => ManagerDashboard(email: email, firstName: firstName, userId: userId),
      'it' => ITTeamDashboard(email: email, firstName: firstName, userId: userId),
      'marketing' => MarketingTeamDashboard(email: email, firstName: firstName, userId: userId),
      _ => EmployeeDashboard(email: email, firstName: firstName, userId: userId),
    };

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _RoleDashboardColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(colors),
                      const SizedBox(height: 22),
                      _buildHeader(colors),
                      const SizedBox(height: 24),
                      _buildRoleGrid(colors),
                      const SizedBox(height: 14),
                      _RoleWideCard(
                        role: _itDepartment,
                        colors: colors,
                        isSelected: false,
                        onTap: () => _openDashboard(_itDepartment),
                      ),
                      const SizedBox(height: 20),
                      _buildRememberCard(colors),
                      const SizedBox(height: 14),
                      _buildOpenButton(),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(_RoleDashboardColors colors) {
    return Row(
      children: [
        Text(
          _clockLabel,
          style: TextStyle(
            color: colors.title,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _toggleTheme,
          icon: Icon(
            _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: colors.title,
            size: 20,
          ),
          tooltip: 'Toggle Theme',
        ),
        Icon(Icons.signal_cellular_alt_rounded, color: colors.title, size: 18),
        const SizedBox(width: 10),
        Icon(Icons.wifi_rounded, color: colors.title, size: 18),
        const SizedBox(width: 10),
        Icon(Icons.battery_full_rounded, color: colors.title, size: 18),
      ],
    );
  }

  Widget _buildHeader(_RoleDashboardColors colors) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: colors.headerIconBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.headerIconBorder, width: 1.5),
          ),
          child: Icon(
            Icons.dashboard_customize_outlined,
            color: colors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Choose Dashboard Role',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.title,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Switch roles and manage from one place',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.subtitle,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(_RoleDashboardColors colors) {
    return GridView.builder(
      itemCount: _roles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.16,
      ),
      itemBuilder: (context, index) {
        return _RoleCard(
          role: _roles[index],
          colors: colors,
          isSelected: index == _selectedRoleIndex,
          onTap: () {
            setState(() {
              _selectedRoleIndex = index;
            });
          },
        );
      },
    );
  }

  Widget _buildRememberCard(_RoleDashboardColors colors) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.softBorder),
        boxShadow: colors.shadow,
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_border_rounded, color: colors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Remember my last role',
              style: TextStyle(
                color: colors.body,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _rememberLastRole,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF22C55E),
            inactiveThumbColor: colors.subtitle,
            inactiveTrackColor: colors.softBorder,
            onChanged: (value) {
              setState(() {
                _rememberLastRole = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpenButton() {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withAlpha(70),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _openSelectedDashboard,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Open Selected Dashboard',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
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

  Widget _buildBottomNavigation(_RoleDashboardColors colors) {
    final items = const [
      _BottomNavItem(Icons.dashboard_outlined, 'Dashboard'),
      _BottomNavItem(Icons.grid_view_rounded, 'Roles'),
      _BottomNavItem(Icons.apps_rounded, 'Others'),
      _BottomNavItem(Icons.insert_chart_outlined_rounded, 'Reports'),
      _BottomNavItem(Icons.more_horiz_rounded, 'More'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.navBackground,
        border: Border(top: BorderSide(color: colors.softBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == _selectedTabIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? colors.primary : colors.navMuted,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? colors.primary : colors.navMuted,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 6 : 0,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleOption role;
  final _RoleDashboardColors colors;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? role.accent : role.accent.withAlpha(145),
              width: isSelected ? 1.8 : 1.4,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: role.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoleIconBadge(role: role, colors: colors),
                    const SizedBox(height: 10),
                    Text(
                      role.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.subtitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleWideCard extends StatelessWidget {
  final _RoleOption role;
  final _RoleDashboardColors colors;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleWideCard({
    required this.role,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: role.accent.withAlpha(isSelected ? 230 : 160),
              width: isSelected ? 1.8 : 1.4,
            ),
          ),
          child: Row(
            children: [
              _RoleIconBadge(role: role, colors: colors, size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      role.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.subtitle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleIconBadge extends StatelessWidget {
  final _RoleOption role;
  final _RoleDashboardColors colors;
  final double size;

  const _RoleIconBadge({
    required this.role,
    required this.colors,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: role.accent.withAlpha(colors.isDark ? 55 : 18),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(role.icon, color: role.accent, size: size * 0.42),
    );
  }
}

class _RoleOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _RoleOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem(this.icon, this.label);
}

class _RoleDashboardColors {
  final bool isDark;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color navBackground;
  final Color title;
  final Color body;
  final Color subtitle;
  final Color primary;
  final Color navMuted;
  final Color softBorder;
  final Color headerIconBackground;
  final Color headerIconBorder;
  final List<BoxShadow> shadow;

  const _RoleDashboardColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.navBackground,
    required this.title,
    required this.body,
    required this.subtitle,
    required this.primary,
    required this.navMuted,
    required this.softBorder,
    required this.headerIconBackground,
    required this.headerIconBorder,
    required this.shadow,
  });

  factory _RoleDashboardColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const _RoleDashboardColors(
        isDark: true,
        background: Color(0xFF0B1220),
        surface: Color(0xFF142033),
        cardBackground: Color(0xFF111E31),
        navBackground: Color(0xFF0E1728),
        title: Color(0xFFF8FAFC),
        body: Color(0xFFE5ECF8),
        subtitle: Color(0xFF778399),
        primary: Color(0xFF60A5FA),
        navMuted: Color(0xFF3D4A60),
        softBorder: Color(0xFF23324A),
        headerIconBackground: Color(0xFF1D2D45),
        headerIconBorder: Color(0xFF36527A),
        shadow: [],
      );
    }

    return _RoleDashboardColors(
      isDark: false,
      background: const Color(0xFFEFF4FC),
      surface: Colors.white,
      cardBackground: Colors.white,
      navBackground: Colors.white,
      title: const Color(0xFF111827),
      body: const Color(0xFF334155),
      subtitle: const Color(0xFF94A3B8),
      primary: const Color(0xFF2563EB),
      navMuted: const Color(0xFF94A3B8),
      softBorder: const Color(0xFFD9E2EF),
      headerIconBackground: const Color(0xFFEAF0FE),
      headerIconBorder: const Color(0xFFBFD0FF),
      shadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
