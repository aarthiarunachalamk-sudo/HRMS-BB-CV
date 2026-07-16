import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';

class MeetingNotificationGate extends StatefulWidget {
  final String userId;
  final String role;
  final Widget child;

  const MeetingNotificationGate({
    super.key,
    required this.userId,
    required this.role,
    required this.child,
  });

  @override
  State<MeetingNotificationGate> createState() => _MeetingNotificationGateState();
}

class _MeetingNotificationGateState extends State<MeetingNotificationGate> {
  Timer? _timer;
  bool _dialogOpen = false;
  final Set<int> _shownNotificationIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkMeetingNotification(waitForGreeting: true),
    );
    _timer = Timer.periodic(
      const Duration(seconds: 120),
      (_) => _checkMeetingNotification(),
    );
  }

  Future<void> _checkMeetingNotification({bool waitForGreeting = false}) async {
    if (_dialogOpen || widget.userId.trim().isEmpty) return;
    if (waitForGreeting) {
      await AppGreetingSession.waitUntilDismissed();
      if (!mounted) return;
    }

    try {
      final uri = ApiConfig.uri(
        '/notifications/?user_id=${Uri.encodeQueryComponent(widget.userId)}'
        '&role=${Uri.encodeQueryComponent(widget.role)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['notifications'] is! List) return;

      final notification = (decoded['notifications'] as List).whereType<Map>().firstWhere(
        (item) =>
            '${item['module']}'.toLowerCase() == 'meeting' &&
            item['is_read'] != true,
        orElse: () => const {},
      );
      if (notification.isEmpty || !mounted) return;
      final notificationId = int.tryParse('${notification['id']}');
      if (notificationId != null && _shownNotificationIds.contains(notificationId)) {
        return;
      }
      if (notificationId != null) _shownNotificationIds.add(notificationId);

      final title = '${notification['title'] ?? 'Meeting Scheduled'}';
      final message = '${notification['message'] ?? notification['subtitle'] ?? ''}';
      _dialogOpen = true;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message.isEmpty ? 'You have a scheduled meeting.' : message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      await _markRead(notification['id']);
    } catch (_) {
      _dialogOpen = false;
      // Notification popups should never block dashboard loading.
    }
  }

  Future<void> _markRead(dynamic id) async {
    final notificationId = int.tryParse('$id');
    if (notificationId == null) return;
    try {
      await http
          .post(
            ApiConfig.uri('/notifications/$notificationId/read/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': widget.userId, 'role': widget.role}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
