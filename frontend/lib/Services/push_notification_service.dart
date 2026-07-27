import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const _channel = AndroidNotificationChannel(
    'attendance_reminders',
    'Attendance reminders',
    description: 'Check-in and attendance reminders from HRMS.',
    importance: Importance.high,
  );
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
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
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _initialized = true;
  }

  Future<void> registerForUser(String userId, String role) async {
    if (userId.trim().isEmpty) return;
    try {
      await initialize();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(userId, role, token);
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _registerToken(userId, role, token),
      );
    } catch (error) {
      debugPrint('Push notification initialization failed: $error');
    }
  }

  Future<void> _registerToken(String userId, String role, String token) async {
    try {
      await http.post(
        ApiConfig.uri('/notifications/device-token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'role': role,
          'token': token,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }),
      );
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
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_reminders',
          'Attendance reminders',
          channelDescription: 'Check-in and attendance reminders from HRMS.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['module']?.toString(),
    );
  }
}
