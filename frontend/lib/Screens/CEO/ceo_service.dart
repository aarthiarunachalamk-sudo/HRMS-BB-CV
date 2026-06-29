import 'dart:convert';

import 'package:http/http.dart' as http;

class CeoService {
  static const String baseUrl = 'http://192.168.1.56:8000/api/ceo';

  Future<Map<String, dynamic>> fetchDashboard(String userId) {
    return _get('/dashboard/');
  }

  Future<Map<String, dynamic>> fetchAnalytics(String userId) {
    return _get('/analytics/');
  }

  Future<Map<String, dynamic>> fetchReports(String userId) {
    return _get('/reports/');
  }

  Future<Map<String, dynamic>> fetchApprovals(String userId) {
    return _get('/approvals/');
  }

  Future<Map<String, dynamic>> fetchEmployees(String userId) {
    return _get('/employees/');
  }

  Future<Map<String, dynamic>> fetchNotifications(String userId) {
    return _get('/notifications/');
  }

  Future<Map<String, dynamic>> fetchMeetings(String userId) {
    return _get('/meetings/');
  }

  Future<Map<String, dynamic>> fetchBudget(String userId) {
    return _get('/budget/');
  }

  Future<Map<String, dynamic>> fetchDepartmentPerformance(String userId) {
    return _get('/department-performance/');
  }

  Future<Map<String, dynamic>> fetchBranchPerformance(String userId) {
    return _get('/branch-performance/');
  }

  Future<Map<String, dynamic>> updateApproval(String approvalId, String status) {
    return _post('/approvals/$approvalId/', {'status': status});
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception('CEO API failed with status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception('CEO API failed with status ${response.statusCode}');
  }
}
