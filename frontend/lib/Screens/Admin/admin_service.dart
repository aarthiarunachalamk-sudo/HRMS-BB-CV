import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class AdminService {
  static const String baseUrl = '${ApiConfig.baseUrl}/admin';

  Future<Map<String, dynamic>> fetchDashboard(String userId) =>
      _get('/dashboard/?user_id=$userId');

  Future<Map<String, dynamic>> fetchEmployees(String userId) =>
      _get('/employees/?user_id=$userId');

  Future<Map<String, dynamic>> fetchEmployee(String employeeId) =>
      _get('/employees/$employeeId/');

  Future<Map<String, dynamic>> fetchAttendance(String userId) =>
      _get('/attendance/?user_id=$userId');

  Future<Map<String, dynamic>> fetchLeaves(String userId) =>
      _get('/leaves/?user_id=$userId');

  Future<Map<String, dynamic>> fetchReports(String userId) =>
      _get('/reports/?user_id=$userId');

  Future<Map<String, dynamic>> fetchMeetings(String userId) =>
      _get('/meetings/?user_id=$userId');

  Future<Map<String, dynamic>> fetchTasks(String userId) =>
      _get('/tasks/?user_id=$userId');

  Future<Map<String, dynamic>> fetchAssets(String userId) =>
      _get('/assets/?user_id=$userId');

  Future<Map<String, dynamic>> fetchNotifications(String userId) =>
      _get('/notifications/?user_id=$userId');

  Future<Map<String, dynamic>> fetchProfile(String userId) =>
      _get('/profile/?user_id=$userId');

  Future<Map<String, dynamic>> approveLeave(String leaveId, String status) =>
      _post('/leaves/$leaveId/approve/', {'status': status});

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) =>
      _post('/employees/create/', data);

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$path'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }
}
