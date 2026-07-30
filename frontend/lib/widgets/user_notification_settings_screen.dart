import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:http/http.dart' as http;

class UserPersonalInformationScreen extends StatelessWidget {
  final String userId;

  const UserPersonalInformationScreen({super.key, required this.userId});

  Future<Map<String, dynamic>> _load() async {
    final response = await http.get(ApiConfig.uri('/profile/?user_id=$userId')).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || data is! Map) throw Exception('Unable to load profile');
    final raw = data['profile'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'.replaceFirst('Exception: ', '')));
          final profile = snapshot.data ?? const <String, dynamic>{};
          final address = [profile['door_no'], profile['street'], profile['city'], profile['state'], profile['pincode']]
              .map((value) => '${value ?? ''}'.trim()).where((value) => value.isNotEmpty).join(', ');
          final entries = <String, dynamic>{
            'Employee ID': profile['user_id'],
            'Name': '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
            'Email': profile['email'],
            'Phone': '${profile['country_code'] ?? ''} ${profile['phone'] ?? ''}'.trim(),
            'Role': profile['role'],
            'Designation': profile['designation'],
            'Department': profile['department'],
            'Address': address,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: entries.entries.map((entry) => Card(
              child: ListTile(
                title: Text(entry.key, style: Theme.of(context).textTheme.labelMedium),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${entry.value ?? ''}'.trim().isEmpty ? 'Not provided' : '${entry.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

class UserNotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const UserNotificationSettingsScreen({super.key, required this.userId});

  @override
  State<UserNotificationSettingsScreen> createState() => _UserNotificationSettingsScreenState();
}

class _UserNotificationSettingsScreenState extends State<UserNotificationSettingsScreen> {
  final values = <String, bool>{'push': true, 'leave': true, 'attendance': true, 'meetings': true};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(ApiConfig.uri('/profile/?user_id=${widget.userId}')).timeout(const Duration(seconds: 60));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || data is! Map) throw Exception('Unable to load settings');
      final profile = data['profile'];
      final preferences = profile is Map ? profile['notification_preferences'] : null;
      if (preferences is Map) {
        for (final key in values.keys) values[key] = preferences[key] != false;
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
      final response = await http.patch(
        ApiConfig.uri('/profile/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId, 'notification_preferences': values}),
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Unable to save setting');
    } catch (e) {
      if (mounted) {
        setState(() => values[key] = previous);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
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
                  children: labels.entries.map((entry) => Card(
                    child: SwitchListTile(
                      title: Text(entry.value),
                      value: values[entry.key]!,
                      onChanged: (value) => _update(entry.key, value),
                    ),
                  )).toList(),
                ),
    );
  }
}
