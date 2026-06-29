import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:image_picker/image_picker.dart';

import 'md_models.dart';
import 'md_service.dart';

enum MdDashboardScreen {
  dashboard,
  meetings,
  calendar,
  timeSelection,
  meetingDetails,
  addParticipants,
  addAgenda,
  reviewMeeting,
  meetingScheduled,
  meetingList,
}

enum _MdStep { dashboard, meetings, calendar, time, details, participants, agenda, review, success, list }

enum _DashboardRole { md, employee }

int _mdDaysInMonth(DateTime date) {
  final nextMonth = date.month == 12 ? DateTime(date.year + 1, 1, 1) : DateTime(date.year, date.month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

bool _mdIsSameDate(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month && first.day == second.day;
}

String _mdClockLabel(DateTime time) {
  final hourValue = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hourValue:$minute $period';
}

class MdDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;
  final MdDashboardScreen initialScreen;

  const MdDashboard({
    super.key,
    required this.email,
    required this.firstName,
    required this.userId,
    this.initialScreen = MdDashboardScreen.dashboard,
  });

  @override
  State<MdDashboard> createState() => _MdDashboardState();
}

class _MdDashboardState extends State<MdDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final MdService _service = MdService();
  late MdMeeting _draft;
  MdDashboardData _data = MdDashboardData.empty;
  _MdStep _step = _MdStep.dashboard;
  _DashboardRole _dashboardRole = _DashboardRole.md;
  int _bottomIndex = 0;
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = _initialHour();
  int _selectedMinute = DateTime.now().minute;
  String _selectedPeriod = DateTime.now().hour >= 12 ? 'PM' : 'AM';
  String _duration = '1 Hour';
  File? _profileImage;

  static int _initialHour() {
    final hour = DateTime.now().hour;
    final value = hour % 12;
    return value == 0 ? 12 : value;
  }

  @override
  void initState() {
    super.initState();
    _draft = _emptyDraft();
    _step = _mapInitialScreen(widget.initialScreen);
    _bottomIndex = widget.initialScreen == MdDashboardScreen.meetings || widget.initialScreen == MdDashboardScreen.meetingList ? 3 : 0;
    _load();
  }

  MdMeeting _emptyDraft() {
    return MdMeeting.empty(
      dateLabel: _formatDate(_selectedDate),
      timeLabel: _formatTimeRange(),
      duration: _duration,
      participants: _data.participants,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  String _formatTimeRange() {
    final minute = _selectedMinute.toString().padLeft(2, '0');
    return '${_selectedHour.toString().padLeft(2, '0')}:$minute $_selectedPeriod';
  }

  _MdStep _mapInitialScreen(MdDashboardScreen screen) {
    switch (screen) {
      case MdDashboardScreen.dashboard:
        return _MdStep.dashboard;
      case MdDashboardScreen.meetings:
        return _MdStep.meetings;
      case MdDashboardScreen.calendar:
        return _MdStep.calendar;
      case MdDashboardScreen.timeSelection:
        return _MdStep.time;
      case MdDashboardScreen.meetingDetails:
        return _MdStep.details;
      case MdDashboardScreen.addParticipants:
        return _MdStep.participants;
      case MdDashboardScreen.addAgenda:
        return _MdStep.agenda;
      case MdDashboardScreen.reviewMeeting:
        return _MdStep.review;
      case MdDashboardScreen.meetingScheduled:
        return _MdStep.success;
      case MdDashboardScreen.meetingList:
        return _MdStep.list;
    }
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchDashboard(widget.userId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _draft = _draft.copyWith(participants: data.participants);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MD backend not connected: $e')),
      );
    }
  }

  Future<void> _schedule() async {
    try {
      final scheduled = await _service.scheduleMeeting(_draft, widget.userId);
      if (!mounted) return;
      setState(() {
        _draft = scheduled;
        _data = MdDashboardData(
          totalRevenue: _data.totalRevenue,
          totalEmployees: _data.totalEmployees,
          pendingApprovals: _data.pendingApprovals,
          meetingsToday: _data.meetingsToday + 1,
          meetings: [scheduled, ..._data.meetings.where((item) => item.id != scheduled.id)],
          participants: _data.participants,
        );
        _step = _MdStep.success;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting not saved: $e')),
      );
    }
  }

  void _toggleTheme() {
    MyApp.themeNotifier.value = MyApp.themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null || !mounted) return;
    setState(() {
      _profileImage = File(pickedImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _MdColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.bg,
        drawer: _MdDrawer(colors: colors, name: widget.firstName, email: widget.email, select: _setDrawerStep, logout: _logout),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(colors: colors, onMenu: () => _scaffoldKey.currentState?.openDrawer(), onTheme: _toggleTheme, onProfile: _pickProfileImage),
              if (_step == _MdStep.dashboard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: _RoleSelector(
                    colors: colors,
                    selectedRole: _dashboardRole,
                    onChanged: (role) => setState(() => _dashboardRole = role),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _loading
                      ? Center(child: CircularProgressIndicator(color: colors.primary))
                      : _buildStep(colors),
                ),
              ),
              _BottomNav(
                colors: colors,
                selectedIndex: _bottomIndex,
                onTap: (index) {
                  setState(() {
                    _bottomIndex = index;
                    _step = index == 3 ? _MdStep.meetings : _MdStep.dashboard;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setDrawerStep(_MdStep step) {
    Navigator.maybePop(context);
    setState(() {
      _step = step;
      _bottomIndex = step == _MdStep.meetings || step == _MdStep.list ? 3 : 0;
    });
  }

  Widget _buildStep(_MdColors colors) {
    switch (_step) {
      case _MdStep.dashboard:
        return _DashboardPage(
          key: const ValueKey('dashboard'),
          colors: colors,
          data: _data,
          name: widget.firstName,
          email: widget.email,
          userId: widget.userId,
          profileImage: _profileImage,
          selectedRole: _dashboardRole,
          onPickProfileImage: _pickProfileImage,
          onMeetings: () => setState(() => _step = _MdStep.meetings),
        );
      case _MdStep.meetings:
      case _MdStep.list:
        return _MeetingsPage(
          key: ValueKey(_step.name),
          colors: colors,
          meetings: _data.meetings,
          onCreate: () => setState(() => _step = _MdStep.calendar),
          onOpen: (meeting) => setState(() {
            _draft = meeting;
            _step = _MdStep.details;
          }),
        );
      case _MdStep.calendar:
        return _CalendarPage(
          colors: colors,
          selectedDate: _selectedDate,
          onDateChanged: (date) => setState(() {
            _selectedDate = date;
            _draft = _draft.copyWith(dateLabel: _formatDate(date));
          }),
          onNext: () => setState(() => _step = _MdStep.time),
        );
      case _MdStep.time:
        return _TimePage(
          colors: colors,
          selectedDateLabel: _formatDate(_selectedDate),
          selectedHour: _selectedHour,
          selectedMinute: _selectedMinute,
          selectedPeriod: _selectedPeriod,
          duration: _duration,
          onTimeChanged: (hour, minute, period) => setState(() {
            _selectedHour = hour;
            _selectedMinute = minute;
            _selectedPeriod = period;
            _draft = _draft.copyWith(timeLabel: _formatTimeRange(), duration: _duration);
          }),
          onNext: () => setState(() => _step = _MdStep.details),
        );
      case _MdStep.details:
        return _DetailsPage(
          colors: colors,
          draft: _draft,
          onChanged: (meeting) => _draft = meeting,
          onNext: () => setState(() => _step = _MdStep.participants),
        );
      case _MdStep.participants:
        return _ParticipantsPage(
          colors: colors,
          participants: _data.participants,
          onNext: (participants) => setState(() {
            _draft = _draft.copyWith(participants: participants);
            _step = _MdStep.agenda;
          }),
        );
      case _MdStep.agenda:
        return _AgendaPage(
          colors: colors,
          agenda: _draft.agenda,
          onNext: (agenda) => setState(() {
            _draft = _draft.copyWith(agenda: agenda);
            _step = _MdStep.review;
          }),
        );
      case _MdStep.review:
        return _ReviewPage(colors: colors, meeting: _draft, onSchedule: _schedule);
      case _MdStep.success:
        return _SuccessPage(
          colors: colors,
          meeting: _draft,
          onDone: () => setState(() => _step = _MdStep.list),
          onView: () => setState(() => _step = _MdStep.details),
        );
    }
  }
}

class _DashboardPage extends StatelessWidget {
  final _MdColors colors;
  final MdDashboardData data;
  final String name;
  final String email;
  final String userId;
  final File? profileImage;
  final _DashboardRole selectedRole;
  final VoidCallback onPickProfileImage;
  final VoidCallback onMeetings;

  const _DashboardPage({
    super.key,
    required this.colors,
    required this.data,
    required this.name,
    required this.email,
    required this.userId,
    required this.profileImage,
    required this.selectedRole,
    required this.onPickProfileImage,
    required this.onMeetings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _MdIdentityHeader(
          colors: colors,
          name: name,
          email: email,
          userId: userId,
          selectedRole: selectedRole,
          profileImage: profileImage,
          onPickProfileImage: onPickProfileImage,
        ),
        const SizedBox(height: 18),
        if (selectedRole == _DashboardRole.md)
          _MdRoleDashboardContent(colors: colors, data: data, onMeetings: onMeetings)
        else
          _EmployeeRoleDashboardContent(colors: colors, name: name, email: email, userId: userId),
      ],
    );
  }
}

class _MdIdentityHeader extends StatelessWidget {
  final _MdColors colors;
  final String name;
  final String email;
  final String userId;
  final _DashboardRole selectedRole;
  final File? profileImage;
  final VoidCallback onPickProfileImage;

  const _MdIdentityHeader({
    required this.colors,
    required this.name,
    required this.email,
    required this.userId,
    required this.selectedRole,
    required this.profileImage,
    required this.onPickProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'MD' : name.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: onPickProfileImage,
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primary.withAlpha(colors.isDark ? 65 : 30),
                      backgroundImage: profileImage == null ? null : FileImage(profileImage!),
                      child: profileImage == null ? Icon(Icons.person_rounded, color: colors.primary, size: 30) : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good ${colors.isDark ? 'Evening' : 'Morning'},', style: TextStyle(color: colors.muted, fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    if (userId.trim().isNotEmpty)
                      Text(
                        '${selectedRole == _DashboardRole.md ? 'MD' : 'Employee'} ID: $userId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    if (email.trim().isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final _MdColors colors;
  final _DashboardRole selectedRole;
  final ValueChanged<_DashboardRole> onChanged;

  const _RoleSelector({
    required this.colors,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedRole == _DashboardRole.md ? 'MD' : 'Employee';
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF07182A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DashboardRole>(
          value: selectedRole,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary),
          style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w900),
          selectedItemBuilder: (context) {
            return _DashboardRole.values.map((_) {
              return Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, color: colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Role Based', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(selectedLabel, overflow: TextOverflow.ellipsis)),
                ],
              );
            }).toList();
          },
          items: const [
            DropdownMenuItem(
              value: _DashboardRole.employee,
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Employee'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: _DashboardRole.md,
              child: Row(
                children: [
                  Icon(Icons.business_center_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('MD'),
                ],
              ),
            ),
          ],
          onChanged: (role) {
            if (role != null) onChanged(role);
          },
        ),
      ),
    );
  }
}

class _RoleOptionButton extends StatelessWidget {
  final _MdColors colors;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOptionButton({
    required this.colors,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : colors.muted, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MdRoleDashboardContent extends StatelessWidget {
  final _MdColors colors;
  final MdDashboardData data;
  final VoidCallback onMeetings;

  const _MdRoleDashboardContent({
    required this.colors,
    required this.data,
    required this.onMeetings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _MetricCard(colors: colors, title: 'Total Revenue', value: data.totalRevenue),
            _MetricCard(colors: colors, title: 'Total Employees', value: data.totalEmployees),
            _MetricCard(colors: colors, title: 'Pending Approvals', value: '${data.pendingApprovals}'),
            _MetricCard(colors: colors, title: 'Meetings Today', value: '${data.meetingsToday}', danger: true),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(colors: colors, title: 'Key Metrics', action: 'This Month'),
        const SizedBox(height: 12),
        _ChartCard(colors: colors),
        const SizedBox(height: 20),
        _SectionHeader(colors: colors, title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionButton(colors: colors, icon: Icons.verified_user_outlined, label: 'Approvals'),
            _ActionButton(colors: colors, icon: Icons.bar_chart_rounded, label: 'Reports'),
            _ActionButton(colors: colors, icon: Icons.analytics_outlined, label: 'Analytics'),
            _ActionButton(colors: colors, icon: Icons.more_horiz_rounded, label: 'More'),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryButton(colors: colors, label: 'Schedule Meeting', icon: Icons.add_rounded, onTap: onMeetings),
      ],
    );
  }
}

class _EmployeeRoleDashboardContent extends StatelessWidget {
  final _MdColors colors;
  final String name;
  final String email;
  final String userId;

  const _EmployeeRoleDashboardContent({
    required this.colors,
    required this.name,
    required this.email,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Employee' : name.trim();
    return Column(
      children: [
        _SectionHeader(colors: colors, title: 'Employee Profile'),
        const SizedBox(height: 12),
        _EmployeeInfoPanel(colors: colors, title: 'Name', value: displayName, icon: Icons.person_outline_rounded),
        _EmployeeInfoPanel(colors: colors, title: 'Employee ID', value: userId.trim().isEmpty ? 'Not available' : userId, icon: Icons.badge_outlined),
        _EmployeeInfoPanel(colors: colors, title: 'Email', value: email.trim().isEmpty ? 'Not available' : email, icon: Icons.mail_outline_rounded),
        const SizedBox(height: 20),
        _SectionHeader(colors: colors, title: 'Employee Dashboard'),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionButton(colors: colors, icon: Icons.access_time_rounded, label: 'Attendance'),
            _ActionButton(colors: colors, icon: Icons.beach_access_outlined, label: 'Leave'),
            _ActionButton(colors: colors, icon: Icons.assignment_outlined, label: 'Tasks'),
            _ActionButton(colors: colors, icon: Icons.more_horiz_rounded, label: 'More'),
          ],
        ),
      ],
    );
  }
}

class _EmployeeInfoPanel extends StatelessWidget {
  final _MdColors colors;
  final String title;
  final String value;
  final IconData icon;

  const _EmployeeInfoPanel({
    required this.colors,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(colors),
      child: Row(
        children: [
          _IconBox(colors: colors, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingsPage extends StatelessWidget {
  final _MdColors colors;
  final List<MdMeeting> meetings;
  final VoidCallback onCreate;
  final ValueChanged<MdMeeting> onOpen;

  const _MeetingsPage({super.key, required this.colors, required this.meetings, required this.onCreate, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 92),
          children: [
            _PageTitle(colors: colors, title: 'Meetings'),
            _Tabs(colors: colors),
            const SizedBox(height: 16),
            Text('Backend Meetings', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (meetings.isEmpty)
              _InfoPanel(colors: colors, title: 'No meetings', value: 'Create a meeting to save it in backend'),
            ...meetings.map((meeting) => _MeetingTile(colors: colors, meeting: meeting, onTap: () => onOpen(meeting))),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 22,
          child: FloatingActionButton(
            onPressed: onCreate,
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _CalendarPage extends StatelessWidget {
  final _MdColors colors;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  const _CalendarPage({
    required this.colors,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _mdDaysInMonth(selectedDate);
    final days = List.generate(daysInMonth, (index) => DateTime(selectedDate.year, selectedDate.month, index + 1));
    final monthLabel = '${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: colors, title: 'Select Date', center: true),
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              onPressed: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              icon: Icon(Icons.chevron_left_rounded, color: colors.muted),
            ),
            Expanded(child: Text(monthLabel, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontWeight: FontWeight.w900))),
            IconButton(
              onPressed: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1, 1)),
              icon: Icon(Icons.chevron_right_rounded, color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          children: days.map((date) {
            final selected = _mdIsSameDate(date, selectedDate);
            return Center(
              child: InkWell(
                onTap: () => onDateChanged(date),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: selected ? colors.primary : Colors.transparent, shape: BoxShape.circle),
                  child: Text('${date.day}', style: TextStyle(color: selected ? Colors.white : colors.text, fontWeight: selected ? FontWeight.w900 : FontWeight.w500)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _InfoPanel(colors: colors, title: 'Selected Date', value: '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}'),
        const SizedBox(height: 16),
        _PrimaryButton(colors: colors, label: 'Next', icon: Icons.arrow_forward_rounded, onTap: onNext),
      ],
    );
  }
}

class _TimePage extends StatelessWidget {
  final _MdColors colors;
  final String selectedDateLabel;
  final int selectedHour;
  final int selectedMinute;
  final String selectedPeriod;
  final String duration;
  final void Function(int hour, int minute, String period) onTimeChanged;
  final VoidCallback onNext;

  const _TimePage({
    required this.colors,
    required this.selectedDateLabel,
    required this.selectedHour,
    required this.selectedMinute,
    required this.selectedPeriod,
    required this.duration,
    required this.onTimeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(12, (index) => index + 1);
    final minutes = [0, 15, 30, 45];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: colors, title: 'Select Time', center: true),
        const SizedBox(height: 16),
        Center(child: _Pill(colors: colors, text: selectedDateLabel)),
        const SizedBox(height: 34),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TimeColumn(
              colors: colors,
              values: hours.map((hour) => hour.toString().padLeft(2, '0')).toList(),
              selected: selectedHour.toString().padLeft(2, '0'),
              onSelected: (value) => onTimeChanged(int.parse(value), selectedMinute, selectedPeriod),
            ),
            _TimeColumn(
              colors: colors,
              values: minutes.map((minute) => minute.toString().padLeft(2, '0')).toList(),
              selected: selectedMinute.toString().padLeft(2, '0'),
              onSelected: (value) => onTimeChanged(selectedHour, int.parse(value), selectedPeriod),
            ),
            _TimeColumn(
              colors: colors,
              values: const ['AM', 'PM'],
              selected: selectedPeriod,
              onSelected: (value) => onTimeChanged(selectedHour, selectedMinute, value),
            ),
          ],
        ),
        const SizedBox(height: 34),
        _InfoPanel(colors: colors, title: 'Duration', value: duration),
        const SizedBox(height: 18),
        _PrimaryButton(colors: colors, label: 'Next', icon: Icons.arrow_forward_rounded, onTap: onNext),
      ],
    );
  }
}

class _DetailsPage extends StatefulWidget {
  final _MdColors colors;
  final MdMeeting draft;
  final ValueChanged<MdMeeting> onChanged;
  final VoidCallback onNext;

  const _DetailsPage({required this.colors, required this.draft, required this.onChanged, required this.onNext});

  @override
  State<_DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<_DetailsPage> {
  late final TextEditingController _title = TextEditingController(text: widget.draft.title);
  late final TextEditingController _meetingType = TextEditingController(text: widget.draft.meetingType);
  late final TextEditingController _location = TextEditingController(text: widget.draft.location);
  late final TextEditingController _description = TextEditingController(text: widget.draft.description);

  @override
  void dispose() {
    _title.dispose();
    _meetingType.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _next() {
    widget.onChanged(widget.draft.copyWith(
      title: _title.text,
      meetingType: _meetingType.text,
      location: _location.text,
      description: _description.text,
    ));
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: colors, title: 'Meeting Details', center: true),
        _Field(colors: colors, label: 'Meeting Title', controller: _title),
        _Field(colors: colors, label: 'Meeting Type', controller: _meetingType),
        _Field(colors: colors, label: 'Location', controller: _location, suffix: Icons.location_on_outlined),
        _Field(colors: colors, label: 'Add Description (Optional)', controller: _description, maxLines: 4),
        const SizedBox(height: 14),
        _PrimaryButton(colors: colors, label: 'Next', icon: Icons.arrow_forward_rounded, onTap: _next),
      ],
    );
  }
}

class _ParticipantsPage extends StatefulWidget {
  final _MdColors colors;
  final List<MdParticipant> participants;
  final ValueChanged<List<MdParticipant>> onNext;

  const _ParticipantsPage({required this.colors, required this.participants, required this.onNext});

  @override
  State<_ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<_ParticipantsPage> {
  late List<MdParticipant> _participants = widget.participants;

  @override
  Widget build(BuildContext context) {
    final selected = _participants.where((item) => item.selected).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: widget.colors, title: 'Add Participants', center: true),
        _SearchBox(colors: widget.colors),
        const SizedBox(height: 12),
        ...List.generate(_participants.length, (index) {
          final item = _participants[index];
          return _ParticipantTile(
            colors: widget.colors,
            participant: item,
            onTap: () => setState(() => _participants[index] = item.copyWith(selected: !item.selected)),
          );
        }),
        const SizedBox(height: 18),
        _PrimaryButton(colors: widget.colors, label: 'Next ($selected)', icon: Icons.arrow_forward_rounded, onTap: () => widget.onNext(_participants)),
      ],
    );
  }
}

class _AgendaPage extends StatefulWidget {
  final _MdColors colors;
  final List<String> agenda;
  final ValueChanged<List<String>> onNext;

  const _AgendaPage({required this.colors, required this.agenda, required this.onNext});

  @override
  State<_AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<_AgendaPage> {
  late final List<TextEditingController> _controllers =
      widget.agenda.map((item) => TextEditingController(text: item)).toList();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addAgendaItem() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _next() {
    final agenda = _controllers.map((controller) => controller.text.trim()).where((item) => item.isNotEmpty).toList();
    widget.onNext(agenda);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: widget.colors, title: 'Add Agenda', center: true),
        const SizedBox(height: 8),
        ...List.generate(_controllers.length, (index) => _AgendaField(colors: widget.colors, index: index + 1, controller: _controllers[index])),
        TextButton.icon(
          onPressed: _addAgendaItem,
          icon: Icon(Icons.add_rounded, color: widget.colors.primary, size: 18),
          label: Text('Add Agenda Item', style: TextStyle(color: widget.colors.primary, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 18),
        _PrimaryButton(colors: widget.colors, label: 'Next', icon: Icons.arrow_forward_rounded, onTap: _next),
      ],
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final _MdColors colors;
  final MdMeeting meeting;
  final VoidCallback onSchedule;

  const _ReviewPage({required this.colors, required this.meeting, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _PageTitle(colors: colors, title: 'Review Meeting', center: true),
        _ReviewRow(colors: colors, icon: Icons.title_rounded, title: 'Title', value: meeting.title),
        _ReviewRow(colors: colors, icon: Icons.calendar_today_rounded, title: 'Date', value: meeting.dateLabel),
        _ReviewRow(colors: colors, icon: Icons.schedule_rounded, title: 'Time', value: meeting.timeLabel),
        _ReviewRow(colors: colors, icon: Icons.location_on_outlined, title: 'Location', value: meeting.location),
        _ReviewRow(colors: colors, icon: Icons.people_outline_rounded, title: 'Participants', value: '${meeting.participants.where((item) => item.selected).length} Selected'),
        _ReviewRow(colors: colors, icon: Icons.list_alt_rounded, title: 'Agenda', value: '${meeting.agenda.length} Agenda Items'),
        const SizedBox(height: 18),
        _PrimaryButton(colors: colors, label: 'Schedule Meeting', icon: Icons.event_available_rounded, onTap: onSchedule),
      ],
    );
  }
}

class _SuccessPage extends StatelessWidget {
  final _MdColors colors;
  final MdMeeting meeting;
  final VoidCallback onView;
  final VoidCallback onDone;

  const _SuccessPage({required this.colors, required this.meeting, required this.onView, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, color: colors.primary, size: 86),
          const SizedBox(height: 14),
          Icon(Icons.check_circle_rounded, color: colors.success, size: 44),
          const SizedBox(height: 18),
          Text('Meeting Scheduled\nSuccessfully!', textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Text(meeting.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${meeting.dateLabel} - ${meeting.timeLabel}', textAlign: TextAlign.center, style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _SecondaryButton(colors: colors, label: 'View Meeting', onTap: onView)),
              const SizedBox(width: 12),
              Expanded(child: _PrimaryButton(colors: colors, label: 'Done', icon: Icons.check_rounded, onTap: onDone)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final _MdColors colors;
  final VoidCallback onMenu;
  final VoidCallback onTheme;
  final VoidCallback onProfile;

  const _TopBar({required this.colors, required this.onMenu, required this.onTheme, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final timeLabel = _mdClockLabel(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: const BitByteLogo(size: 28, showSubtitle: false, compact: true),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MD Dashboard', style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w900)),
              Text(timeLabel, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: onTheme, icon: Icon(colors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: colors.text, size: 20)),
          IconButton(onPressed: onProfile, icon: Icon(Icons.account_circle_outlined, color: colors.text, size: 22)),
        ],
      ),
    );
  }
}

class _MdDrawer extends StatelessWidget {
  final _MdColors colors;
  final String name;
  final String email;
  final ValueChanged<_MdStep> select;
  final VoidCallback logout;

  const _MdDrawer({required this.colors, required this.name, required this.email, required this.select, required this.logout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const BitByteLogo(compact: true),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.trim().isEmpty ? 'MD' : name.trim(), overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w900)),
                Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 11)),
              ])),
            ]),
          ),
          Divider(color: colors.border),
          Expanded(
            child: ListView(children: [
              _MdDrawerTile(colors: colors, icon: Icons.dashboard_rounded, title: 'Dashboard', onTap: () => select(_MdStep.dashboard)),
              _MdDrawerTile(colors: colors, icon: Icons.event_note_rounded, title: 'Schedule Meeting', onTap: () => select(_MdStep.meetings)),
              _MdDrawerTile(colors: colors, icon: Icons.list_alt_rounded, title: 'Meeting List', onTap: () => select(_MdStep.list)),
              _MdDrawerTile(colors: colors, icon: Icons.calendar_month_rounded, title: 'Calendar', onTap: () => select(_MdStep.calendar)),
            ]),
          ),
          Divider(color: colors.border),
          ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)), onTap: logout),
        ]),
      ),
    );
  }
}

class _MdDrawerTile extends StatelessWidget {
  final _MdColors colors;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MdDrawerTile({required this.colors, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: colors.primary), title: Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)), onTap: onTap);
  }
}

class _BottomNav extends StatelessWidget {
  final _MdColors colors;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.colors, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BottomNavEntry(Icons.home_outlined, 'Dashboard'),
      _BottomNavEntry(Icons.analytics_outlined, 'Analytics'),
      _BottomNavEntry(Icons.groups_outlined, 'Employees'),
      _BottomNavEntry(Icons.calendar_today_outlined, 'Meetings'),
      _BottomNavEntry(Icons.description_outlined, 'Reports'),
      _BottomNavEntry(Icons.verified_outlined, 'Approvals'),
      _BottomNavEntry(Icons.more_horiz_rounded, 'More'),
    ];
    return Container(
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 10),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 46,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index].icon, color: selected ? colors.primary : colors.muted, size: 18),
                    const SizedBox(height: 3),
                    FittedBox(child: Text(items[index].label, style: TextStyle(color: selected ? colors.primary : colors.muted, fontSize: 10, fontWeight: FontWeight.w700))),
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

class _BottomNavEntry {
  final IconData icon;
  final String label;

  const _BottomNavEntry(this.icon, this.label);
}

class _MetricCard extends StatelessWidget {
  final _MdColors colors;
  final String title;
  final String value;
  final String? trend;
  final bool danger;

  const _MetricCard({required this.colors, required this.title, required this.value, this.trend, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: danger ? colors.danger : colors.text, fontSize: 18, fontWeight: FontWeight.w900))),
              if (trend != null) Text(trend!, style: TextStyle(color: colors.success, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final _MdColors colors;

  const _ChartCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final points = [0.3, 0.55, 0.42, 0.7, 0.46, 0.54, 0.5, 0.6];
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FractionallySizedBox(heightFactor: point, alignment: Alignment.bottomCenter, child: Container(decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)))),
        ))).toList(),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final _MdColors colors;
  final MdMeeting meeting;
  final VoidCallback onTap;

  const _MeetingTile({required this.colors, required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _box(colors),
          child: Row(
            children: [
              _IconBox(colors: colors, icon: Icons.event_note_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meeting.title, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${meeting.dateLabel}, ${meeting.timeLabel}', overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 11)),
                    Text(meeting.location, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final _MdColors colors;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final IconData? suffix;

  const _Field({required this.colors, required this.label, required this.controller, this.maxLines = 1, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.text, fontSize: 13),
            decoration: InputDecoration(
              suffixIcon: suffix == null ? null : Icon(suffix, color: colors.muted, size: 18),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final _MdColors colors;
  final MdParticipant participant;
  final VoidCallback onTap;

  const _ParticipantTile({required this.colors, required this.participant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = participant.name.trim().isEmpty ? '?' : participant.name.trim().substring(0, 1);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: colors.primary.withAlpha(45), child: Text(initial, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900))),
      title: Text(participant.name, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 13)),
      subtitle: Text(participant.role, style: TextStyle(color: colors.muted, fontSize: 11)),
      trailing: Checkbox(value: participant.selected, activeColor: colors.primary, onChanged: (_) => onTap()),
      onTap: onTap,
    );
  }
}

class _AgendaField extends StatelessWidget {
  final _MdColors colors;
  final int index;
  final TextEditingController controller;

  const _AgendaField({required this.colors, required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _box(colors),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixText: '$index. ',
          prefixStyle: TextStyle(color: colors.muted, fontSize: 13, fontWeight: FontWeight.w800),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(13),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final _MdColors colors;
  final IconData icon;
  final String title;
  final String value;

  const _ReviewRow({required this.colors, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _IconBox(colors: colors, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final _MdColors colors;
  final String title;
  final String? action;

  const _SectionHeader({required this.colors, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w900))),
      if (action != null) Text(action!, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _PageTitle extends StatelessWidget {
  final _MdColors colors;
  final String title;
  final bool center;

  const _PageTitle({required this.colors, required this.title, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(title, textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }
}

class _Tabs extends StatelessWidget {
  final _MdColors colors;

  const _Tabs({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
      child: Row(children: ['Upcoming', 'Past', 'Cancelled'].map((tab) {
        final active = tab == 'Upcoming';
        return Expanded(child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? colors.primary : Colors.transparent, borderRadius: BorderRadius.circular(7)),
          child: Text(tab, style: TextStyle(color: active ? Colors.white : colors.text, fontSize: 11, fontWeight: FontWeight.w800)),
        ));
      }).toList()),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final _MdColors colors;

  const _SearchBox({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _box(colors),
      child: Row(children: [Icon(Icons.search_rounded, color: colors.muted, size: 18), const SizedBox(width: 8), Text('Search participants...', style: TextStyle(color: colors.muted, fontSize: 12))]),
    );
  }
}

class _Pill extends StatelessWidget {
  final _MdColors colors;
  final String text;

  const _Pill({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: colors.border)),
      child: Text(text, style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final _MdColors colors;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _TimeColumn({
    required this.colors,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.map((value) {
        final active = value == selected;
        return InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              value,
              style: TextStyle(
                color: active ? colors.primary : colors.muted,
                fontSize: active ? 22 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final _MdColors colors;
  final String title;
  final String value;

  const _InfoPanel({required this.colors, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(colors),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final _MdColors colors;
  final IconData icon;
  final String label;

  const _ActionButton({required this.colors, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(height: 6),
          FittedBox(child: Text(label, style: TextStyle(color: colors.text, fontSize: 11, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final _MdColors colors;
  final IconData icon;

  const _IconBox({required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: colors.primary.withAlpha(colors.isDark ? 55 : 28), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: colors.primary, size: 18),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final _MdColors colors;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.colors, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: FittedBox(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final _MdColors colors;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.colors, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: colors.primary, side: BorderSide(color: colors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: FittedBox(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
      ),
    );
  }
}

BoxDecoration _box(_MdColors colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: colors.border),
    boxShadow: colors.shadow,
  );
}

class _MdColors {
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Color success;
  final Color danger;
  final List<BoxShadow> shadow;

  const _MdColors({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.success,
    required this.danger,
    required this.shadow,
  });

  factory _MdColors.of(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    if (isDark) {
      return const _MdColors(
        isDark: true,
        bg: Color(0xFF06111E),
        surface: Color(0xFF0D1B2C),
        text: Color(0xFFF8FAFC),
        muted: Color(0xFF8A9AAF),
        border: Color(0xFF20334B),
        primary: Color(0xFF7C3AED),
        success: Color(0xFF34D399),
        danger: Color(0xFFFF5A70),
        shadow: [],
      );
    }
    return _MdColors(
      isDark: false,
      bg: const Color(0xFFF8FBFF),
      surface: Colors.white,
      text: const Color(0xFF0F172A),
      muted: const Color(0xFF64748B),
      border: const Color(0xFFE2E8F0),
      primary: const Color(0xFF0B63F6),
      success: const Color(0xFF10B981),
      danger: const Color(0xFFEF233C),
      shadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 6))],
    );
  }
}
