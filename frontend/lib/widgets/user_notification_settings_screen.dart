import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';
import 'package:http/http.dart' as http;

class UserPersonalInformationScreen extends StatelessWidget {
  final String userId;

  const UserPersonalInformationScreen({super.key, required this.userId});

  Future<Map<String, dynamic>> _load() async {
    final response = await http
        .get(ApiConfig.uri('/profile/?user_id=$userId'))
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map) {
      throw Exception('Unable to load profile');
    }
    final raw = data['profile'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ProfileMessage(
              message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
              icon: Icons.cloud_off_rounded,
            );
          }
          final profile = snapshot.data ?? const <String, dynamic>{};
          final address =
              [
                    profile['door_no'],
                    profile['street'],
                    profile['city'],
                    profile['state'],
                    profile['pincode'],
                  ]
                  .map((value) => '${value ?? ''}'.trim())
                  .where((value) => value.isNotEmpty)
                  .join(', ');
          final firstName = '${profile['first_name'] ?? ''}'.trim();
          final lastName = '${profile['last_name'] ?? ''}'.trim();
          final fullName = '${profile['name'] ?? '$firstName $lastName'}'
              .trim();
          final name = fullName.isEmpty ? 'Employee' : fullName;
          final employeeId = _firstValue(profile, const [
            'user_id',
            'employee_id',
            'id',
          ]);
          final designation = _firstValue(profile, const [
            'designation',
            'designation_label',
            'role_label',
            'role',
          ]);
          final photoUrl = _firstValue(profile, const [
            'profile_photo_url',
            'photo_url',
            'doc_passport_photo',
          ]);
          final employment = <String, dynamic>{
            'Employee ID': employeeId,
            'Email': profile['email'],
            'Phone':
                '${profile['country_code'] ?? ''} ${profile['phone'] ?? ''}'
                    .trim(),
            'Role': profile['role'],
            'Designation': profile['designation'],
            'Department': profile['department'],
            'Date of Joining':
                profile['date_of_joining'] ?? profile['joining_date'],
            'Employment Type': profile['employment_type'],
            'Work Mode': profile['work_mode'] ?? profile['work_location'],
            'Reporting TL': profile['reporting_tl'],
            'Status': profile['status'],
          };
          final personal = <String, dynamic>{
            'Gender': profile['gender'],
            'Date of Birth': profile['dob'] ?? profile['date_of_birth'],
            'Blood Group': profile['blood_group'],
            'Nationality': profile['nationality'],
            'Marital Status': profile['marital_status'],
            'Address': address,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      EmployeeAvatar(
                        name: name,
                        photoUrl: photoUrl,
                        radius: 38,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(28),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (designation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          designation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeConfig.getTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (employeeId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ProfileBadge(employeeId),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ProfileSection(title: 'EMPLOYMENT DETAILS', entries: employment),
              const SizedBox(height: 14),
              _ProfileSection(title: 'PERSONAL DETAILS', entries: personal),
            ],
          );
        },
      ),
    );
  }
}

String _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = '${source[key] ?? ''}'.trim();
    if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
  }
  return '';
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Map<String, dynamic> entries;

  const _ProfileSection({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final visible = entries.entries
        .where((entry) => '${entry.value ?? ''}'.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: visible.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('No information provided'),
                  )
                : Column(
                    children: [
                      for (var index = 0; index < visible.length; index++) ...[
                        _ProfileRow(
                          label: visible[index].key,
                          value: '${visible[index].value}'.trim(),
                        ),
                        if (index < visible.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: ThemeConfig.getTextSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String text;

  const _ProfileBadge(this.text);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ProfileMessage({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: ThemeConfig.getTextSecondary(context)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class UserNotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const UserNotificationSettingsScreen({super.key, required this.userId});

  @override
  State<UserNotificationSettingsScreen> createState() =>
      _UserNotificationSettingsScreenState();
}

class _UserNotificationSettingsScreenState
    extends State<UserNotificationSettingsScreen> {
  final values = <String, bool>{
    'push': true,
    'leave': true,
    'attendance': true,
    'meetings': true,
  };
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(ApiConfig.uri('/profile/?user_id=${widget.userId}'))
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data is! Map) {
        throw Exception('Unable to load settings');
      }
      final profile = data['profile'];
      final preferences = profile is Map
          ? profile['notification_preferences']
          : null;
      if (preferences is Map) {
        for (final key in values.keys) {
          values[key] = preferences[key] != false;
        }
      }
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _update(String key, bool value) async {
    final previous = values[key]!;
    setState(() => values[key] = value);
    try {
      final response = await http
          .patch(
            ApiConfig.uri('/profile/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.userId,
              'notification_preferences': values,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Unable to save setting');
      }
    } catch (e) {
      if (mounted) {
        setState(() => values[key] = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = <String, String>{
      'push': 'Push notifications',
      'leave': 'Leave updates',
      'attendance': 'Attendance alerts',
      'meetings': 'Meeting reminders',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: labels.entries
                  .map(
                    (entry) => Card(
                      child: SwitchListTile(
                        title: Text(entry.value),
                        value: values[entry.key]!,
                        onChanged: (value) => _update(entry.key, value),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
