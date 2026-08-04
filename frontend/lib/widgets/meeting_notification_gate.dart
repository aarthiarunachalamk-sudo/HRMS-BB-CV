import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';

class DashboardNotificationGate extends StatefulWidget {
  final String userId;
  final String role;
  final Widget child;

  const DashboardNotificationGate({
    super.key,
    required this.userId,
    required this.role,
    required this.child,
  });

  @override
  State<DashboardNotificationGate> createState() =>
      _DashboardNotificationGateState();
}

class _DashboardNotificationGateState extends State<DashboardNotificationGate> {
  static const _storage = FlutterSecureStorage();
  static const _popupFreshness = Duration(minutes: 15);
  Timer? _timer;
  bool _dialogOpen = false;
  final Set<int> _shownNotificationIds = <int>{};
  late final Future<void> _dismissedIdsLoaded;

  @override
  void initState() {
    super.initState();
    _dismissedIdsLoaded = _loadDismissedIds();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkDashboardNotification(waitForGreeting: true),
    );
    _timer = Timer.periodic(
      const Duration(seconds: 120),
      (_) => _checkDashboardNotification(),
    );
  }

  Future<void> _checkDashboardNotification({
    bool waitForGreeting = false,
  }) async {
    if (_dialogOpen || widget.userId.trim().isEmpty) return;
    if (waitForGreeting) {
      await AppGreetingSession.waitUntilDismissed();
      if (!mounted) return;
    }

    try {
      await _dismissedIdsLoaded;
      final uri = ApiConfig.uri(
        '/notifications/?user_id=${Uri.encodeQueryComponent(widget.userId)}'
        '&role=${Uri.encodeQueryComponent(widget.role)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['notifications'] is! List) return;

      final popupNotifications = (decoded['notifications'] as List)
          .whereType<Map>()
          .where((item) => _notificationPresentation(item) != null)
          .toList();

      // Historical unread records remain available in notification history,
      // but must never reopen as dashboard popups after a later login.
      final staleIds = popupNotifications
          .where((item) => item['is_read'] != true && !_isFresh(item))
          .map((item) => int.tryParse('${item['id']}'))
          .whereType<int>()
          .where((id) => !_shownNotificationIds.contains(id))
          .toList();
      if (staleIds.isNotEmpty) {
        _shownNotificationIds.addAll(staleIds);
        await _persistDismissedIds();
        for (final id in staleIds) {
          unawaited(_markRead(id));
        }
      }

      final notification = popupNotifications.firstWhere((item) {
        final id = int.tryParse('${item['id']}');
        return id != null &&
            !_shownNotificationIds.contains(id) &&
            item['is_read'] != true &&
            _isFresh(item);
      }, orElse: () => const {});
      if (notification.isEmpty || !mounted) return;
      final notificationId = int.tryParse('${notification['id']}');
      if (notificationId != null) {
        _shownNotificationIds.add(notificationId);
        await _persistDismissedIds();
      }
      if (!mounted) return;

      final presentation = _notificationPresentation(notification);
      if (presentation == null) return;
      final title = '${notification['title'] ?? presentation.fallbackTitle}';
      final message =
          '${notification['message'] ?? notification['subtitle'] ?? ''}';
      _dialogOpen = true;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AppCelebrationDialog(
          title: title,
          message: message.isEmpty ? presentation.fallbackMessage : message,
          icon: presentation.icon,
          accent: presentation.accent,
          buttonLabel: presentation.buttonLabel,
        ),
      );
      _dialogOpen = false;
      await _markRead(notification['id']);
    } catch (_) {
      _dialogOpen = false;
      // Dashboard popups should never block dashboard loading.
    }
  }

  bool _isFresh(Map notification) {
    final createdAt = DateTime.tryParse('${notification['created_at'] ?? ''}');
    if (createdAt == null) return false;
    final age = DateTime.now().toUtc().difference(createdAt.toUtc());
    // A slightly future timestamp can occur because of device/server clock
    // skew, so it is still treated as a new notification.
    return age <= _popupFreshness && age >= const Duration(minutes: -5);
  }

  String get _dismissedStorageKey =>
      'dismissed_dashboard_popups_${widget.userId.trim()}';

  String get _legacyMeetingStorageKey =>
      'dismissed_meeting_notifications_${widget.userId.trim()}';

  Future<void> _loadDismissedIds() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _dismissedStorageKey),
        _storage.read(key: _legacyMeetingStorageKey),
      ]);
      _shownNotificationIds.addAll(
        values
            .whereType<String>()
            .expand((value) => value.split(','))
            .map(int.tryParse)
            .whereType<int>(),
      );
    } catch (_) {
      // The backend read-state remains the fallback when secure storage fails.
    }
  }

  Future<void> _persistDismissedIds() async {
    try {
      final ids = _shownNotificationIds.toList()..sort();
      final retained = ids.length > 150 ? ids.sublist(ids.length - 150) : ids;
      await _storage.write(
        key: _dismissedStorageKey,
        value: retained.join(','),
      );
    } catch (_) {
      // A local persistence failure must not block the dashboard.
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

class _NotificationPresentation {
  final String fallbackTitle;
  final String fallbackMessage;
  final IconData icon;
  final Color accent;
  final String buttonLabel;

  const _NotificationPresentation({
    required this.fallbackTitle,
    required this.fallbackMessage,
    required this.icon,
    required this.accent,
    required this.buttonLabel,
  });
}

_NotificationPresentation? _notificationPresentation(Map notification) {
  final module = '${notification['module'] ?? ''}'.trim().toLowerCase();
  final type = '${notification['type'] ?? ''}'.trim().toLowerCase();
  final searchable = [
    notification['title'],
    notification['message'],
    notification['subtitle'],
  ].join(' ').toLowerCase();

  if (module == 'company_leave' || module == 'company-leave') {
    return const _NotificationPresentation(
      fallbackTitle: 'Company Leave Announced',
      fallbackMessage: 'The company has announced an upcoming leave day.',
      icon: Icons.beach_access_rounded,
      accent: Color(0xFF8B72FF),
      buttonLabel: 'Got it',
    );
  }

  if (module == 'meeting') {
    return const _NotificationPresentation(
      fallbackTitle: 'Meeting Scheduled',
      fallbackMessage: 'You have a scheduled meeting.',
      icon: Icons.video_camera_front_rounded,
      accent: Color(0xFF2F91FF),
      buttonLabel: 'Got it',
    );
  }

  const celebrationModules = {
    'announcement',
    'announcements',
    'company_news',
    'company-news',
    'happy_news',
    'happy-news',
    'celebration',
    'celebrations',
  };
  final happyNews = RegExp(
    r'\b(happy|congrat|celebrat|birthday|anniversary|award|achievement|promotion|welcome|festival|holiday|good news|milestone)\w*',
  ).hasMatch(searchable);
  if (celebrationModules.contains(module) && (type == 'success' || happyNews)) {
    return const _NotificationPresentation(
      fallbackTitle: 'Happy News!',
      fallbackMessage: 'The company has shared something worth celebrating.',
      icon: Icons.celebration_rounded,
      accent: Color(0xFFFFB020),
      buttonLabel: 'Wonderful!',
    );
  }

  return null;
}
