import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';

import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_success_screen.dart';
import 'admin_widgets.dart';

class AdminTasksScreen extends StatefulWidget {
  final String userId;
  const AdminTasksScreen({super.key, required this.userId});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  late Future<Map<String, dynamic>> _future;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _future = AdminService().fetchTasks(widget.userId);
  }

  Future<void> _refresh() async {
    final future = AdminService().fetchTasks(widget.userId);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Tasks',
      trailing: IconButton(
        icon: Icon(Icons.add_circle_rounded, color: c.primary),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminCreateTaskScreen()),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final tasks = _mapList(snapshot.data?['tasks']);
          final filtered = tasks.where((task) {
            final status = _text(task['status']).toLowerCase();
            if (_selectedFilter == 1) return status == 'in_progress';
            if (_selectedFilter == 2) return status == 'completed';
            return true;
          }).toList();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?['success'] != true) {
            return _AdminTaskMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load tasks',
              message: _text(
                snapshot.data?['message'],
                'Check your connection and try again.',
              ),
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: adminPageList([
              _Segment(
                const ['All', 'In Progress', 'Completed'],
                _selectedFilter,
                c,
                onSelected: (index) => setState(() => _selectedFilter = index),
              ),
              if (filtered.isEmpty)
                _AdminTaskMessage(
                  icon: tasks.isEmpty
                      ? Icons.task_alt_rounded
                      : Icons.filter_alt_off_rounded,
                  title: tasks.isEmpty
                      ? 'No tasks assigned yet'
                      : 'No matching tasks',
                  message: tasks.isEmpty
                      ? 'Tap the + button to create and assign the first task.'
                      : 'Choose another status to view available tasks.',
                ),
              ...filtered.map((task) {
                final title = _text(task['title'], 'Task');
                final assignee = _text(task['assignee'], 'Unassigned');
                final priority = _text(task['priority'], 'Medium');
                final progress = _taskProgress(task['status']);
                return AdminCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminTaskDetailsScreen(
                        title: title,
                        assignee: assignee,
                        priority: priority,
                        progress: progress,
                        dueDate: _text(task['due_date'], 'N/A'),
                        description: _text(
                          task['description'],
                          'No description',
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            adminTitle(title, 14, c),
                            const SizedBox(height: 4),
                            adminMuted(assignee, 11, c),
                            const SizedBox(height: 5),
                            AdminBadge(
                              priority,
                              color: _priorityColor(priority, c),
                            ),
                          ],
                        ),
                      ),
                      _RingLabel(progress, c.primary),
                    ],
                  ),
                );
              }),
            ]),
          );
        },
      ),
    );
  }
}

class _AdminTaskMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _AdminTaskMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: c.primary, size: 38),
            const SizedBox(height: 10),
            adminTitle(title, 14, c),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminCreateTaskScreen extends StatefulWidget {
  const AdminCreateTaskScreen({super.key});

  @override
  State<AdminCreateTaskScreen> createState() => _AdminCreateTaskScreenState();
}

class _AdminCreateTaskScreenState extends State<AdminCreateTaskScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _assignee = '';
  String _assigneeId = '';
  String _assigneeEmail = '';
  String _priority = 'High';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService().fetchEmployees(''),
      builder: (context, snapshot) {
        final employees = _mapList(snapshot.data?['employees']);
        final employeeByLabel = <String, Map<String, dynamic>>{
          for (final employee in employees)
            if (_text(employee['name']).isNotEmpty)
              '${_text(employee['name'])} (${_text(employee['employee_id'], _text(employee['user_id']))})':
                  employee,
        };
        final assignees = employeeByLabel.isEmpty
            ? ['Unassigned']
            : employeeByLabel.keys.toList();
        final selectedAssignee = assignees.contains(_assignee)
            ? _assignee
            : assignees.first;
        if (_assignee != selectedAssignee) {
          _assignee = selectedAssignee;
          final employee = employeeByLabel[selectedAssignee];
          _assigneeId = _text(
            employee?['employee_id'],
            _text(employee?['user_id']),
          );
          _assigneeEmail = _text(
            employee?['email'],
            _text(employee?['employee_email']),
          );
        }
        return AdminShell(
          title: 'Create Task',
          child: adminPageList([
            _TextFieldBlock('Task Title', _title, Icons.task_alt_rounded, c),
            _TextFieldBlock(
              'Description',
              _description,
              Icons.notes_rounded,
              c,
              maxLines: 3,
            ),
            _DropdownBlock(
              label: 'Assign To',
              value: selectedAssignee,
              items: assignees,
              icon: Icons.person_outline_rounded,
              c: c,
              onChanged: (v) {
                final employee = employeeByLabel[v];
                setState(() {
                  _assignee = v;
                  _assigneeId = _text(
                    employee?['employee_id'],
                    _text(employee?['user_id']),
                  );
                  _assigneeEmail = _text(
                    employee?['email'],
                    _text(employee?['employee_email']),
                  );
                });
              },
            ),
            _DropdownBlock(
              label: 'Priority',
              value: _priority,
              items: const ['High', 'Medium', 'Low'],
              icon: Icons.flag_outlined,
              c: c,
              onChanged: (v) => setState(() => _priority = v),
            ),
            _DateCard(
              'Due Date',
              _dueDate == null
                  ? 'Select due date'
                  : _dueDate!.toIso8601String().split('T').first,
              c,
              onTap: _selectDueDate,
            ),
            AdminPrimaryButton(
              label: _saving ? 'Assigning...' : 'Assign Task',
              icon: Icons.send_rounded,
              onTap: _assignTask,
            ),
          ]),
        );
      },
    );
  }

  Future<void> _assignTask() async {
    if (_saving) return;
    setState(() => _saving = true);
    final response = await AdminService().createTask({
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'assignee_name': _assignee.replaceFirst(RegExp(r'\s*\([^)]*\)$'), ''),
      'assignee_id': _assigneeId,
      'assignee_email': _assigneeEmail,
      'priority': _priority,
      'due_date': _dueDate?.toIso8601String().split('T').first ?? '',
      'created_by': 'admin',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${response['message'] ?? 'Task creation failed.'}'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSuccessScreen(
          message: 'Task Assigned\nSuccessfully!',
          subMessage: 'Employee has been notified.',
          actionLabel: 'View Tasks',
          onAction: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final today = DateTime.now();
    final selected = await showSeparatedDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }
}

class AdminTaskDetailsScreen extends StatelessWidget {
  final String title;
  final String assignee;
  final String priority;
  final String progress;
  final String dueDate;
  final String description;

  const AdminTaskDetailsScreen({
    super.key,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.progress,
    this.dueDate = 'N/A',
    this.description = 'No description',
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final parsedProgress = int.tryParse(progress.replaceAll('%', '')) ?? 0;
    return AdminShell(
      title: 'Task Details',
      child: adminPageList([
        AdminCard(
          child: Column(
            children: [
              AdminInfoRow('Task', title),
              Divider(color: c.border),
              AdminInfoRow('Assigned To', assignee),
              Divider(color: c.border),
              AdminInfoRow(
                'Priority',
                priority,
                valueColor: _priorityColor(priority, c),
              ),
              Divider(color: c.border),
              AdminInfoRow('Due Date', dueDate),
              Divider(color: c.border),
              AdminInfoRow('Progress', progress),
            ],
          ),
        ),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              adminTitle('Progress', 14, c),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: parsedProgress / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
                color: c.primary,
                backgroundColor: c.border,
              ),
              const SizedBox(height: 14),
              adminMuted(description, 12, c),
            ],
          ),
        ),
      ]),
    );
  }
}

class AdminAssetsScreen extends StatelessWidget {
  final String userId;
  const AdminAssetsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Assets',
      trailing: IconButton(
        icon: Icon(Icons.add_circle_rounded, color: c.primary),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminAssignAssetScreen()),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchAssets(userId),
        builder: (context, snapshot) {
          final assets = _mapList(snapshot.data?['assets']);
          final assigned = assets
              .where((a) => _text(a['status']).toLowerCase() == 'assigned')
              .length;
          final available = assets.length - assigned;
          return adminPageList([
            Row(
              children: [
                Expanded(
                  child: _CountCard(
                    'Total Assets',
                    '${assets.length}',
                    c.primary,
                    c,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountCard('Assigned', '$assigned', c.green, c),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountCard('Available', '$available', c.orange, c),
                ),
              ],
            ),
            const AdminSearchBox(hint: 'Search assets...'),
            if (assets.isEmpty)
              AdminCard(
                child: Center(child: adminMuted('No assets found', 12, c)),
              ),
            ...assets.map((asset) {
              final status = _text(asset['status'], 'Available');
              return AdminListTile(
                icon: Icons.devices_rounded,
                titleText: _text(asset['name'], 'Asset'),
                subtitle: _text(asset['code'], _text(asset['type'])),
                color: status == 'Assigned' ? c.green : c.orange,
                trailing: AdminBadge(
                  status,
                  color: status == 'Assigned' ? c.green : c.orange,
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

class AdminAssignAssetScreen extends StatefulWidget {
  const AdminAssignAssetScreen({super.key});

  @override
  State<AdminAssignAssetScreen> createState() => _AdminAssignAssetScreenState();
}

class _AdminAssignAssetScreenState extends State<AdminAssignAssetScreen> {
  String _asset = 'MacBook Pro';
  String _employee = 'John Smith';
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Assign Asset',
      child: adminPageList([
        _DropdownBlock(
          label: 'Asset Name',
          value: _asset,
          items: const [
            'MacBook Pro',
            'iPhone 15',
            'Dell Monitor',
            'HP Printer',
          ],
          icon: Icons.devices_rounded,
          c: c,
          onChanged: (v) => setState(() => _asset = v),
        ),
        _DropdownBlock(
          label: 'Assign To',
          value: _employee,
          items: const ['John Smith', 'Priya Sharma', 'Michael Brown'],
          icon: Icons.person_outline_rounded,
          c: c,
          onChanged: (v) => setState(() => _employee = v),
        ),
        _DateCard('Assign Date', '24 Jun 2026', c),
        _TextFieldBlock('Notes', _notes, Icons.notes_rounded, c, maxLines: 3),
        AdminPrimaryButton(
          label: 'Assign Asset',
          icon: Icons.inventory_2_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  final String userId;
  const AdminReportsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Reports',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchReports(userId),
        builder: (context, snapshot) {
          final reports = _mapList(snapshot.data?['reports']);
          return adminPageList([
            if (reports.isEmpty)
              AdminCard(
                child: Center(child: adminMuted('No reports found', 12, c)),
              ),
            ...reports.map(
              (item) => AdminListTile(
                icon: _reportIcon(_text(item['title'])),
                titleText: _text(item['title'], 'Report'),
                subtitle: _text(item['subtitle'], 'Backend report'),
                color: c.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminReportDetailsScreen(
                      title: _text(item['title'], 'Report'),
                      value: _text(item['value'], '0'),
                      subtitle: _text(item['subtitle']),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class AdminReportDetailsScreen extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  const AdminReportDetailsScreen({
    super.key,
    this.title = 'Attendance Report',
    this.value = '0',
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: title,
      child: adminPageList([
        _DateCard('Date Range', '01 Jun 2026 - 24 Jun 2026', c),
        _DropdownBlock(
          label: 'Department',
          value: 'All Departments',
          items: const ['All Departments', 'HR', 'Finance', 'IT', 'Marketing'],
          icon: Icons.apartment_rounded,
          c: c,
          onChanged: (_) {},
        ),
        Row(
          children: [
            Expanded(child: _CountCard(title, value, c.primary, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Source', 'Backend', c.green, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Status', 'Live', c.red, c)),
          ],
        ),
        AdminCard(
          child: adminMuted(
            subtitle.isEmpty
                ? 'This report is loaded from the backend.'
                : subtitle,
            12,
            c,
          ),
        ),
        AdminPrimaryButton(
          label: 'Export PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance PDF export is not connected yet.'),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  final String userId;
  const AdminNotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Notifications',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchNotifications(userId),
        builder: (context, snapshot) {
          final notifications = _mapList(snapshot.data?['notifications']);
          return adminPageList([
            if (notifications.isEmpty)
              AdminCard(
                child: Center(
                  child: adminMuted('No notifications found', 12, c),
                ),
              ),
            ...notifications.map(
              (item) => AdminListTile(
                icon: _notificationIcon(_text(item['module'])),
                titleText: _text(item['title'], 'Notification'),
                subtitle: _text(item['subtitle'], _text(item['message'])),
                color: _notificationColor(_text(item['type']), c),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications refreshed from backend.'),
                  ),
                );
              },
              child: Text(
                'Refresh',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w800),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  final String userId;
  const AdminSettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Settings',
      child: adminPageList([
        AdminListTile(
          icon: Icons.person_rounded,
          titleText: 'Profile Settings',
          subtitle: 'Manage your profile',
          color: c.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminProfileScreen(userId: userId),
            ),
          ),
        ),
        AdminListTile(
          icon: Icons.security_rounded,
          titleText: 'Security Settings',
          subtitle: 'Password and security',
          color: c.purple,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminChangePasswordScreen(),
            ),
          ),
        ),
        AdminListTile(
          icon: Icons.notifications_rounded,
          titleText: 'Notifications',
          subtitle: 'Manage notifications',
          color: c.orange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminNotificationsScreen(userId: userId),
            ),
          ),
        ),
        AdminListTile(
          icon: Icons.dark_mode_rounded,
          titleText: 'Theme',
          subtitle: c.isDark ? 'Dark Mode' : 'Light Mode',
          color: c.primary,
          onTap: AdminPalette.toggleTheme,
        ),
        AdminListTile(
          icon: Icons.language_rounded,
          titleText: 'Language',
          subtitle: 'English',
          color: c.green,
        ),
        AdminListTile(
          icon: Icons.help_outline_rounded,
          titleText: 'Help & Support',
          subtitle: 'Get help and support',
          color: c.gold,
        ),
        AdminListTile(
          icon: Icons.info_outline_rounded,
          titleText: 'About App',
          subtitle: 'Version 1.0.0',
          color: c.muted,
        ),
        AdminListTile(
          icon: Icons.logout_rounded,
          titleText: 'Logout',
          subtitle: 'Sign out from admin',
          color: c.red,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminLogoutConfirmScreen()),
          ),
        ),
      ]),
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  final String userId;
  const AdminProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Profile',
      child: FutureBuilder<Map<String, dynamic>>(
        future: AdminService().fetchProfile(userId),
        builder: (context, snapshot) {
          final profile = _map(snapshot.data?['profile']);
          final name = _text(profile['name'], 'Admin');
          return adminPageList([
            AdminCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: c.primary.withOpacity(0.14),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: c.primary,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  adminTitle(name, 18, c),
                  adminMuted(_text(profile['email'], '-'), 12, c),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                children: [
                  AdminInfoRow('Mobile', _text(profile['phone'], 'N/A')),
                  Divider(color: c.border),
                  AdminInfoRow(
                    'Department',
                    _text(profile['department'], 'N/A'),
                  ),
                  Divider(color: c.border),
                  AdminInfoRow('Role', _text(profile['role'], 'Admin')),
                  Divider(color: c.border),
                  AdminInfoRow('Status', _text(profile['status'], 'Active')),
                ],
              ),
            ),
            AdminListTile(
              icon: Icons.lock_reset_rounded,
              titleText: 'Change Password',
              subtitle: 'Update login password',
              color: c.purple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminChangePasswordScreen(),
                ),
              ),
            ),
            AdminListTile(
              icon: Icons.history_rounded,
              titleText: 'Activity Log',
              subtitle: 'Shown through backend notifications',
              color: c.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminNotificationsScreen(userId: userId),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class AdminChangePasswordScreen extends StatelessWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    return AdminShell(
      title: 'Change Password',
      child: adminPageList([
        _TextFieldBlock(
          'Current Password',
          current,
          Icons.lock_outline_rounded,
          c,
          obscure: true,
        ),
        _TextFieldBlock(
          'New Password',
          next,
          Icons.lock_reset_rounded,
          c,
          obscure: true,
        ),
        _TextFieldBlock(
          'Confirm Password',
          confirm,
          Icons.verified_user_outlined,
          c,
          obscure: true,
        ),
        AdminPrimaryButton(
          label: 'Update Password',
          icon: Icons.save_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}

class AdminLogoutConfirmScreen extends StatelessWidget {
  const AdminLogoutConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Logout Confirmation',
      child: adminPageList([
        AdminCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: c.primary.withOpacity(0.12),
                child: Icon(Icons.logout_rounded, color: c.primary, size: 38),
              ),
              const SizedBox(height: 18),
              adminTitle('Are you sure you want to logout?', 17, c),
              const SizedBox(height: 8),
              adminMuted('You will be redirected to the login screen.', 12, c),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: c.red),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final AdminPalette c;
  final ValueChanged<int>? onSelected;

  const _Segment(this.labels, this.selected, this.c, {this.onSelected});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selected;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onSelected == null ? null : () => onSelected!(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RingLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _RingLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AdminPalette c;

  const _CountCard(this.label, this.value, this.color, this.c);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminMuted(label, 10, c),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final AdminPalette c;
  final int maxLines;
  final bool obscure;

  const _TextFieldBlock(
    this.label,
    this.controller,
    this.icon,
    this.c, {
    this.maxLines = 1,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminMuted(label, 12, c),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: obscure ? 1 : maxLines,
            obscureText: obscure,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: c.muted, size: 20),
              filled: true,
              fillColor: c.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownBlock extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final AdminPalette c;
  final ValueChanged<String> onChanged;

  const _DropdownBlock({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.c,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminMuted(label, 12, c),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: c.muted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: AppDropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      dropdownColor: c.surface,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                      items: items
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (item) {
                        if (item != null) onChanged(item);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final AdminPalette c;
  final VoidCallback? onTap;

  const _DateCard(this.label, this.value, this.c, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: c.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                adminMuted(label, 11, c),
                const SizedBox(height: 3),
                adminTitle(value, 13, c),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ],
      ),
    );
  }
}

Color _priorityColor(String priority, AdminPalette c) {
  switch (priority) {
    case 'High':
      return c.red;
    case 'Medium':
      return c.orange;
    default:
      return c.green;
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];

String _text(dynamic value, [String fallback = '']) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}

String _taskProgress(dynamic status) {
  switch (_text(status).toLowerCase()) {
    case 'completed':
      return '100%';
    case 'in_progress':
    case 'in progress':
      return '50%';
    default:
      return '0%';
  }
}

IconData _reportIcon(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('attendance')) return Icons.event_available_rounded;
  if (lower.contains('leave')) return Icons.beach_access_rounded;
  if (lower.contains('employee')) return Icons.people_rounded;
  if (lower.contains('task')) return Icons.task_alt_rounded;
  if (lower.contains('asset')) return Icons.devices_rounded;
  return Icons.insert_chart_outlined_rounded;
}

IconData _notificationIcon(String module) {
  switch (module.toLowerCase()) {
    case 'leave':
      return Icons.beach_access_rounded;
    case 'attendance':
      return Icons.calendar_month_rounded;
    case 'task':
      return Icons.task_alt_rounded;
    case 'meeting':
      return Icons.event_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _notificationColor(String type, AdminPalette c) {
  switch (type.toLowerCase()) {
    case 'success':
      return c.green;
    case 'warning':
      return c.orange;
    case 'error':
      return c.red;
    default:
      return c.primary;
  }
}
