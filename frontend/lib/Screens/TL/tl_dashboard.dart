import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/logo_widget.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/TL/tl_service.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/TL/tl_shared.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:image_picker/image_picker.dart';

class TLDashboard extends StatefulWidget {
  final String email;
  final String firstName;
  final String userId;

  const TLDashboard({super.key, required this.email, required this.firstName, required this.userId});

  @override
  State<TLDashboard> createState() => _TLDashboardState();
}

class _TLDashboardState extends State<TLDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<Map<String, dynamic>> _future;
  int _index = 0;
  Map<String, dynamic> _selected = {};
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _future = TlService().fetchDashboard(widget.userId);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _toggleTheme() {
    MyApp.themeNotifier.value = MyApp.themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  void _openDetail(int index, Map<String, dynamic> item) {
    setState(() {
      _selected = item;
      _index = index;
    });
  }

  void _refreshDashboard() {
    setState(() {
      _future = TlService().fetchDashboard(widget.userId);
    });
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedImage == null || !mounted) return;
    setState(() => _profileImage = File(pickedImage.path));
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final pages = [
            _Dashboard(data: data, name: widget.firstName, email: widget.email, profileImage: _profileImage, onProfileTap: _pickProfileImage, open: _setIndex),
            _Team(data: data, open: (item) => _openDetail(17, item)),
            _Tasks(data: data, open: (item) => _openDetail(14, item), create: () => _setIndex(15)),
            _Projects(data: data, open: (item) => _openDetail(16, item)),
            _Attendance(data: data, openSelfie: () => _setIndex(5), openReport: () => _setIndex(11)),
            _Selfie(openNext: () => _setIndex(6)),
            _GeoLocation(data: data, openNext: () => _setIndex(7)),
            _ConfirmAttendance(data: data, openNext: () => _setIndex(8)),
            _AttendanceMarked(data: data, openAttendance: () => _setIndex(4)),
            _Leave(data: data),
            _Meetings(data: data, userId: widget.userId, email: widget.email, open: (item) => _openDetail(18, item), scheduled: _refreshDashboard),
            _Reports(data: data, open: (item) => _openDetail(18, item)),
            _Approvals(data: data),
            _Notifications(data: data),
            _TaskDetails(item: _selected, update: () => _setIndex(2)),
            _CreateTask(data: data, submit: () => _setIndex(2)),
            _ProjectDetails(item: _selected, openTasks: () => _setIndex(2)),
            _TeamPerformance(data: data),
            _GenericDetails(item: _selected),
            _Profile(email: widget.email, name: widget.firstName, profileImage: _profileImage, onProfileTap: _pickProfileImage, logout: _logout),
          ];
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: c.bg,
            drawer: _Drawer(email: widget.email, name: widget.firstName, select: _setIndex, logout: _logout),
            body: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.bg, c.bgAlt], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: SafeArea(
                child: Column(children: [
                  _TopBar(c: c, title: _titles[_index], menu: () => _scaffoldKey.currentState?.openDrawer(), theme: _toggleTheme, profile: _pickProfileImage),
                  if (snapshot.connectionState == ConnectionState.waiting) LinearProgressIndicator(minHeight: 2, color: c.primary, backgroundColor: Colors.transparent),
                  if (snapshot.hasError) Padding(padding: const EdgeInsets.all(8), child: Text('Backend data unavailable', style: TextStyle(color: c.danger, fontSize: 11, fontWeight: FontWeight.w800))),
                  Expanded(child: pages[_index]),
                  _BottomNav(c: c, index: _index, select: _setIndex),
                ]),
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

class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final String email;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final ValueChanged<int> open;

  const _Dashboard({required this.data, required this.name, required this.email, required this.profileImage, required this.onProfileTap, required this.open});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      Row(children: [
        _ProfileAvatar(image: profileImage, radius: 28, onTap: onProfileTap),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good Morning,', style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          Text(name.trim(), overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: [
          _Metric('My Tasks', tlText(data, 'my_tasks'), c.primary, Icons.task_alt_rounded, () => open(2)),
          _Metric('Members', tlText(data, 'members_count'), c.success, Icons.groups_rounded, () => open(1)),
          _Metric('Projects', tlText(data, 'projects_count'), c.purple, Icons.work_rounded, () => open(3)),
          _Metric('Pending Approvals', tlText(data, 'pending_approvals'), c.danger, Icons.approval_rounded, () => open(12)),
        ],
      ),
      const SizedBox(height: 14),
      _Section(title: 'Tasks Overview', action: 'View All', onTap: () => open(2)),
      _ProgressCard(value: tlPercent(data, 'tasks_progress'), label: '${tlText(data, 'tasks_done')} done'),
      const SizedBox(height: 14),
      _Section(title: 'Team Performance', action: 'View', onTap: () => open(17)),
      _ProgressCard(value: tlPercent(data, 'team_progress'), label: '${tlText(data, 'on_track')} on track'),
    ]);
  }
}

class _Team extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;

  const _Team({required this.data, required this.open});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'team'), icon: Icons.person_rounded, color: c.primary, onTap: open);
  }
}

class _Tasks extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback create;

  const _Tasks({required this.data, required this.open, required this.create});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Stack(children: [
      _ListPage(items: tlList(data, 'tasks'), icon: Icons.task_alt_rounded, color: c.danger, onTap: open),
      Positioned(right: 16, bottom: 16, child: FloatingActionButton(onPressed: create, backgroundColor: c.primary, child: const Icon(Icons.add_rounded, color: Colors.white))),
    ]);
  }
}

class _Projects extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;

  const _Projects({required this.data, required this.open});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'projects'), icon: Icons.work_rounded, color: c.primary, onTap: open);
  }
}

class _Attendance extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openSelfie;
  final VoidCallback openReport;

  const _Attendance({required this.data, required this.openSelfie, required this.openReport});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Checked In', style: TextStyle(color: c.success, fontSize: 12, fontWeight: FontWeight.w900)),
        Text(tlText(data, 'check_in'), style: TextStyle(color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(tlText(data, 'location'), style: TextStyle(color: c.muted, fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      _Calendar(month: tlText(data, 'calendar_month'), day: '${data['calendar_day'] ?? ''}'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white), onPressed: openSelfie, child: const Text('Check-Out'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: openReport, child: const Text('View Full Report'))),
      ]),
    ]);
  }
}

class _Selfie extends StatelessWidget {
  final VoidCallback openNext;
  const _Selfie({required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        CircleAvatar(radius: 70, backgroundColor: c.primary.withAlpha(30), child: Icon(Icons.face_rounded, color: c.primary, size: 70)),
        const SizedBox(height: 12),
        Text('Please ensure your face is clearly visible', style: TextStyle(color: c.muted, fontSize: 12)),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)), onPressed: openNext, child: const Text('Capture Photo')),
    ]);
  }
}

class _GeoLocation extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openNext;
  const _GeoLocation({required this.data, required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        Container(height: 190, alignment: Alignment.center, decoration: BoxDecoration(color: c.row, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.location_on_rounded, color: c.primary, size: 54)),
        const SizedBox(height: 12),
        Text(tlText(data, 'location'), style: TextStyle(color: c.text, fontWeight: FontWeight.w900)),
        Text('Accuracy: ${tlText(data, 'accuracy')}', style: TextStyle(color: c.success, fontSize: 12)),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)), onPressed: openNext, child: const Text('Confirm Location')),
    ]);
  }
}

class _ConfirmAttendance extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openNext;
  const _ConfirmAttendance({required this.data, required this.openNext});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Info('Check In Time', tlText(data, 'check_in')),
        _Info('Location', tlText(data, 'location')),
        _Info('Work Type', tlText(data, 'work_type')),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)), onPressed: openNext, child: const Text('Confirm Check-In')),
    ]);
  }
}

class _AttendanceMarked extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback openAttendance;
  const _AttendanceMarked({required this.data, required this.openAttendance});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        CircleAvatar(radius: 42, backgroundColor: c.success, child: const Icon(Icons.check_rounded, color: Colors.white, size: 46)),
        const SizedBox(height: 16),
        Text('Checked In Successfully!', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(tlText(data, 'location'), style: TextStyle(color: c.muted, fontSize: 12)),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)), onPressed: openAttendance, child: const Text('View Attendance')),
    ]);
  }
}

class _Leave extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Leave({required this.data});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'leaves'), icon: Icons.beach_access_rounded, color: c.warning, onTap: (_) {});
  }
}

class _Meetings extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final String email;
  final ValueChanged<Map<String, dynamic>> open;
  final VoidCallback scheduled;
  const _Meetings({required this.data, required this.userId, required this.email, required this.open, required this.scheduled});

  @override
  State<_Meetings> createState() => _MeetingsState();
}

class _MeetingsState extends State<_Meetings> {
  final _title = TextEditingController();
  final _type = TextEditingController();
  final _location = TextEditingController();
  final _duration = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  Map<String, dynamic>? _employee;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    _location.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _schedule() async {
    if (_title.text.trim().isEmpty || _employee == null) return;
    setState(() => _saving = true);
    try {
      await TlService().scheduleMeeting({
        'title': _title.text.trim(),
        'meeting_type': _type.text.trim(),
        'location': _location.text.trim(),
        'description': _description.text.trim(),
        'date_label': '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}',
        'time_label': _time.format(context),
        'duration': _duration.text.trim(),
        'status': 'upcoming',
        'participants': [_employee],
        'agenda': [],
        'created_by': widget.userId.isNotEmpty ? widget.userId : widget.email,
      });
      _title.clear();
      _type.clear();
      _location.clear();
      _duration.clear();
      _description.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting scheduled')));
        widget.scheduled();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final team = tlList(widget.data, 'team');
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      _Calendar(month: tlText(widget.data, 'calendar_month'), day: '${widget.data['calendar_day'] ?? ''}'),
      const SizedBox(height: 12),
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Schedule Meeting', style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(controller: _title, decoration: _fieldDecoration(context, 'Meeting Title')),
        const SizedBox(height: 10),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _employee,
          items: team.map((item) => DropdownMenuItem(value: item, child: Text('${item['title']}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) => setState(() => _employee = value),
          decoration: _fieldDecoration(context, 'Employee'),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded), label: Text('${_date.day}/${_date.month}/${_date.year}'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_rounded), label: Text(_time.format(context)))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _type, decoration: _fieldDecoration(context, 'Meeting Type')),
        const SizedBox(height: 10),
        TextField(controller: _location, decoration: _fieldDecoration(context, 'Location / Link')),
        const SizedBox(height: 10),
        TextField(controller: _duration, decoration: _fieldDecoration(context, 'Duration')),
        const SizedBox(height: 10),
        TextField(controller: _description, maxLines: 3, decoration: _fieldDecoration(context, 'Description')),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
          onPressed: _saving ? null : _schedule,
          child: Text(_saving ? 'Scheduling...' : 'Schedule Meeting'),
        ),
      ])),
      const SizedBox(height: 12),
      ...tlList(widget.data, 'meetings').map((item) => TlListTile(icon: Icons.event_note_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['time']}', color: c.primary, onTap: () => widget.open(item))),
    ]);
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final c = TlPalette.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: c.row,
      labelStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
    );
  }
}

class _Reports extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> open;
  const _Reports({required this.data, required this.open});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'reports'), icon: Icons.assessment_rounded, color: c.primary, onTap: open);
  }
}

class _Approvals extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Approvals({required this.data});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'approvals'), icon: Icons.approval_rounded, color: c.success, onTap: (_) {});
  }
}

class _Notifications extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Notifications({required this.data});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return _ListPage(items: tlList(data, 'notifications'), icon: Icons.notifications_rounded, color: c.danger, onTap: (_) {});
  }
}

class _TaskDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback update;
  const _TaskDetails({required this.item, required this.update});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${item['title'] ?? 'Task Details'}', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _Info('Project', '${item['project'] ?? item['subtitle'] ?? ''}'),
        _Info('Assigned To', '${item['assignee'] ?? ''}'),
        _Info('Priority', '${item['priority'] ?? ''}'),
        _Info('Due Date', '${item['due'] ?? ''}'),
        _Info('Status', '${item['status'] ?? item['trailing'] ?? ''}'),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), onPressed: update, child: const Text('Update Status')),
    ]);
  }
}

class _CreateTask extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback submit;
  const _CreateTask({required this.data, required this.submit});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        _Input(label: 'Task Title'),
        _Input(label: 'Project'),
        _Input(label: 'Assign To'),
        _Input(label: 'Priority'),
        _Input(label: 'Due Date'),
        _Input(label: 'Description', maxLines: 3),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), onPressed: submit, child: const Text('Create Task')),
    ]);
  }
}

class _ProjectDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback openTasks;
  const _ProjectDetails({required this.item, required this.openTasks});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${item['title'] ?? 'Project Details'}', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: (double.tryParse('${item['progress'] ?? 0}') ?? 0) / 100, color: c.primary, backgroundColor: c.border),
        const SizedBox(height: 12),
        _Info('Status', '${item['status'] ?? ''}'),
        _Info('Description', '${item['subtitle'] ?? ''}'),
      ])),
      const SizedBox(height: 16),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white), onPressed: openTasks, child: const Text('View Tasks')),
    ]);
  }
}

class _TeamPerformance extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TeamPerformance({required this.data});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 100, height: 100, child: CircularProgressIndicator(value: tlPercent(data, 'team_progress'), strokeWidth: 9, color: c.success, backgroundColor: c.border)),
          Text('${(tlPercent(data, 'team_progress') * 100).round()}%', style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      ])),
      const SizedBox(height: 12),
      ...tlList(data, 'team').map((item) => TlListTile(icon: Icons.person_rounded, title: '${item['title']}', subtitle: '${item['subtitle']}', trailing: '${item['score'] ?? item['trailing'] ?? ''}', color: c.success)),
    ]);
  }
}

class _GenericDetails extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GenericDetails({required this.item});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${item['title'] ?? 'Details'}', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _Info('Summary', '${item['subtitle'] ?? ''}'),
        _Info('Status', '${item['trailing'] ?? item['status'] ?? ''}'),
        _Info('Time', '${item['time'] ?? ''}'),
      ])),
    ]);
  }
}

class _Profile extends StatelessWidget {
  final String email;
  final String name;
  final File? profileImage;
  final VoidCallback onProfileTap;
  final VoidCallback logout;
  const _Profile({required this.email, required this.name, required this.profileImage, required this.onProfileTap, required this.logout});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 16), children: [
      TlCard(child: Column(children: [
        _ProfileAvatar(image: profileImage, radius: 34, onTap: onProfileTap),
        const SizedBox(height: 10),
        Text(name.trim(), style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(email, style: TextStyle(color: c.muted, fontSize: 11)),
      ])),
      const SizedBox(height: 10),
      TlListTile(icon: Icons.person_outline_rounded, title: 'Personal Information', subtitle: 'Profile and contact details', color: c.primary),
      TlListTile(icon: Icons.lock_outline_rounded, title: 'Change Password', subtitle: 'Security settings', color: c.purple),
      TlListTile(icon: Icons.notifications_none_rounded, title: 'Notification Settings', subtitle: 'Alerts and reminders', color: c.warning),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white), onPressed: logout, child: const Text('Logout')),
    ]);
  }
}

class _ProfileAvatar extends StatelessWidget {
  final File? image;
  final double radius;
  final VoidCallback onTap;

  const _ProfileAvatar({required this.image, required this.radius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
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

class _ListPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final Color color;
  final ValueChanged<Map<String, dynamic>> onTap;

  const _ListPage({required this.items, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: items.map((item) => TlListTile(icon: icon, title: '${item['title'] ?? item['name']}', subtitle: '${item['subtitle'] ?? item['role'] ?? ''}', trailing: '${item['trailing'] ?? item['status'] ?? ''}', color: color, onTap: () => onTap(item))).toList(),
    );
  }
}

class _Calendar extends StatelessWidget {
  final String month;
  final String day;
  const _Calendar({required this.month, required this.day});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    final now = DateTime.now();
    final activeDay = int.tryParse(day);
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final cells = leading + daysInMonth;
    return TlCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.calendar_month_rounded, color: c.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(month.isEmpty ? '${now.month}/${now.year}' : month, style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 12),
      Row(
        children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
            .map((label) => Expanded(child: Center(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)))))
            .toList(),
      ),
      const SizedBox(height: 8),
      GridView.builder(
        itemCount: cells,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemBuilder: (context, index) {
          if (index < leading) return const SizedBox.shrink();
          final date = index - leading + 1;
          final active = date == activeDay;
          return Center(
            child: active
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: c.primary,
                    child: Text('$date', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  )
                : Text('$date', style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w800)),
          );
        },
      ),
    ]));
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _Metric(this.title, this.value, this.color, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: color, size: 22),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(title, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ]));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _Section({required this.title, required this.action, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Row(children: [
      Expanded(child: Text(title, style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900))),
      TextButton(onPressed: onTap, child: Text(action)),
    ]);
  }
}

class _ProgressCard extends StatelessWidget {
  final double value;
  final String label;
  const _ProgressCard({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return TlCard(child: Row(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: value, strokeWidth: 7, color: c.primary, backgroundColor: c.border)),
        Text('${(value * 100).round()}%', style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Text(label, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w900))),
    ]));
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
      Text(value, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w900)),
    ]));
  }
}

class _Input extends StatelessWidget {
  final String label;
  final int maxLines;
  const _Input({required this.label, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: c.row,
          labelStyle: TextStyle(color: c.muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TlPalette c;
  final String title;
  final VoidCallback menu;
  final VoidCallback theme;
  final VoidCallback profile;
  const _TopBar({required this.c, required this.title, required this.menu, required this.theme, required this.profile});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 6), child: Row(children: [
      InkWell(onTap: menu, borderRadius: BorderRadius.circular(8), child: const Padding(padding: EdgeInsets.all(4), child: BitByteLogo(compact: true))),
      const SizedBox(width: 12),
      Expanded(child: Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900))),
      IconButton(onPressed: theme, icon: Icon(c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: c.primary)),
      IconButton(onPressed: profile, icon: Icon(Icons.account_circle_outlined, color: c.text)),
    ]));
  }
}

class _Drawer extends StatelessWidget {
  final String email;
  final String name;
  final ValueChanged<int> select;
  final VoidCallback logout;
  const _Drawer({required this.email, required this.name, required this.select, required this.logout});
  @override
  Widget build(BuildContext context) {
    final c = TlPalette.of(context);
    return Drawer(backgroundColor: c.surface, child: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(18), child: Row(children: [
        const BitByteLogo(compact: true),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.trim().isEmpty ? 'Team Lead' : name, style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900)),
          Text(email, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11)),
        ])),
      ])),
      Divider(color: c.border),
      Expanded(child: ListView(children: List.generate(14, (index) => ListTile(leading: Icon(_icons[index], color: c.primary, size: 19), title: Text(_titles[index], style: TextStyle(color: c.text, fontWeight: FontWeight.w700)), onTap: () => select(index))))),
      Divider(color: c.border),
      ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)), onTap: logout),
    ])));
  }
}

class _BottomNav extends StatelessWidget {
  final TlPalette c;
  final int index;
  final ValueChanged<int> select;
  const _BottomNav({required this.c, required this.index, required this.select});
  @override
  Widget build(BuildContext context) {
    const items = [0, 1, 2, 3, 13];
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 8),
      child: Row(children: items.map((itemIndex) {
        final selected = index == itemIndex;
        return Expanded(child: InkWell(onTap: () => select(itemIndex), borderRadius: BorderRadius.circular(8), child: SizedBox(height: 48, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[itemIndex], color: selected ? c.primary : c.muted, size: 18),
          const SizedBox(height: 3),
          FittedBox(child: Text(_titles[itemIndex], style: TextStyle(color: selected ? c.primary : c.muted, fontSize: 10, fontWeight: FontWeight.w800))),
        ]))));
      }).toList()),
    );
  }
}

const _titles = [
  'Dashboard',
  'Team',
  'Tasks',
  'Projects',
  'Attendance',
  'Selfie Attendance',
  'Geo Location',
  'Confirm Attendance',
  'Attendance Marked',
  'Leave',
  'Meetings',
  'Reports',
  'Approvals',
  'Notifications',
  'Task Details',
  'Create Task',
  'Project Details',
  'Team Performance',
  'Details',
  'Profile',
];

const _icons = [
  Icons.dashboard_rounded,
  Icons.groups_rounded,
  Icons.task_alt_rounded,
  Icons.work_rounded,
  Icons.calendar_month_rounded,
  Icons.camera_alt_rounded,
  Icons.location_on_rounded,
  Icons.fact_check_rounded,
  Icons.check_circle_rounded,
  Icons.beach_access_rounded,
  Icons.event_rounded,
  Icons.assessment_rounded,
  Icons.approval_rounded,
  Icons.notifications_rounded,
  Icons.info_rounded,
  Icons.add_task_rounded,
  Icons.work_history_rounded,
  Icons.insights_rounded,
  Icons.description_rounded,
  Icons.account_circle_rounded,
];
