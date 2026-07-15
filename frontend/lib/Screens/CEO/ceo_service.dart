import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class CeoService {
  static const String _base = '${ApiConfig.baseUrl}/ceo';

  // ── Dashboard ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchDashboard(String userId) =>
      _getStrict('/dashboard/?user_id=$userId');

  Future<Map<String, dynamic>> fetchOrganization(String userId) =>
      _getStrict('/organization/?user_id=$userId');

  Future<Map<String, dynamic>> saveOrganization(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/organization/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  // ── Analytics ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAnalytics(String userId) =>
      _get('/analytics/?user_id=$userId');

  // ── Reports ───────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchReports(String userId) =>
      _get('/reports/?user_id=$userId');

  // ── Approvals ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchApprovals(String userId) =>
      _get('/approvals/?user_id=$userId');

  Future<Map<String, dynamic>> fetchApprovalCategory(
    String category,
    String userId, {
    bool history = false,
  }) =>
      _get('/approval-categories/$category/?user_id=$userId&history=$history');

  Future<Map<String, dynamic>> fetchLeaveDetail(int leaveId) =>
      _get('/leave-detail/$leaveId/');

  Future<Map<String, dynamic>> updateApproval(
    String leaveId,
    String status,
    String reviewedBy,
  ) => _post('/approvals/$leaveId/', {
    'status': status,
    'user_id': reviewedBy,
    'reviewed_by': reviewedBy,
  });

  // ── Employees ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEmployees(String userId) =>
      _get('/employees/?user_id=$userId');

  // ── Notifications ─────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEmployeeAttendance(String employeeId) =>
      _get('/employee-attendance/?employee_id=$employeeId');

  Future<Map<String, dynamic>> fetchAttendanceIntelligence(
    String userId, {
    String? dateFrom,
    String? dateTo,
    String? selectedDate,
  }) {
    final query = <String, String>{'user_id': userId};
    if (dateFrom?.isNotEmpty == true) query['date_from'] = dateFrom!;
    if (dateTo?.isNotEmpty == true) query['date_to'] = dateTo!;
    if (selectedDate?.isNotEmpty == true) query['date'] = selectedDate!;
    return _getStrict(
      '/attendance-intelligence/?${Uri(queryParameters: query).query}',
    );
  }

  Future<Map<String, dynamic>> fetchNotifications(String userId) =>
      _get('/notifications/?user_id=$userId');

  Future<Map<String, dynamic>> markNotificationRead(
    int notificationId,
    String userId,
  ) => _post('/notifications/$notificationId/read/', {'user_id': userId});

  // ── Meetings ──────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchMeetings(String userId) =>
      _get('/meetings/?user_id=$userId');

  // ── Budget ────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchBudget(String userId) =>
      _get('/budget/?user_id=$userId');

  // ── Department performance ────────────────────────────────
  Future<Map<String, dynamic>> fetchDepartmentPerformance(String userId) =>
      _get('/department-performance/?user_id=$userId');

  Future<Map<String, dynamic>> saveDepartment(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/department-performance/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  // ── Branch performance ────────────────────────────────────
  Future<Map<String, dynamic>> fetchBranchPerformance(String userId) =>
      _get('/branch-performance/?user_id=$userId');

  // ── HTTP helpers ──────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _getStrict(String path) async {
    final res = await http
        .get(Uri.parse('$_base$path'))
        .timeout(const Duration(seconds: 45));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend returned ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Backend returned invalid dashboard data');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _postWithResponse(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      final decoded = jsonDecode(res.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (error) {
      return {'success': false, 'message': error.toString()};
    }
    return {'success': false, 'message': 'Invalid server response.'};
  }
}
