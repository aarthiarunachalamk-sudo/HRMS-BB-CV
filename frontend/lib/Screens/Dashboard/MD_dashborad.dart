import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class MdDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;
  const MdDashboard({super.key, required this.email, required this.firstName, required this.userId});

  @override
  State<MdDashboard> createState() => _MdDashboardState();
}

class _MdDashboardState extends State<MdDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _statsCards = [
    {'title': 'Total Employees', 'value': '0', 'icon': Icons.people_rounded, 'color': Color(0xFF4FACFE)},
    {'title': 'Present Today', 'value': '0', 'icon': Icons.check_circle_rounded, 'color': Color(0xFF43E97B)},
    {'title': 'On Leave', 'value': '0', 'icon': Icons.beach_access_rounded, 'color': Color(0xFFFA709A)},
    {'title': 'Projects', 'value': '0', 'icon': Icons.folder_rounded, 'color': Color(0xFFA18CD1)},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.people_alt_rounded, 'label': 'Employees'},
    {'icon': Icons.calendar_today_rounded, 'label': 'Attendance'},
    {'icon': Icons.beach_access_rounded, 'label': 'Leave'},
    {'icon': Icons.folder_rounded, 'label': 'Projects'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Reports'},
  ];

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(textPrimary, textSecondary, cardBg, isDark),
      body: ConstellationBackground(
        accentColor: ThemeConfig.blueAccent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: ThemeConfig.blueGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${widget.firstName}', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(widget.userId, style: TextStyle(color: ThemeConfig.blueAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: ThemeConfig.blueAccent),
                      onPressed: () {
                        final currentMode = MyApp.themeNotifier.value;
                        MyApp.themeNotifier.value = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Managing Director', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('Overview', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: _statsCards.length,
                        itemBuilder: (context, index) {
                          final card = _statsCards[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder, width: 1.2),
                              boxShadow: ThemeConfig.getPremiumShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(card['icon'], color: card['color'], size: 28),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card['value'], style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                                    Text(card['title'], style: TextStyle(color: textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(Color textPrimary, Color textSecondary, Color cardBg, bool isDark) {
    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.firstName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('MD', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _menuItems.map((item) {
                  return ListTile(
                    leading: Icon(item['icon'], color: const Color(0xFFA18CD1)),
                    title: Text(item['label'], style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
                    onTap: () => Navigator.pop(context),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
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
}