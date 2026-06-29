import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/create_admins.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:image_picker/image_picker.dart';

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
  String _dashboardRole = 'CEO';
  File? _profileImage;

  static const Color _bgTop = Color(0xFF070D19);
  static const Color _bgBottom = Color(0xFF0F223D);
  static const Color _card = Color(0xFF0F1B2E);
  static const Color _cardAlt = Color(0xFF0A121E);
  static const Color _border = Color(0xFF1E2E44);
  static const Color _gold = Color(0xFFD7932E);
  static const Color _cyan = Color(0xFF00C6FF);
  static const Color _green = Color(0xFF13D989);
  static const Color _purple = Color(0xFF9F3BFF);
  static const Color _pink = Color(0xFFFF3D8F);
  static const Color _muted = Color(0xFF8E9CAE);

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Dashboard'),
    _NavItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics'),
    _NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Reports'),
    _NavItem(Icons.approval_outlined, Icons.approval_rounded, 'Approvals'),
    _NavItem(Icons.more_horiz_outlined, Icons.more_horiz_rounded, 'More'),
  ];

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  ListTile _drawerTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ThemeConfig.blueAccent),
      title: Text(label, style: TextStyle(color: ThemeConfig.getTextPrimary(context), fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: isDark ? ThemeConfig.purpleGradient : ThemeConfig.blueGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CeoProfileAvatar(image: _profileImage, radius: 30, onTap: _pickProfileImage),
                  const SizedBox(height: 10),
                  Text(
                    widget.firstName.isEmpty ? 'CEO' : widget.firstName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('Chief Executive Officer', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(widget.userId, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _drawerTile(context, Icons.dashboard_rounded, 'Dashboard', () { Navigator.pop(context); setState(() => _selectedIndex = 0); }),
                  _drawerTile(context, Icons.analytics_rounded, 'Analytics', () { Navigator.pop(context); setState(() => _selectedIndex = 1); }),
                  _drawerTile(context, Icons.assignment_rounded, 'Reports', () { Navigator.pop(context); setState(() => _selectedIndex = 2); }),
                  _drawerTile(context, Icons.approval_rounded, 'Approvals', () { Navigator.pop(context); setState(() => _selectedIndex = 3); }),
                  _drawerTile(context, Icons.person_add_rounded, 'Create Team Member', () { Navigator.pop(context); _openPage(const CeoCreateAdminsPage()); }),
                  _drawerTile(context, Icons.groups_rounded, 'Employee Directory', () { Navigator.pop(context); _openPage(_EmployeeDirectoryPage(firstName: widget.firstName, email: widget.email, userId: widget.userId)); }),
                  _drawerTile(context, Icons.notifications_rounded, 'Notifications', () { Navigator.pop(context); _openPage(_NotificationsPage(firstName: widget.firstName, email: widget.email)); }),
                ],
              ),
            ),
            Divider(color: cardBorder),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardView(
        firstName: widget.firstName,
        email: widget.email,
        userId: widget.userId,
        profileImage: _profileImage,
        onPickProfileImage: _pickProfileImage,
        onOpenApprovals: () => setState(() => _selectedIndex = 3),
        onOpenReports: () => setState(() => _selectedIndex = 2),
        onOpenDirectory: () => _openPage(_EmployeeDirectoryPage(firstName: widget.firstName, email: widget.email, userId: widget.userId)),
      ),
      const _AnalyticsView(),
      _ReportsView(onReportDetails: () => _openPage(const _ReportDetailsPage())),
      _ApprovalsView(onLeaveDetails: () => _openPage(const _LeaveRequestPage())),
      _MoreView(
        firstName: widget.firstName,
        email: widget.email,
        userId: widget.userId,
        onProfile: () => _openPage(_ProfileSettingsPage(firstName: widget.firstName, email: widget.email, userId: widget.userId, onLogout: () => _openPage(_LogoutConfirmPage(onLogout: _logout)))),
        onBudget: () => _openPage(const _BudgetOverviewPage()),
        onDirectory: () => _openPage(_EmployeeDirectoryPage(firstName: widget.firstName, email: widget.email, userId: widget.userId)),
        onNotifications: () => _openPage(_NotificationsPage(firstName: widget.firstName, email: widget.email)),
        onMeetings: () => _openPage(const _MeetingsPage()),
        onDepartment: () => _openPage(const _DepartmentPerformancePage()),
        onBranch: () => _openPage(const _BranchPerformancePage()),
        onCreateMember: () => _openPage(const CeoCreateAdminsPage()),
        onLogout: () => _openPage(_LogoutConfirmPage(onLogout: _logout)),
      ),
    ];

    return _CeoShell(
      title: _navItems[_selectedIndex].label,
      showBack: false,
      drawer: _buildSideDrawer(context),
      trailing: IconButton(onPressed: _pickProfileImage, icon: Icon(Icons.account_circle_outlined, color: ThemeConfig.getTextPrimary(context))),
      roleBar: _selectedIndex == 0
          ? _CeoRoleBasedBar(
              role: _dashboardRole,
              userId: widget.userId,
              onChanged: (role) => setState(() => _dashboardRole = role),
            )
          : null,
      bottomNavigationBar: _BottomNavBar(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
      ),
      child: pages[_selectedIndex],
    );
  }
}

class _DashboardView extends StatefulWidget {
  final String firstName;
  final String email;
  final String userId;
  final File? profileImage;
  final VoidCallback onPickProfileImage;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenDirectory;

  const _DashboardView({required this.firstName, required this.email, required this.userId, required this.profileImage, required this.onPickProfileImage, required this.onOpenApprovals, required this.onOpenReports, required this.onOpenDirectory});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  late final Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = CeoService().fetchDashboard(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Backend data unavailable', style: _CeoText.muted(12)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _CeoDashboardState._cyan));
        }
        final data = snapshot.data!;
        return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        Row(children: [
          _CeoProfileAvatar(image: widget.profileImage, radius: 28, onTap: widget.onPickProfileImage),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: _CeoText.muted(12)),
            Text(widget.firstName.isEmpty ? 'CEO' : widget.firstName, overflow: TextOverflow.ellipsis, style: _CeoText.title(17)),
            Text(widget.email, overflow: TextOverflow.ellipsis, style: _CeoText.muted(11)),
            if (widget.userId.isNotEmpty) Text(widget.userId, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _CeoDashboardState._cyan, fontSize: 11, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 18),
        _MetricGrid(cards: [
          _MetricData('Total Employees', '${data['total_employees']}', '', Icons.groups_rounded, _CeoDashboardState._cyan),
          _MetricData('Active Employees', '${data['active_employees']}', '', Icons.verified_user_rounded, _CeoDashboardState._green),
          _MetricData('Departments', '${data['departments']}', '', Icons.apartment_rounded, _CeoDashboardState._purple),
          _MetricData('Branches', '${data['branches']}', '', Icons.business_rounded, _CeoDashboardState._gold),
        ]),
        const SizedBox(height: 16),
        const _SectionTitle('Revenue Overview'),
        const SizedBox(height: 10),
        _ChartCard(title: "${data['revenue']}", trend: "${data['revenue_trend']}", bars: const [0, 0, 0, 0, 0, 0], color: _CeoDashboardState._green),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _MiniSummary('Attendance', '${data['attendance']}', 'Present Today', _CeoDashboardState._green)),
          const SizedBox(width: 10),
          Expanded(child: _MiniSummary('Pending Approvals', '${data['pending_approvals']}', 'Requests', _CeoDashboardState._pink)),
          const SizedBox(width: 10),
          Expanded(child: _MiniSummary('Payroll Cost', "${data['payroll_cost']}", 'This Month', _CeoDashboardState._cyan)),
        ]),
        const SizedBox(height: 18),
        const _SectionTitle('Quick Actions'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionTile(icon: Icons.groups_rounded, label: 'Employees', onTap: widget.onOpenDirectory)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.beach_access_rounded, label: 'Leave', onTap: widget.onOpenApprovals)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.payments_rounded, label: 'Payroll', onTap: widget.onOpenReports)),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(icon: Icons.summarize_rounded, label: 'Reports', onTap: widget.onOpenReports)),
        ]),
      ],
        );
      },
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: const [
        _PeriodSelector(),
        SizedBox(height: 14),
        _ChartCard(title: '₹ 48,50,000', subtitle: 'Revenue Overview', trend: '+15.6%', bars: [28, 38, 36, 52, 47, 60], color: _CeoDashboardState._green),
        SizedBox(height: 14),
        _ChartCard(title: 'Employee Growth', trend: '+12.5%', bars: [42, 68, 82, 54, 78, 72], color: _CeoDashboardState._cyan),
        SizedBox(height: 14),
        _DepartmentDonutCard(),
      ],
    );
  }
}

class _ReportsView extends StatelessWidget {
  final VoidCallback onReportDetails;
  const _ReportsView({required this.onReportDetails});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        _ReportTile(Icons.badge_rounded, 'HR Reports', 'View HR related reports', _CeoDashboardState._green, onReportDetails),
        _ReportTile(Icons.account_balance_wallet_rounded, 'Finance Reports', 'View finance reports', _CeoDashboardState._purple, onReportDetails),
        _ReportTile(Icons.calendar_month_rounded, 'Attendance Reports', 'View attendance reports', _CeoDashboardState._cyan, onReportDetails),
        _ReportTile(Icons.beach_access_rounded, 'Leave Reports', 'View leave related reports', _CeoDashboardState._pink, onReportDetails),
        _ReportTile(Icons.payments_rounded, 'Payroll Reports', 'View payroll reports', _CeoDashboardState._green, onReportDetails),
        _ReportTile(Icons.query_stats_rounded, 'Performance Reports', 'View performance reports', _CeoDashboardState._gold, onReportDetails),
      ],
    );
  }
}

class _ApprovalsView extends StatelessWidget {
  final VoidCallback onLeaveDetails;
  const _ApprovalsView({required this.onLeaveDetails});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        const _SegmentTabs(left: 'Pending', right: 'History'),
        const SizedBox(height: 16),
        _ApprovalTile(Icons.event_available_rounded, 'Leave Requests', '5 Pending', _CeoDashboardState._purple, onLeaveDetails),
        _ApprovalTile(Icons.receipt_long_rounded, 'Expense Requests', '3 Pending', _CeoDashboardState._green, onLeaveDetails),
        _ApprovalTile(Icons.schedule_rounded, 'Overtime Requests', '2 Pending', _CeoDashboardState._gold, onLeaveDetails),
        _ApprovalTile(Icons.savings_rounded, 'Budget Requests', '1 Pending', _CeoDashboardState._pink, onLeaveDetails),
      ],
    );
  }
}

class _MoreView extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;
  final VoidCallback onProfile;
  final VoidCallback onBudget;
  final VoidCallback onDirectory;
  final VoidCallback onNotifications;
  final VoidCallback onMeetings;
  final VoidCallback onDepartment;
  final VoidCallback onBranch;
  final VoidCallback onCreateMember;
  final VoidCallback onLogout;

  const _MoreView({required this.firstName, required this.email, required this.userId, required this.onProfile, required this.onBudget, required this.onDirectory, required this.onNotifications, required this.onMeetings, required this.onDepartment, required this.onBranch, required this.onCreateMember, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: [
        _ProfileHeader(firstName: firstName.isEmpty ? 'CEO' : firstName, email: email, role: 'Chief Executive Officer'),
        const SizedBox(height: 16),
        _MenuTile(Icons.account_circle_rounded, 'Profile & Settings', 'Account, security, preferences', onProfile),
        _MenuTile(Icons.pie_chart_rounded, 'Budget Overview', 'Budget, spent, remaining', onBudget),
        _MenuTile(Icons.groups_rounded, 'Employee Directory', 'Leadership and teams', onDirectory),
        _MenuTile(Icons.notifications_rounded, 'Notifications', 'Alerts and updates', onNotifications),
        _MenuTile(Icons.calendar_month_rounded, 'Meetings', 'Board and department reviews', onMeetings),
        _MenuTile(Icons.stacked_bar_chart_rounded, 'Department Performance', 'Team performance snapshot', onDepartment),
        _MenuTile(Icons.business_rounded, 'Branch Performance', 'Location performance snapshot', onBranch),
        _MenuTile(Icons.person_add_rounded, 'Create Team Member', 'Add HR, Finance, IT, etc.', onCreateMember),
        _MenuTile(Icons.logout_rounded, 'Logout', 'End current session', onLogout, danger: true),
      ],
    );
  }
}

class _ReportDetailsPage extends StatelessWidget {
  const _ReportDetailsPage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'HR Summary Report',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          _PeriodSelector(),
          SizedBox(height: 14),
          _MetricGrid(cards: [
            _MetricData('Total Employees', '1,245', '', Icons.groups_rounded, _CeoDashboardState._cyan),
            _MetricData('New Joiners', '28', '', Icons.person_add_alt_1_rounded, _CeoDashboardState._green),
            _MetricData('Exit Employees', '8', '', Icons.person_remove_rounded, _CeoDashboardState._pink),
            _MetricData('Active Employees', '1,217', '', Icons.verified_user_rounded, _CeoDashboardState._purple),
          ]),
          SizedBox(height: 14),
          _DepartmentBarsCard(),
          SizedBox(height: 14),
          _ExportButtons(),
        ],
      ),
    );
  }
}

class _LeaveRequestPage extends StatelessWidget {
  const _LeaveRequestPage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Leave Request',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          _PersonCard(name: 'Aarthi M', role: 'Marketing Executive'),
          SizedBox(height: 14),
          _DetailsCard(rows: [
            _InfoRow('Leave Type', 'Casual Leave'),
            _InfoRow('From Date', '20 May 2025'),
            _InfoRow('To Date', '21 May 2025'),
            _InfoRow('Total Days', '2 Days'),
            _InfoRow('Reason', 'Personal Work'),
            _InfoRow('Applied On', '18 May 2025'),
            _InfoRow('Status', 'Pending', valueColor: _CeoDashboardState._gold),
          ]),
          SizedBox(height: 18),
          _DecisionButtons(),
        ],
      ),
    );
  }
}

class _DepartmentPerformancePage extends StatelessWidget {
  const _DepartmentPerformancePage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Department Performance',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          _PeriodSelector(),
          SizedBox(height: 14),
          _PerformanceRow('HR', '92%', '+12.5%', _CeoDashboardState._green),
          _PerformanceRow('Finance', '88%', '+10.3%', _CeoDashboardState._gold),
          _PerformanceRow('Sales', '78%', '+6.1%', _CeoDashboardState._cyan),
          _PerformanceRow('IT', '75%', '+6.2%', _CeoDashboardState._purple),
          _PerformanceRow('Operations', '70%', '+5.4%', _CeoDashboardState._cyan),
          SizedBox(height: 14),
          _OverallPerformanceCard(),
        ],
      ),
    );
  }
}

class _BranchPerformancePage extends StatelessWidget {
  const _BranchPerformancePage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Branch Performance',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          _PeriodSelector(),
          SizedBox(height: 14),
          _BranchTile('Chennai', '95%', '+12.5%', '₹48L'),
          _BranchTile('Bangalore', '92%', '+10.3%', '₹42L'),
          _BranchTile('Hyderabad', '90%', '+8.1%', '₹36L'),
          _BranchTile('Mumbai', '88%', '+7.2%', '₹32L'),
          _BranchTile('Delhi', '85%', '+6.5%', '₹28L'),
        ],
      ),
    );
  }
}

class _BudgetOverviewPage extends StatelessWidget {
  const _BudgetOverviewPage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Budget Directory',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          _BudgetCard('Total Budget', '₹ 2,45,00,000', null),
          _BudgetCard('Total Spent', '₹ 1,45,00,000', '59%'),
          _BudgetCard('Remaining Budget', '₹ 1,00,00,000', '41%'),
          SizedBox(height: 16),
          _ChartCard(title: 'Budget vs Actual', bars: [58, 72, 48, 66, 76, 70], color: _CeoDashboardState._cyan),
        ],
      ),
    );
  }
}

class _EmployeeDirectoryPage extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;

  const _EmployeeDirectoryPage({required this.firstName, required this.email, required this.userId});

  @override
  Widget build(BuildContext context) {
    final employees = [
      _Employee(firstName.isEmpty ? 'CEO' : firstName, 'Chief Executive Officer', email, userId),
      const _Employee('Karthik R', 'Sales Executive', 'karthik@company.com', 'EMP1022'),
      const _Employee('Rahul K', 'HR Executive', 'rahul@company.com', 'EMP1023'),
      const _Employee('Priya S', 'Finance Executive', 'priya@company.com', 'EMP1024'),
      const _Employee('Vignesh P', 'IT Executive', 'vignesh@company.com', 'EMP1025'),
    ];

    return _CeoShell(
      title: 'Employee Directory',
      trailing: const Icon(Icons.filter_list_rounded, color: _CeoDashboardState._muted),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          const _SearchBox(),
          const SizedBox(height: 14),
          ...employees.map((e) => _EmployeeTile(employee: e, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _EmployeeProfilePage(employee: e))))),
        ],
      ),
    );
  }
}

class _EmployeeProfilePage extends StatelessWidget {
  final _Employee employee;
  const _EmployeeProfilePage({required this.employee});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: employee.name,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _ProfileHeader(firstName: employee.name, email: employee.email, role: employee.role),
          const SizedBox(height: 16),
          const _SegmentTabs(left: 'Overview', right: 'Attendance'),
          const SizedBox(height: 14),
          _DetailsCard(rows: [
            _InfoRow('Employee ID', employee.id.isEmpty ? 'EMP1021' : employee.id),
            _InfoRow('Email', employee.email),
            const _InfoRow('Phone', '+91 98765 43210'),
            const _InfoRow('Department', 'Marketing'),
            const _InfoRow('Date of Joining', '10 Jan 2023'),
            const _InfoRow('Reporting Manager', 'Karthik R'),
          ]),
          const SizedBox(height: 14),
          Row(children: const [
            Expanded(child: _MiniSummary('Attendance', '95%', 'This Month', _CeoDashboardState._green)),
            SizedBox(width: 10),
            Expanded(child: _MiniSummary('Leave Balance', '12 Days', 'Remaining', _CeoDashboardState._cyan)),
            SizedBox(width: 10),
            Expanded(child: _MiniSummary('Performance', '4.5', 'Rating', _CeoDashboardState._gold)),
          ]),
        ],
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  final String firstName;
  final String email;
  const _NotificationsPage({required this.firstName, required this.email});

  @override
  Widget build(BuildContext context) {
    final displayName = firstName.isEmpty ? 'CEO' : firstName;
    return _CeoShell(
      title: 'Notifications',
      trailing: const Icon(Icons.more_vert_rounded, color: _CeoDashboardState._muted),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          const _SegmentTabs(left: 'All', right: 'Unread'),
          const SizedBox(height: 16),
          const _NotificationTile(Icons.check_box_rounded, 'CEO session active', 'Backend login verified', 'Now', _CeoDashboardState._green),
          _NotificationTile(Icons.account_circle_rounded, 'Logged in user', displayName, 'Now', _CeoDashboardState._cyan),
          _NotificationTile(Icons.mail_outline_rounded, 'Connected email', email, 'Now', _CeoDashboardState._purple),
          const _NotificationTile(Icons.person_add_alt_1_rounded, 'New employee joined', 'Employee record pending sync', '1h ago', _CeoDashboardState._pink),
          const _NotificationTile(Icons.payments_rounded, 'Monthly payroll completed', 'April 2025 payroll completed', '2h ago', _CeoDashboardState._gold),
          const _NotificationTile(Icons.account_balance_wallet_rounded, 'Budget update', 'Q2 budget has been updated', '3h ago', _CeoDashboardState._gold),
          const _NotificationTile(Icons.warning_rounded, 'Attendance alert', '5 employees marked absent today', '5h ago', _CeoDashboardState._purple),
        ],
      ),
    );
  }
}

class _MeetingsPage extends StatelessWidget {
  const _MeetingsPage();

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Meetings',
      trailing: const Icon(Icons.more_vert_rounded, color: _CeoDashboardState._muted),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _CeoDashboardState._purple,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: const [
          Text('May 2025', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 12),
          _CalendarStrip(),
          SizedBox(height: 18),
          Text('Today - 22 May 2025', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(height: 10),
          _MeetingTile('Board Meeting', '10:00 AM - 11:30 AM', 'Board Room', _CeoDashboardState._cyan),
          _MeetingTile('Department Review', '02:00 PM - 03:00 PM', 'Conference Hall', _CeoDashboardState._pink),
          _MeetingTile('Budget Planning', '04:00 PM - 05:30 PM', 'Online', _CeoDashboardState._cyan),
        ],
      ),
    );
  }
}

class _ProfileSettingsPage extends StatelessWidget {
  final String firstName;
  final String email;
  final String userId;
  final VoidCallback onLogout;

  const _ProfileSettingsPage({required this.firstName, required this.email, required this.userId, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Profile & Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          _ProfileHeader(firstName: firstName.isEmpty ? 'CEO' : firstName, email: userId.isEmpty ? email : userId, role: 'Chief Executive Officer'),
          const SizedBox(height: 16),
          const _SettingsGroup(title: 'Profile', children: [
            _SettingsRow(Icons.person_outline_rounded, 'Personal Information', null),
            _SettingsRow(Icons.business_center_outlined, 'Organization Info', null),
          ]),
          const SizedBox(height: 14),
          const _SettingsGroup(title: 'Security', children: [
            _SettingsRow(Icons.lock_outline_rounded, 'Change Password', null),
            _SettingsRow(Icons.fingerprint_rounded, 'Biometric Login', 'On'),
          ]),
          const SizedBox(height: 14),
          const _SettingsGroup(title: 'Preferences', children: [
            _SettingsRow(Icons.language_rounded, 'Language', 'English'),
            _SettingsRow(Icons.dark_mode_outlined, 'Theme', 'Dark'),
            _SettingsRow(Icons.notifications_none_rounded, 'Notification Settings', null),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE1622), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: onLogout,
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutConfirmPage extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutConfirmPage({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return _CeoShell(
      title: 'Logout',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _CeoDashboardState._cardAlt, border: Border.all(color: _CeoDashboardState._border)),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 22),
            const Text('Are you sure you want to logout?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE1622), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: onLogout, child: const Text('Logout'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _CeoDashboardState._border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
            ]),
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

  const _CeoShell({required this.title, required this.child, this.showBack = true, this.trailing, this.roleBar, this.bottomNavigationBar, this.floatingActionButton, this.drawer});

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
        decoration: BoxDecoration(gradient: LinearGradient(colors: [bgStart, bgEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42, height: 42,
                      child: showBack
                          ? IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18), onPressed: () => Navigator.of(context).pop())
                          : Builder(builder: (ctx) => InkWell(onTap: () => Scaffold.of(ctx).openDrawer(), borderRadius: BorderRadius.circular(8), child: const Padding(padding: EdgeInsets.all(5), child: BitByteLogo(compact: true)))),
                    ),
                    Expanded(child: Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800))),
                    SizedBox(width: 42, height: 42, child: Center(child: trailing ?? const SizedBox.shrink())),
                  ],
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

class _CeoRoleBasedBar extends StatelessWidget {
  final String role;
  final String userId;
  final ValueChanged<String> onChanged;

  const _CeoRoleBasedBar({required this.role, required this.userId, required this.onChanged});

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
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: role,
            isExpanded: true,
            dropdownColor: bg,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _CeoDashboardState._cyan),
            style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w900),
            selectedItemBuilder: (context) {
              return const ['Employee', 'CEO'].map((_) {
                return Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, color: _CeoDashboardState._cyan, size: 18),
                    const SizedBox(width: 8),
                    Text('Role Based', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(role, overflow: TextOverflow.ellipsis)),
                    if (userId.trim().isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(userId, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _CeoDashboardState._cyan, fontSize: 11, fontWeight: FontWeight.w800)),
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

  const _BottomNavBar({required this.items, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final bgColor = ThemeConfig.getCardBg(context);
    final borderColor = ThemeConfig.getCardBorder(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final selectedColor = isDark ? _CeoDashboardState._purple : ThemeConfig.blueSecondary;

    return Container(
      decoration: BoxDecoration(color: bgColor, border: Border(top: BorderSide(color: borderColor))),
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
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(selected ? item.activeIcon : item.icon, color: selected ? selectedColor : _CeoDashboardState._muted, size: 21),
                    const SizedBox(height: 4),
                    FittedBox(child: Text(item.label, style: TextStyle(color: selected ? textPrimary : textSecondary, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                  ]),
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
      itemCount: cards.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(card.icon, color: card.color, size: 20), const Spacer(), if (card.trend.isNotEmpty) Text(card.trend, style: const TextStyle(color: _CeoDashboardState._green, fontSize: 10, fontWeight: FontWeight.w700))]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(card.title, style: _CeoText.muted(11)), const SizedBox(height: 4), Text(card.value, style: _CeoText.title(20))]),
        ]));
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trend;
  final List<double> bars;
  final Color color;

  const _ChartCard({required this.title, this.subtitle, this.trend, required this.bars, required this.color});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (subtitle != null) Text(subtitle!, style: _CeoText.muted(11)),
        Row(children: [Expanded(child: Text(title, style: _CeoText.title(18))), if (trend != null) Text(trend!, style: const TextStyle(color: _CeoDashboardState._green, fontSize: 11, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 14),
        SizedBox(height: 88, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: bars.map((h) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Container(height: h, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.35), color], begin: Alignment.bottomCenter, end: Alignment.topCenter), borderRadius: BorderRadius.circular(8)))))).toList())),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'].map((m) => Text(m, style: TextStyle(color: _CeoDashboardState._muted, fontSize: 10))).toList()),
      ]),
    );
  }
}

class _DepartmentDonutCard extends StatelessWidget {
  const _DepartmentDonutCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle('Department Performance'),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(width: 96, height: 96, child: CustomPaint(painter: _DonutPainter())),
        const SizedBox(width: 18),
        const Expanded(child: Column(children: [
          _LegendRow('HR', '28%', _CeoDashboardState._cyan),
          _LegendRow('Finance', '25%', _CeoDashboardState._green),
          _LegendRow('Sales', '20%', _CeoDashboardState._gold),
          _LegendRow('IT', '17%', _CeoDashboardState._pink),
          _LegendRow('Operations', '10%', _CeoDashboardState._purple),
        ])),
      ]),
    ]));
  }
}

class _DepartmentBarsCard extends StatelessWidget {
  const _DepartmentBarsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      _SectionTitle('Department Wise Employees'),
      SizedBox(height: 12),
      _ProgressInfo('HR', '120', 0.42, _CeoDashboardState._green),
      _ProgressInfo('Finance', '200', 0.70, _CeoDashboardState._gold),
      _ProgressInfo('Sales', '300', 0.82, _CeoDashboardState._pink),
      _ProgressInfo('IT', '250', 0.74, _CeoDashboardState._purple),
      _ProgressInfo('Operations', '200', 0.64, _CeoDashboardState._cyan),
    ]));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(12), this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    final card = Container(
      width: double.infinity, padding: padding,
      decoration: BoxDecoration(color: cardBg.withOpacity(0.94), borderRadius: BorderRadius.circular(8), border: Border.all(color: cardBorder), boxShadow: ThemeConfig.getPremiumShadow(context)),
      child: child,
    );
    if (onTap == null) return card;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: card)));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: _CeoText.title(15));
}

class _MiniSummary extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final Color color;

  const _MiniSummary(this.title, this.value, this.caption, this.color);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _CeoText.muted(10)),
      const SizedBox(height: 5),
      Text(value, style: _CeoText.title(16)),
      const SizedBox(height: 2),
      Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    ]));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(
      height: 70,
      decoration: BoxDecoration(color: _CeoDashboardState._cardAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: _CeoDashboardState._border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _CeoDashboardState._cyan, size: 22),
        const SizedBox(height: 6),
        FittedBox(child: Text(label, style: _CeoText.muted(10))),
      ]),
    ));
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile(this.icon, this.title, this.subtitle, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(onTap: onTap, child: Row(children: [
      _IconSquare(icon: icon, color: color),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _CeoText.title(14)), const SizedBox(height: 3), Text(subtitle, style: _CeoText.muted(11))])),
      const Icon(Icons.chevron_right_rounded, color: Colors.white),
    ]));
  }
}

class _ApprovalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ApprovalTile(this.icon, this.title, this.subtitle, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => _ReportTile(icon, title, subtitle, color, onTap);
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _MenuTile(this.icon, this.title, this.subtitle, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : _CeoDashboardState._cyan;
    return _GlassCard(onTap: onTap, child: Row(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: danger ? Colors.redAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: _CeoText.muted(11)),
      ])),
      Icon(Icons.chevron_right_rounded, color: danger ? Colors.redAccent : _CeoDashboardState._muted),
    ]));
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerRight, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _CeoDashboardState._cardAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: _CeoDashboardState._border)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('This Month', style: TextStyle(color: _CeoDashboardState._muted, fontSize: 11, fontWeight: FontWeight.w700)),
        SizedBox(width: 8),
        Icon(Icons.keyboard_arrow_down_rounded, color: _CeoDashboardState._muted, size: 18),
      ]),
    ));
  }
}

class _SegmentTabs extends StatelessWidget {
  final String left;
  final String right;
  const _SegmentTabs({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: _TabLabel(left, active: true)), Expanded(child: _TabLabel(right, active: false))]);
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool active;
  const _TabLabel(this.text, {required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(text, style: TextStyle(color: active ? _CeoDashboardState._pink : _CeoDashboardState._muted, fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 8),
      Container(height: 2, color: active ? _CeoDashboardState._pink : _CeoDashboardState._border),
    ]);
  }
}

class _DetailsCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _DetailsCard({required this.rows});

  @override
  Widget build(BuildContext context) => _GlassCard(child: Column(children: rows));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
      Expanded(child: Text(label, style: _CeoText.muted(12))),
      Flexible(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
    ]));
  }
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons();

  @override
  Widget build(BuildContext context) {
    return Column(children: const [
      _DecisionButton('Approve', _CeoDashboardState._green, Icons.check_rounded),
      SizedBox(height: 10),
      _DecisionButton('Reject', Color(0xFFBE1622), Icons.close_rounded),
      SizedBox(height: 10),
      _DecisionButton('Escalate', Colors.transparent, Icons.trending_up_rounded, outlined: true),
    ]);
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;
  const _DecisionButton(this.label, this.color, this.icon, {this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 48, width: double.infinity, child: outlined
        ? OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _CeoDashboardState._border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () {}, icon: Icon(icon, size: 18), label: Text(label))
        : ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () {}, icon: Icon(icon, size: 18), label: Text(label)));
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
    return _GlassCard(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: _CeoText.title(13))), Text(value, style: _CeoText.title(14)), const SizedBox(width: 8), Text(trend, style: const TextStyle(color: _CeoDashboardState._green, fontSize: 11, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress / 100, minHeight: 5, color: color, backgroundColor: _CeoDashboardState._border)),
    ]));
  }
}

class _OverallPerformanceCard extends StatelessWidget {
  const _OverallPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(child: Row(children: [
      SizedBox(width: 92, height: 92, child: Stack(alignment: Alignment.center, children: const [
        CircularProgressIndicator(value: 0.84, strokeWidth: 8, color: _CeoDashboardState._green, backgroundColor: _CeoDashboardState._border),
        Text('84%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
      ])),
      const SizedBox(width: 18),
      const Expanded(child: Text('Overall Performance\n+10.2%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.7))),
    ]));
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
    return _GlassCard(child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city, style: _CeoText.title(14)), const SizedBox(height: 5), Text('Revenue', style: _CeoText.muted(11))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(score, style: _CeoText.title(16)), Text(trend, style: const TextStyle(color: _CeoDashboardState._green, fontSize: 11, fontWeight: FontWeight.w800)), Text(revenue, style: _CeoText.muted(12))]),
    ]));
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String value;
  final String? percent;
  const _BudgetCard(this.title, this.value, this.percent);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _CeoText.muted(12)), const SizedBox(height: 8), Text(value, style: _CeoText.title(18))])),
      if (percent != null) CircleAvatar(radius: 24, backgroundColor: _CeoDashboardState._border, child: Text(percent!, style: const TextStyle(color: _CeoDashboardState._green, fontWeight: FontWeight.w800, fontSize: 12)))
      else const Icon(Icons.chevron_right_rounded, color: Colors.white),
    ]));
  }
}

class _EmployeeTile extends StatelessWidget {
  final _Employee employee;
  final VoidCallback onTap;
  const _EmployeeTile({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(onTap: onTap, child: Row(children: [
      const _AvatarBadge(icon: Icons.person_rounded, small: true),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(employee.name, style: _CeoText.title(14)), Text(employee.role, style: _CeoText.muted(11))])),
      const Icon(Icons.chevron_right_rounded, color: Colors.white),
    ]));
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  const _NotificationTile(this.icon, this.title, this.subtitle, this.time, this.color);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(child: Row(children: [
      _IconSquare(icon: icon, color: color),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _CeoText.title(13)), const SizedBox(height: 4), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _CeoText.muted(11))])),
      Text(time, style: _CeoText.muted(10)),
    ]));
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
    return _GlassCard(child: Row(children: [
      Container(width: 4, height: 54, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _CeoText.title(14)), const SizedBox(height: 5), Text(time, style: _CeoText.muted(11)), Text(place, style: _CeoText.muted(11))])),
      const Icon(Icons.chevron_right_rounded, color: Colors.white),
    ]));
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _CeoText.muted(12)), const SizedBox(height: 6), ...children]));
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _SettingsRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: _CeoText.title(13))),
      if (value != null) Text(value!, style: _CeoText.muted(11)),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right_rounded, color: _CeoDashboardState._muted, size: 18),
    ]));
  }
}

class _ProfileHeader extends StatelessWidget {
  final String firstName;
  final String email;
  final String role;
  const _ProfileHeader({required this.firstName, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const _AvatarBadge(icon: Icons.person_rounded),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(firstName, overflow: TextOverflow.ellipsis, style: _CeoText.title(18)),
        Text(role, overflow: TextOverflow.ellipsis, style: _CeoText.muted(12)),
        Text(email, overflow: TextOverflow.ellipsis, style: _CeoText.muted(11)),
      ])),
    ]);
  }
}

class _PersonCard extends StatelessWidget {
  final String name;
  final String role;
  const _PersonCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) => _ProfileHeader(firstName: name, email: 'Active request', role: role);
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _CeoDashboardState._card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _CeoDashboardState._border)),
      child: Row(children: [const Icon(Icons.search_rounded, color: _CeoDashboardState._muted, size: 20), const SizedBox(width: 10), Text('Search employee...', style: _CeoText.muted(12))]),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip();

  @override
  Widget build(BuildContext context) {
    final days = const ['19', '20', '21', '22', '23', '24', '25'];
    return Row(children: days.map((day) {
      final active = day == '22';
      return Expanded(child: Container(
        height: 44, margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: active ? _CeoDashboardState._purple : _CeoDashboardState._card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _CeoDashboardState._border)),
        alignment: Alignment.center,
        child: Text(day, style: TextStyle(color: Colors.white, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
      ));
    }).toList());
  }
}

class _ExportButtons extends StatelessWidget {
  const _ExportButtons();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _GradientButton(label: 'Download PDF', icon: Icons.picture_as_pdf_rounded, colors: const [_CeoDashboardState._purple, Color(0xFF6C1BFF)])),
      const SizedBox(width: 12),
      Expanded(child: _GradientButton(label: 'Export Excel', icon: Icons.table_chart_rounded, colors: const [_CeoDashboardState._cyan, Color(0xFF009AAE)])),
    ]);
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  const _GradientButton({required this.label, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(8)),
      child: TextButton.icon(onPressed: () {}, icon: Icon(icon, color: Colors.white, size: 18), label: FittedBox(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
    );
  }
}

class _HeaderBell extends StatelessWidget {
  final VoidCallback onPressed;
  const _HeaderBell({required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(onPressed: onPressed, icon: Icon(Icons.notifications_none_rounded, color: ThemeConfig.getTextPrimary(context), size: 22));
}

class _IconSquare extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconSquare({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.45))),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final IconData icon;
  final bool small;
  const _AvatarBadge({required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 42.0 : 58.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFD7B3), Color(0xFF8E4B2E)]), border: Border.all(color: Colors.white24, width: 2)),
      child: Icon(icon, color: Colors.white, size: small ? 22 : 30),
    );
  }
}

class _CeoProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _CeoProfileAvatar({required this.image, required this.radius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: image == null ? null : FileImage(image!),
        child: image == null ? Icon(Icons.person_rounded, color: Colors.white, size: radius) : null,
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
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      SizedBox(width: 76, child: Text(label, style: _CeoText.muted(12))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 5, color: color, backgroundColor: _CeoDashboardState._border))),
      const SizedBox(width: 10),
      SizedBox(width: 34, child: Text(value, textAlign: TextAlign.right, style: _CeoText.title(12))),
    ]));
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LegendRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: _CeoText.muted(11))),
      Text(value, style: _CeoText.title(11)),
    ]));
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round;
    const values = [0.28, 0.25, 0.20, 0.17, 0.10];
    const colors = [_CeoDashboardState._cyan, _CeoDashboardState._green, _CeoDashboardState._gold, _CeoDashboardState._pink, _CeoDashboardState._purple];
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
  static TextStyle title(double size) => TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.w800);
  static TextStyle muted(double size) => TextStyle(color: _CeoDashboardState._muted, fontSize: size, fontWeight: FontWeight.w500);
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
  const _MetricData(this.title, this.value, this.trend, this.icon, this.color);
}

class _Employee {
  final String name;
  final String role;
  final String email;
  final String id;
  const _Employee(this.name, this.role, this.email, this.id);
}
