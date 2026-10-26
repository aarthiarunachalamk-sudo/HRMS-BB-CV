import 'dart:convert';

import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class SaService {
  static const String _base = '${ApiConfig.baseUrl}/superadmin';
  static const Duration _timeout = Duration(seconds: 25);

  Future<Map<String, dynamic>> fetchDashboard({bool forceRefresh = false}) async {
    final uri = Uri.parse('$_base/dashboard/');
    try {
      return await ApiClient.getJsonCached(
        uri,
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      return _get('/dashboard/');
    }
  }

  Future<Map<String, dynamic>> fetchNotifications({String userId = ''}) =>
      _get('/notifications/${userId.isNotEmpty ? '?user_id=$userId' : ''}');

  Future<void> markNotificationRead(int pk, {String userId = ''}) async {
    try {
      await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$pk/read/'),
        body: {'user_id': userId, 'role': 'superadmin'},
        timeout: _timeout,
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await ApiClient
          .get(Uri.parse('$_base$path'), timeout: _timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      throw Exception('Superadmin backend unavailable: $error');
    }
    throw Exception('Superadmin backend returned invalid data.');
  }
}
