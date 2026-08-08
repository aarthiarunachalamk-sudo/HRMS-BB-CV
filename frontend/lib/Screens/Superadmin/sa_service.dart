import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class SaService {
  static const String _base = '${ApiConfig.baseUrl}/superadmin';
  static const Duration _timeout = Duration(seconds: 12);

  Future<Map<String, dynamic>> fetchDashboard() => _get('/dashboard/');

  Future<Map<String, dynamic>> fetchNotifications({String userId = ''}) =>
      _get('/notifications/${userId.isNotEmpty ? '?user_id=$userId' : ''}');

  Future<void> markNotificationRead(int pk, {String userId = ''}) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$pk/read/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'role': 'superadmin'}),
      ).timeout(_timeout);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'))
          .timeout(_timeout);
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
