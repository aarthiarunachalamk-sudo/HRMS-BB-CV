import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class EmployeeDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const EmployeeDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
  });

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  static const Color _blue = Color(0xFF4FACFE);
  static const Color _green = Color(0xFF43E97B);
  static const Color _purple = Color(0xFF8B5CFF);
  static const Color _gold = Color(0xFFD7932E);
  static const Color _pink = Color(0xFFFF3D8F);

  void _logout() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MyApp()), (route) => false);

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final isDark = ThemeConfig.isDark(context);

    final pages = [
      _buildHome(textPrimary, textSecondary, cardBg, cardBorder),
      _buildAttendance(textPrimary, textSecondary, cardBg, cardBorder),
      _buildLeave(textPrimary, textSecondary, cardBg, cardBorder),
      _buildProfile(textPrimary, textSecondary, cardBg, cardBorder),
    ];

    return Scaffold(
      body: ConstellationBackground(
        accentColor: _blue,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, Color(0xFF00C6FF)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(
                      widget.firstName.isNotEmpty ? widget.firstName[0].toUpperCase() : 'E',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hello, ${widget.firstName}', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(widget.userId, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: _blue),
                    onPressed: () { MyApp.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark; setState(() {}); },
                  ),
                  IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22), onPressed: _logout),
                ]),
              ),
              Expanded(child: pages[_selectedIndex]),
              // Bottom Nav
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: cardBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                        _navItem(1, Icons.access_time_outlined, Icons.access_time_filled_rounded, 'Attendance'),
                        _navItem(2, Icons.beach_access_outlined, Icons.beach_access_rounded, 'Leave'),
                        _navItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _selectedIndex == index;
    return Expanded(child: InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(selected ? activeIcon : icon, color: selected ? _blue : Colors.grey, size: 22),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: selected ? _blue : Colors.grey, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ]),
    ));
  }

  Widget _buildHome(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Welcome Card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_blue, Color(0xFF00C6FF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome Back! 👋', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(widget.firstName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 20),

        // Stats
        Text('My Overview', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            _statCard('Attendance', '95%', Icons.check_circle_rounded, _green, cardBg, cardBorder, tp, ts),
            _statCard('Leave Balance', '12 Days', Icons.beach_access_rounded, _blue, cardBg, cardBorder, tp, ts),
            _statCard('Tasks', '5 Pending', Icons.task_alt_rounded, _gold, cardBg, cardBorder, tp, ts),
            _statCard('Payroll', '₹ 0', Icons.payments_rounded, _purple, cardBg, cardBorder, tp, ts),
          ],
        ),
        const SizedBox(height: 20),

        // Quick Actions
        Text('Quick Actions', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _quickAction(Icons.access_time_rounded, 'Clock In', _green, cardBg, cardBorder, tp, ts),
          const SizedBox(width: 10),
          _quickAction(Icons.beach_access_rounded, 'Apply Leave', _blue, cardBg, cardBorder, tp, ts),
          const SizedBox(width: 10),
          _quickAction(Icons.payments_rounded, 'Payslip', _purple, cardBg, cardBorder, tp, ts),
          const SizedBox(width: 10),
          _quickAction(Icons.summarize_rounded, 'Reports', _gold, cardBg, cardBorder, tp, ts),
        ]),
        const SizedBox(height: 20),

        // Recent Activity
        Text('Recent Activity', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _activityTile('Account Created', 'Welcome to Bitbyte!', Icons.celebration_rounded, _green, cardBg, cardBorder, tp, ts),
        _activityTile('Password Changed', 'Login credentials set', Icons.lock_rounded, _blue, cardBg, cardBorder, tp, ts),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildAttendance(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance', style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
          child: Column(children: [
            const Icon(Icons.access_time_rounded, color: _green, size: 48),
            const SizedBox(height: 12),
            Text('Today\'s Status', style: TextStyle(color: ts, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Not Clocked In', style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clock In feature coming soon!'))),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Clock In'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clock Out feature coming soon!'))),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Clock Out'),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Monthly Summary', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _infoCard([
          _infoRow('Present Days', '0', tp, ts),
          _infoRow('Absent Days', '0', tp, ts),
          _infoRow('Leave Days', '0', tp, ts),
          _infoRow('Attendance %', '0%', tp, ts),
        ], cardBg, cardBorder),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildLeave(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Leave Management', style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _leaveBalanceCard('Annual', '12', _blue, cardBg, cardBorder, tp, ts)),
          const SizedBox(width: 12),
          Expanded(child: _leaveBalanceCard('Sick', '6', _green, cardBg, cardBorder, tp, ts)),
          const SizedBox(width: 12),
          Expanded(child: _leaveBalanceCard('Casual', '5', _purple, cardBg, cardBorder, tp, ts)),
        ]),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave apply feature coming soon!'))),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Text('Leave History', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
          child: Center(child: Column(children: [
            Icon(Icons.beach_access_outlined, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text('No leave history', style: TextStyle(color: ts, fontSize: 14)),
          ])),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildProfile(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_blue, Color(0xFF00C6FF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: Center(child: Text(
                widget.firstName.isNotEmpty ? widget.firstName[0].toUpperCase() : 'E',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(height: 12),
            Text(widget.firstName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.userId, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Account Details', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _infoCard([
          _infoRow('Employee ID', widget.userId, tp, ts),
          _infoRow('Email', widget.email, tp, ts),
          _infoRow('Role', 'Employee', tp, ts),
        ], cardBg, cardBorder),
        const SizedBox(height: 16),
        Text('Settings', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _settingsTile(Icons.lock_outline_rounded, 'Change Password', _blue, cardBg, cardBorder, tp, ts, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
        }),
        _settingsTile(Icons.notifications_none_rounded, 'Notifications', _purple, cardBg, cardBorder, tp, ts, () {}),
        _settingsTile(Icons.help_outline_rounded, 'Help & Support', _gold, cardBg, cardBorder, tp, ts, () {}),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color cardBg, Color cardBorder, Color tp, Color ts) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 24),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: ts, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, Color cardBg, Color cardBorder, Color tp, Color ts) {
    return Expanded(child: GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label coming soon!'))),
      child: Container(
        height: 70, padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: ts, fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }

  Widget _activityTile(String title, String subtitle, IconData icon, Color color, Color cardBg, Color cardBorder, Color tp, Color ts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: tp, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: ts, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _leaveBalanceCard(String type, String days, Color color, Color cardBg, Color cardBorder, Color tp, Color ts) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
      child: Column(children: [
        Text(days, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(type, style: TextStyle(color: ts, fontSize: 11)),
      ]),
    );
  }

  Widget _infoCard(List<Widget> rows, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value, Color tp, Color ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: ts, fontSize: 12))),
        Text(value, style: TextStyle(color: tp, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _settingsTile(IconData icon, String label, Color color, Color cardBg, Color cardBorder, Color tp, Color ts, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: tp, fontSize: 13, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios_rounded, color: ts, size: 14),
        ]),
      ),
    );
  }
}