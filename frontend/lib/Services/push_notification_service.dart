import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const _channel = AndroidNotificationChannel(
    'hrms_updates',
    'BBT HRMS updates',
    description:
        'Attendance, leave, approvals, payroll, tasks and BBT HRMS updates.',
    importance: Importance.high,
  );
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationTaps =>
      _notificationTapController.stream;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseUnavailableReported = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _registeredUserId;
  String? _registeredRole;

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      } catch (error) {
        if (!_firebaseUnavailableReported) {
          _firebaseUnavailableReported = true;
          debugPrint(
            'Push notifications are disabled because Firebase is not '
            'configured for this build: $error',
          );
        }
        return false;
      }
    }
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            _notificationTapController.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          _notificationTapController.add({'module': payload});
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _notificationTapController.add(message.data),
    );
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(
        Duration.zero,
        () => _notificationTapController.add(initialMessage.data),
      );
    }
    _initialized = true;
    return true;
  }

  Future<void> registerForUser(String userId, String role) async {
    final normalizedUserId = userId.trim();
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedUserId.isEmpty) return;
    try {
      if (!await initialize()) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Push token is not available for $normalizedUserId.');
        return;
      }
      await _registerToken(normalizedUserId, normalizedRole, token);

      if (_registeredUserId != normalizedUserId ||
          _registeredRole != normalizedRole) {
        await _tokenRefreshSubscription?.cancel();
        _registeredUserId = normalizedUserId;
        _registeredRole = normalizedRole;
        _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
            .listen(
              (refreshedToken) => _registerToken(
                normalizedUserId,
                normalizedRole,
                refreshedToken,
              ),
            );
      }
    } catch (error) {
      debugPrint('Push notification initialization failed: $error');
    }
  }

  Future<void> _registerToken(String userId, String role, String token) async {
    try {
      final response = await http.post(
        ApiConfig.uri('/notifications/device-token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'role': role,
          'token': token,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Push token registration failed: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      message.messageId.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'hrms_updates',
          'BBT HRMS updates',
          channelDescription:
              'Attendance, leave, approvals, payroll, tasks and BBT HRMS updates.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          groupKey: 'com.bitbyte.hrms.UPDATES',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
