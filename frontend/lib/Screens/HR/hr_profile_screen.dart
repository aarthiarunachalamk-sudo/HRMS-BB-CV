import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrProfileScreen extends StatelessWidget {
  final String userId;
  final String email;
  final String name;
  final VoidCallback onLogout;

  const HrProfileScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        HrCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: c.primary.withAlpha(30),
                child: Icon(Icons.person_rounded, color: c.primary, size: 34),
              ),
              const SizedBox(height: 10),
              Text(
                name.trim().isEmpty ? 'HR Manager' : name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: c.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HrListTile(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          subtitle: 'Profile and contact details',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _HrPersonalInformationScreen(userId: userId)),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Security settings',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(employeeId: userId, otc: ''),
            ),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notification Settings',
          subtitle: 'Alerts and reminders',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _HrNotificationSettingsScreen(userId: userId)),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'End current session',
          color: c.danger,
          onTap: onLogout,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: onLogout,
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _HrPersonalInformationScreen extends StatefulWidget {
  final String userId;
  const _HrPersonalInformationScreen({required this.userId});

  @override
  State<_HrPersonalInformationScreen> createState() => _HrPersonalInformationScreenState();
}

class _HrPersonalInformationScreenState extends State<_HrPersonalInformationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = HrService().fetchUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Personal Information')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final raw = snapshot.data!['profile'];
          final profile = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          return ListView(
            padding: AppLayout.pagePadding,
            children: [
              for (final entry in <String, dynamic>{
                'Employee ID': profile['user_id'],
                'Name': '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
                'Email': profile['email'],
                'Phone': '${profile['country_code'] ?? ''} ${profile['phone'] ?? ''}'.trim(),
                'Role': profile['role'],
                'Designation': profile['designation'],
                'Department': profile['department'],
                'Address': [profile['door_no'], profile['street'], profile['city'], profile['state'], profile['pincode']]
                    .map((value) => '${value ?? ''}'.trim())
                    .where((value) => value.isNotEmpty)
                    .join(', '),
              }.entries)
                HrCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key, style: TextStyle(color: c.muted, fontSize: 12)),
                    subtitle: Text('${entry.value}'.trim().isEmpty ? '-' : '${entry.value}', style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HrNotificationSettingsScreen extends StatefulWidget {
  final String userId;
  const _HrNotificationSettingsScreen({required this.userId});

  @override
  State<_HrNotificationSettingsScreen> createState() => _HrNotificationSettingsScreenState();
}

class _HrNotificationSettingsScreenState extends State<_HrNotificationSettingsScreen> {
  final Map<String, bool> _values = {'push': true, 'leave': true, 'attendance': true, 'meetings': true};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await HrService().fetchUserProfile(widget.userId);
      final profile = response['profile'];
      final preferences = profile is Map ? profile['notification_preferences'] : null;
      if (preferences is Map) {
        for (final key in _values.keys) _values[key] = preferences[key] != false;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(String key, bool value) async {
    final previous = _values[key]!;
    setState(() => _values[key] = value);
    try {
      await HrService().updateUserProfile(widget.userId, {'notification_preferences': _values});
    } catch (_) {
      if (mounted) setState(() => _values[key] = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    const labels = {'push': 'Push Notifications', 'leave': 'Leave Updates', 'attendance': 'Attendance Alerts', 'meetings': 'Meeting Reminders'};
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Notification Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppLayout.pagePadding,
              children: labels.entries.map((entry) => HrCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                  value: _values[entry.key]!,
                  onChanged: (value) => _change(entry.key, value),
                ),
              )).toList(),
            ),
    );
  }
}
