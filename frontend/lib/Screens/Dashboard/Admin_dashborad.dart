import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class AdminDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;
  const AdminDashboard({super.key, required this.email, required this.firstName, required this.userId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _logout() => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    const color = Color(0xFF4FACFE);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(textPrimary, cardBg),
      body: ConstellationBackground(
        accentColor: color,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Welcome, ${widget.firstName}', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(widget.userId, style: const TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Text('Admin Overview', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                      children: [
                        _card('Users', '0', Icons.people_rounded, color, cardBg, cardBorder, textPrimary, textSecondary),
                        _card('Tasks', '0', Icons.task_rounded, const Color(0xFF43E97B), cardBg, cardBorder, textPrimary, textSecondary),
                        _card('Reports', '0', Icons.bar_chart_rounded, const Color(0xFFF7971E), cardBg, cardBorder, textPrimary, textSecondary),
                        _card('Settings', '0', Icons.settings_rounded, const Color(0xFFFA709A), cardBg, cardBorder, textPrimary, textSecondary),
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

  Widget _card(String title, String value, IconData icon, Color color, Color cardBg, Color cardBorder, Color tp, Color ts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 28),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: tp, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: ts, fontSize: 11)),
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
          decoration: BoxDecoration(gradient: ThemeConfig.blueGradient),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 32)),
            const SizedBox(height: 10),
            Text(widget.firstName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Admin', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(widget.userId, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
        Expanded(child: ListView(children: [
          ListTile(leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF4FACFE)), title: Text('Dashboard', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.people_rounded, color: Color(0xFF4FACFE)), title: Text('Users', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.settings_rounded, color: Color(0xFF4FACFE)), title: Text('Settings', style: TextStyle(color: textPrimary)), onTap: () => Navigator.pop(context)),
        ])),
        const Divider(),
        ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)), onTap: _logout),
      ])),
    );
  }
}
