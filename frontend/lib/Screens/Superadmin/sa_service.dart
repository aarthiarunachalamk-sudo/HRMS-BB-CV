import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class SaService {
  static const String _base = '${ApiConfig.baseUrl}/superadmin';
  static const Duration _timeout = Duration(seconds: 12);

  // Cache dashboard data so FutureBuilders don't re-fetch on every rebuild
  static Map<String, dynamic>? _dashboardCache;
  static DateTime? _dashboardCacheTime;

  Future<Map<String, dynamic>> fetchDashboard({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _dashboardCache != null &&
        _dashboardCacheTime != null &&
        now.difference(_dashboardCacheTime!).inSeconds < 30) {
      return _dashboardCache!;
    }
    final result = await _get('/dashboard/');
    _dashboardCache = result;
    _dashboardCacheTime = now;
    return result;
  }

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
