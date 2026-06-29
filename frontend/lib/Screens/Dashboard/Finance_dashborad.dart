import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class FinanceDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;
  const FinanceDashboard({super.key, required this.email, required this.firstName, required this.userId});

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _logout() => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    const color = Color(0xFFF7971E);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(textPrimary, cardBg),
      body: ConstellationBackground(
        accentColor: color,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(textPrimary, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildBadge('Finance Team', color),
                    const SizedBox(height: 20),
                    Text('Finance Overview', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                      children: [
                        _statCard('Budget', '0', Icons.account_balance_rounded, color, cardBg, cardBorder, textPrimary, textSecondary),
                        _statCard('Expenses', '0', Icons.money_off_rounded, const Color(0xFFFA709A), cardBg, cardBorder, textPrimary, textSecondary),
                        _statCard('Revenue', '0', Icons.trending_up_rounded, const Color(0xFF43E97B), cardBg, cardBorder, textPrimary, textSecondary),
                        _statCard('Pending', '0', Icons.pending_rounded, const Color(0xFF4FACFE), cardBg, cardBorder, textPrimary, textSecondary),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24)),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, ${widget.firstName}', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(widget.userId, style: const TextStyle(color: Color(0xFFF7971E), fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
      ]),
    );
  }

  Widget _buildBadge(String title, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withAlpha(180)]), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.account_balance_rounded, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 28),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: textSecondary, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildDrawer(Color textPrimary, Color cardBg) {
    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF7971E), Color(0xFFFFD200)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 32)),
            const SizedBox(height: 10),
            Text(widget.firstName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Finance', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(widget.userId, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
        Expanded(child: ListView(children: [
          ListTile(leading: const Icon(Icons.dashboard_rounded, color: Color(0xFFF7971E)), title: Text('Dashboard', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.payments_rounded, color: Color(0xFFF7971E)), title: Text('Payroll', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.bar_chart_rounded, color: Color(0xFFF7971E)), title: Text('Reports', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
        ])),
        const Divider(),
        ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)), onTap: _logout),
      ])),
    );
  }
}
