import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrProfileScreen extends StatefulWidget {
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
  State<HrProfileScreen> createState() => _HrProfileScreenState();
}

class _HrProfileScreenState extends State<HrProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = HrService().fetchUserProfile(widget.userId);
  }

  Widget _profileAvatar(HrPalette colors) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final rawProfile = snapshot.data?['profile'];
        final profile = rawProfile is Map
            ? Map<String, dynamic>.from(rawProfile)
            : <String, dynamic>{};
        final photoUrl = '${profile['profile_photo_url'] ?? ''}'.trim();

        return CircleAvatar(
          radius: 34,
          backgroundColor: colors.primary.withAlpha(30),
          foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
          onForegroundImageError: photoUrl.isEmpty ? null : (_, __) {},
          child: Icon(
            Icons.person_rounded,
            color: colors.primary,
            size: 34,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        HrCard(
          child: Column(
            children: [
              _profileAvatar(c),
              const SizedBox(height: 10),
              Text(
                widget.name.trim().isEmpty ? 'HR Manager' : widget.name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.email,
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
            MaterialPageRoute(builder: (_) => _HrPersonalInformationScreen(userId: widget.userId)),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Security settings',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(employeeId: widget.userId, otc: ''),
            ),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notification Settings',
          subtitle: 'Alerts and reminders',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _HrNotificationSettingsScreen(userId: widget.userId)),
          ),
        ),
        const SizedBox(height: 10),
        HrListTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'End current session',
          color: c.danger,
          onTap: widget.onLogout,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: widget.onLogout,
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
          final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
          final photoUrl = '${profile['profile_photo_url'] ?? ''}'.trim();
          final address = [
            profile['door_no'],
            profile['street'],
            profile['city'],
            profile['state'],
            profile['pincode'],
          ].map((value) => '${value ?? ''}'.trim()).where((value) => value.isNotEmpty).join(', ');

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                HrCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: c.primary.withAlpha(28),
                        foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                        onForegroundImageError: photoUrl.isEmpty ? null : (_, __) {},
                        child: Icon(Icons.person_rounded, color: c.primary, size: 34),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'HR Manager' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _displayValue(profile['designation']),
                              style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: c.primary.withAlpha(24),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _displayValue(profile['user_id']),
                                style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Contact information',
                  children: [
                    _ProfileInfoRow(icon: Icons.email_outlined, label: 'Email', value: profile['email']),
                    _ProfileInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: '${profile['country_code'] ?? ''} ${profile['phone'] ?? ''}'.trim(),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Employment information',
                  children: [
                    _ProfileInfoRow(icon: Icons.badge_outlined, label: 'Role', value: profile['role']),
                    _ProfileInfoRow(icon: Icons.work_outline_rounded, label: 'Designation', value: profile['designation']),
                    _ProfileInfoRow(
                      icon: Icons.account_tree_outlined,
                      label: 'Department',
                      value: profile['department'],
                      formatValue: true,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Address',
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Residential address',
                      value: address,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _displayValue(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty) return 'Not provided';
    if (RegExp(r'\d').hasMatch(text)) return text;
    if (!text.contains('_') && text.length <= 3) return text.toUpperCase();
    return text
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8),
          ),
        ),
        HrCard(padding: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool showDivider;
  final bool formatValue;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.formatValue = false,
  });

  String get displayValue {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty) return 'Not provided';
    if (!formatValue) return text;
    return text
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(displayValue, style: TextStyle(color: c.text, fontSize: 13, height: 1.35, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, indent: 64, color: c.border),
      ],
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
