import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_attendance_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_create_employee_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_documents_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_employees_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_leave_requests_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_meetings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_onboarding_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_payroll_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_performance_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_profile_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_recruitment_pipeline_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_recruitment_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_schedule_interview_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_shared.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_tasks_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_training_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:image_picker/image_picker.dart';

class HrDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const HrDashboard({super.key, required this.email, required this.firstName, required this.userId});

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<Map<String, dynamic>> _future;
  int _index = 0;
  String _role = 'HR';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _future = HrService().fetchDashboard(widget.userId);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _toggleTheme() {
    MyApp.themeNotifier.value = MyApp.themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final pages = [
            _HrHome(data: data, name: widget.firstName, email: widget.email, profileImage: _profileImage, onProfileTap: _pickProfileImage, onOpen: _setIndex),
            const HrCreateEmployeeScreen(),
            HrEmployeesScreen(data: data),
            HrAttendanceScreen(data: data),
            HrLeaveRequestsScreen(data: data),
            HrRecruitmentScreen(data: data, onPipeline: () => _setIndex(7), onSchedule: () => _setIndex(8)),
            HrMeetingsScreen(data: data),
            HrRecruitmentPipelineScreen(data: data),
            HrScheduleInterviewScreen(data: data),
            HrOnboardingScreen(data: data),
            HrDocumentsScreen(data: data),
            HrPerformanceScreen(data: data),
            HrPayrollScreen(data: data),
            HrTrainingScreen(data: data),
            HrTasksScreen(data: data),
            HrProfileScreen(email: widget.email, name: widget.firstName, onLogout: _logout),
          ];

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: c.bg,
            drawer: _HrDrawer(data: data, email: widget.email, onTap: _setIndex, onLogout: _logout),
            body: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.bg, c.bgAlt], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(colors: c, title: _titles[_index], onMenu: () => _scaffoldKey.currentState?.openDrawer(), onTheme: _toggleTheme, onProfile: _pickProfileImage),
                    _HrRoleDropdown(
                      colors: c,
                      value: _role,
                      onChanged: (value) => setState(() => _role = value),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting) LinearProgressIndicator(minHeight: 2, color: c.primary, backgroundColor: Colors.transparent),
                    if (snapshot.hasError) Padding(padding: const EdgeInsets.all(8), child: Text('Backend data unavailable', style: TextStyle(color: c.danger, fontSize: 11, fontWeight: FontWeight.w800))),
                    Expanded(child: pages[_index]),
                    _BottomNav(colors: c, index: _index, onTap: _setIndex),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _setIndex(int value) {
    Navigator.maybePop(context);
    setState(() => _index = value);
  }
}

class _HrHome extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final String email;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final ValueChanged<int> onOpen;

  const _HrHome({required this.data, required this.name, required this.email, required this.profileImage, required this.onProfileTap, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Row(children: [
          _HrProfileAvatar(image: profileImage, radius: 28, onTap: onProfileTap),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good Morning,', style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(name.trim().isEmpty ? 'HR Manager' : name, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            HrMetricCard(title: 'Total Employees', value: hrText(data, 'total_employees'), icon: Icons.groups_rounded, color: c.primary),
            HrMetricCard(title: 'Present Today', value: hrText(data, 'present_today'), icon: Icons.verified_user_rounded, color: c.success),
            HrMetricCard(title: 'Absent Today', value: hrText(data, 'absent_today'), icon: Icons.person_off_rounded, color: c.danger),
            HrMetricCard(title: 'On Leave', value: hrText(data, 'on_leave'), icon: Icons.beach_access_rounded, color: c.purple),
          ],
        ),
        const SizedBox(height: 16),
        Text('Quick Actions', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: [
          _Action(icon: Icons.person_add_alt_1_rounded, label: 'Create', color: c.primary, onTap: () => onOpen(1)),
          _Action(icon: Icons.event_available_rounded, label: 'Approve Leave', color: c.warning, onTap: () => onOpen(4)),
          _Action(icon: Icons.calendar_month_rounded, label: 'Attendance', color: c.success, onTap: () => onOpen(3)),
          _Action(icon: Icons.work_outline_rounded, label: 'Recruitment', color: c.purple, onTap: () => onOpen(5)),
        ]),
        const SizedBox(height: 16),
        Text('Upcoming', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...hrList(data, 'upcoming').map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HrListTile(icon: Icons.event_note_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['time']}', color: c.primary),
            )),
        if (hrList(data, 'notifications').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Meeting Notifications', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...hrList(data, 'notifications').map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HrListTile(icon: Icons.notifications_active_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['time']}', color: c.danger),
              )),
        ],
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 72,
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 7),
            FittedBox(child: Text(label, style: TextStyle(color: c.text, fontSize: 10, fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}

class _HrProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _HrProfileAvatar({required this.image, required this.radius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: c.primary.withAlpha(30),
        backgroundImage: image == null ? null : FileImage(image!),
        child: image == null ? Icon(Icons.person_rounded, color: c.primary, size: radius) : null,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final HrPalette colors;
  final String title;
  final VoidCallback onMenu;
  final VoidCallback onTheme;
  final VoidCallback onProfile;

  const _TopBar({required this.colors, required this.title, required this.onMenu, required this.onTheme, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(children: [
        InkWell(onTap: onMenu, borderRadius: BorderRadius.circular(8), child: const Padding(padding: EdgeInsets.all(4), child: BitByteLogo(compact: true))),
        const SizedBox(width: 12),
        Expanded(child: Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w900))),
        IconButton(onPressed: onTheme, icon: Icon(colors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: colors.primary)),
        IconButton(onPressed: onProfile, icon: Icon(Icons.account_circle_outlined, color: colors.text)),
      ]),
    );
  }
}

class _HrRoleDropdown extends StatelessWidget {
  final HrPalette colors;
  final String value;
  final ValueChanged<String> onChanged;

  const _HrRoleDropdown({required this.colors, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: colors.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary),
            style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w900),
            selectedItemBuilder: (context) {
              return ['Employee', 'HR'].map((_) {
                return Row(children: [
                  Icon(Icons.admin_panel_settings_outlined, color: colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Role Based', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
                ]);
              }).toList();
            },
            items: const [
              DropdownMenuItem(value: 'Employee', child: Row(children: [Icon(Icons.person_outline_rounded, size: 18), SizedBox(width: 8), Text('Employee')])),
              DropdownMenuItem(value: 'HR', child: Row(children: [Icon(Icons.badge_outlined, size: 18), SizedBox(width: 8), Text('HR')])),
            ],
            onChanged: (role) {
              if (role != null) onChanged(role);
            },
          ),
        ),
      ),
    );
  }
}

class _HrDrawer extends StatelessWidget {
  final Map<String, dynamic> data;
  final String email;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _HrDrawer({required this.data, required this.email, required this.onTap, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const BitByteLogo(compact: true),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HR Manager', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
                Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11)),
              ])),
            ]),
          ),
          Divider(color: c.border),
          Expanded(
            child: ListView(
              children: List.generate(_titles.length, (index) {
                return ListTile(
                  leading: Icon(_icons[index], color: c.primary, size: 19),
                  title: Text(_titles[index], style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
          Divider(color: c.border),
          ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)), onTap: onLogout),
        ]),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final HrPalette colors;
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.colors, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [0, 2, 3, 10, 15];
    return Container(
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
      child: Row(
        children: items.map((itemIndex) {
          final selected = index == itemIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(itemIndex),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 48,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_icons[itemIndex], color: selected ? colors.primary : colors.muted, size: 18),
                  const SizedBox(height: 3),
                  FittedBox(child: Text(_titles[itemIndex], style: TextStyle(color: selected ? colors.primary : colors.muted, fontSize: 10, fontWeight: FontWeight.w800))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

const _titles = [
  'Dashboard',
  'Create Employee',
  'Employees',
  'Attendance',
  'Leave Requests',
  'Recruitment',
  'Meetings',
  'Recruitment Pipeline',
  'Schedule Interview',
  'Onboarding',
  'Documents',
  'Performance',
  'Payroll',
  'Training',
  'Tasks',
  'Profile',
];

const _icons = [
  Icons.dashboard_rounded,
  Icons.person_add_alt_1_rounded,
  Icons.groups_rounded,
  Icons.calendar_month_rounded,
  Icons.beach_access_rounded,
  Icons.work_outline_rounded,
  Icons.event_rounded,
  Icons.filter_alt_rounded,
  Icons.video_call_rounded,
  Icons.assignment_ind_rounded,
  Icons.folder_rounded,
  Icons.insights_rounded,
  Icons.payments_rounded,
  Icons.school_rounded,
  Icons.task_alt_rounded,
  Icons.account_circle_rounded,
];
