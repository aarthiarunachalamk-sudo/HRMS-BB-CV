import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/login_screen.dart';

import 'admin_palette.dart';
import 'admin_success_screen.dart';
import 'admin_widgets.dart';

class AdminTasksScreen extends StatelessWidget {
  const AdminTasksScreen({super.key});

  static const _tasks = [
    ['UI Design Review', 'Priya Sharma', 'High', '75%'],
    ['Attendance Module', 'Michael Brown', 'Medium', '40%'],
    ['Bug Fixing', 'John Smith', 'Low', '30%'],
    ['API Integration', 'Sarah Johnson', 'High', '60%'],
  ];

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
      child: adminPageList([
        _Segment(['All', 'In Progress', 'Completed'], 0, c),
        ..._tasks.map(
          (task) => AdminCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminTaskDetailsScreen(
                  title: task[0],
                  assignee: task[1],
                  priority: task[2],
                  progress: task[3],
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      adminTitle(task[0], 14, c),
                      const SizedBox(height: 4),
                      adminMuted(task[1], 11, c),
                      const SizedBox(height: 5),
                      AdminBadge(task[2], color: _priorityColor(task[2], c)),
                    ],
                  ),
                ),
                _RingLabel(task[3], c.primary),
              ],
            ),
          ),
        ),
      ]),
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
  String _assignee = 'John Smith';
  String _priority = 'High';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
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
          value: _assignee,
          items: const [
            'John Smith',
            'Priya Sharma',
            'Michael Brown',
            'Sarah Johnson',
          ],
          icon: Icons.person_outline_rounded,
          c: c,
          onChanged: (v) => setState(() => _assignee = v),
        ),
        _DropdownBlock(
          label: 'Priority',
          value: _priority,
          items: const ['High', 'Medium', 'Low'],
          icon: Icons.flag_outlined,
          c: c,
          onChanged: (v) => setState(() => _priority = v),
        ),
        _DateCard('Due Date', 'Select due date', c),
        AdminPrimaryButton(
          label: 'Assign Task',
          icon: Icons.send_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminSuccessScreen(
                message: 'Task Assigned\nSuccessfully!',
                subMessage: 'Employee has been notified.',
                actionLabel: 'View Tasks',
                onAction: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class AdminTaskDetailsScreen extends StatelessWidget {
  final String title;
  final String assignee;
  final String priority;
  final String progress;

  const AdminTaskDetailsScreen({
    super.key,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.progress,
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
              const AdminInfoRow('Due Date', '24 Jun 2026'),
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
              adminMuted(
                'Review the new UI design for the HRMS application and share feedback.',
                12,
                c,
              ),
            ],
          ),
        ),
        AdminListTile(
          icon: Icons.attach_file_rounded,
          titleText: 'Attachments',
          subtitle: '2 files',
          color: c.primary,
        ),
        AdminListTile(
          icon: Icons.comment_rounded,
          titleText: 'Comments',
          subtitle: '3 comments',
          color: c.orange,
        ),
      ]),
    );
  }
}

class AdminAssetsScreen extends StatelessWidget {
  const AdminAssetsScreen({super.key});

  static const _assets = [
    ['MacBook Pro', 'Laptop - IT-001', 'Assigned'],
    ['iPhone 15', 'Mobile - MOB-001', 'Assigned'],
    ['Dell Monitor', 'Monitor - MON-001', 'Available'],
    ['HP Printer', 'Printer - PRN-001', 'Available'],
  ];

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
      child: adminPageList([
        Row(
          children: [
            Expanded(child: _CountCard('Total Assets', '245', c.primary, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Assigned', '187', c.green, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Available', '58', c.orange, c)),
          ],
        ),
        const AdminSearchBox(hint: 'Search assets...'),
        ..._assets.map(
          (asset) => AdminListTile(
            icon: Icons.devices_rounded,
            titleText: asset[0],
            subtitle: asset[1],
            color: asset[2] == 'Assigned' ? c.green : c.orange,
            trailing: AdminBadge(
              asset[2],
              color: asset[2] == 'Assigned' ? c.green : c.orange,
            ),
          ),
        ),
      ]),
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
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    final reports = [
      [
        Icons.event_available_rounded,
        'Attendance Report',
        'View attendance analytics',
        c.green,
      ],
      [Icons.beach_access_rounded, 'Leave Report', 'View leave summary', c.red],
      [
        Icons.people_rounded,
        'Employee Report',
        'View employee details',
        c.primary,
      ],
      [Icons.task_alt_rounded, 'Task Report', 'View task progress', c.orange],
      [Icons.devices_rounded, 'Asset Report', 'View asset summary', c.green],
    ];
    return AdminShell(
      title: 'Reports',
      child: adminPageList([
        ...reports.map(
          (item) => AdminListTile(
            icon: item[0] as IconData,
            titleText: item[1] as String,
            subtitle: item[2] as String,
            color: item[3] as Color,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AdminReportDetailsScreen(title: item[1] as String),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class AdminReportDetailsScreen extends StatelessWidget {
  final String title;
  const AdminReportDetailsScreen({super.key, this.title = 'Attendance Report'});

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
            Expanded(child: _CountCard('Total Employees', '120', c.primary, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Present', '96', c.green, c)),
            const SizedBox(width: 10),
            Expanded(child: _CountCard('Late', '18', c.red, c)),
          ],
        ),
        AdminChartCard(
          title: 'Attendance Trend',
          subtitle: 'This week',
          trend: '+4%',
          bars: const [40, 62, 50, 74, 66, 70, 75],
          color: c.primary,
        ),
        AdminPrimaryButton(
          label: 'Export PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () {},
        ),
      ]),
    );
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Notifications',
      child: adminPageList([
        AdminListTile(
          icon: Icons.beach_access_rounded,
          titleText: 'Leave Request',
          subtitle: 'Priya Sharma applied for leave - 2 min ago',
          color: c.red,
        ),
        AdminListTile(
          icon: Icons.event_rounded,
          titleText: 'Meeting Reminder',
          subtitle: 'Monthly review meeting at 10:00 AM',
          color: c.primary,
        ),
        AdminListTile(
          icon: Icons.warning_amber_rounded,
          titleText: 'Attendance Alert',
          subtitle: '3 employees were late today',
          color: c.orange,
        ),
        AdminListTile(
          icon: Icons.task_alt_rounded,
          titleText: 'Task Update',
          subtitle: 'UI design review task updated',
          color: c.purple,
        ),
        AdminListTile(
          icon: Icons.system_update_alt_rounded,
          titleText: 'System Update',
          subtitle: 'HRMS update completed',
          color: c.green,
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Mark all as read',
            style: TextStyle(color: c.primary, fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

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
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
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
            MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
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
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Profile',
      child: adminPageList([
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
              adminTitle('Admin User', 18, c),
              adminMuted('admin@company.com', 12, c),
            ],
          ),
        ),
        AdminCard(
          child: Column(
            children: [
              const AdminInfoRow('Mobile', '+91 98XXXXXXX0'),
              Divider(color: c.border),
              const AdminInfoRow('Department', 'Administration'),
              Divider(color: c.border),
              const AdminInfoRow('Role', 'Super Admin'),
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
          subtitle: 'View recent activity',
          color: c.orange,
        ),
      ]),
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

  const _Segment(this.labels, this.selected, this.c);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selected;
          return Expanded(
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

  const _DateCard(this.label, this.value, this.c);

  @override
  Widget build(BuildContext context) {
    return AdminCard(
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
