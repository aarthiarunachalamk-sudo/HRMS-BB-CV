// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/logout_exit_dialog.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/user_notification_settings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_models.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientVisits/client_visit_screens.dart';

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
  late Future<EmployeeDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = EmployeeService().fetchDashboard(widget.userId, widget.email);
  }

  void _logout() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    const color = Color(0xFF11998E);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(textPrimary, cardBg),
      body: ConstellationBackground(
        accentColor: color,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(textPrimary, isDark, color),
              Expanded(
                child: FutureBuilder<EmployeeDashboardData>(
                  future: _future,
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
                    final leaves = data['leave_balances'] is Map
                        ? Map<String, dynamic>.from(
                            data['leave_balances'] as Map,
                          )
                        : <String, dynamic>{};

                    final desig = '${profile['designation'] ?? ''}';
                    final dept = '${profile['department'] ?? ''}';
                    final status = '${attendance['status'] ?? '--'}';
                    final totalTasks = tasks.length;
                    final doneTasks = tasks
                        .where(
                          (t) =>
                              '${(t as Map?)?['status'] ?? ''}'.toLowerCase() ==
                              'completed',
                        )
                        .length;
                    final leavesAvail = '${leaves['total_available'] ?? '--'}';
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBadge('Manager', dept, desig, color),
                          const SizedBox(height: 20),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            Text(
                              'Manager Overview',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _card(
                                  'Total Tasks',
                                  '$totalTasks',
                                  Icons.task_rounded,
                                  color,
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textSecondary,
                                ),
                                _card(
                                  'Completed',
                                  '$doneTasks',
                                  Icons.check_circle_rounded,
                                  const Color(0xFF43E97B),
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textSecondary,
                                ),
                                _card(
                                  'Attendance',
                                  status,
                                  Icons.how_to_reg_rounded,
                                  const Color(0xFF4FACFE),
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textSecondary,
                                ),
                                _card(
                                  'Leave Available',
                                  leavesAvail,
                                  Icons.beach_access_rounded,
                                  const Color(0xFFFA709A),
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  '${AppGreeting.current().label}, ${widget.firstName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: accent,
            ),
            onPressed: () {
              MyApp.themeNotifier.value = isDark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, String dept, String desig, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.manage_accounts_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (desig.isNotEmpty)
                  Text(
                    desig,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardBg,
    Color cardBorder,
    Color tp,
    Color ts,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: tp,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: TextStyle(color: ts, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(Color textPrimary, Color cardBg) {
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
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.firstName.isEmpty ? 'Manager' : widget.firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Manager',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    widget.userId,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.dashboard_rounded,
                      color: Color(0xFF11998E),
                    ),
                    title: Text(
                      'Dashboard',
                      style: TextStyle(color: textPrimary),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add_location_alt_rounded,
                      color: Color(0xFF11998E),
                    ),
                    title: Text(
                      'Client Visit Approvals',
                      style: TextStyle(color: textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Client Visits')),
                            body: ClientVisitDashboardScreen(
                              userId: widget.userId,
                              reviewerMode: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.task_rounded,
                      color: Color(0xFF11998E),
                    ),
                    title: Text('Tasks', style: TextStyle(color: textPrimary)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF11998E),
                    ),
                    title: Text(
                      'Reports',
                      style: TextStyle(color: textPrimary),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.account_circle_rounded,
                color: Color(0xFF11998E),
              ),
              title: Text('Profile', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        UserPersonalInformationScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () =>
                  showLogoutConfirmation(context: context, onLogout: _logout),
            ),
          ],
        ),
      ),
    );
  }
}
