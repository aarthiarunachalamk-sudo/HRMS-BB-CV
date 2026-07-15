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

  Future<Map<String, dynamic>> fetchLeaveIntelligence(
    String userId, {
    required int year,
    required int month,
  }) => _getStrict(
    '/leave-intelligence/?${Uri(queryParameters: {
      'user_id': userId,
      'year': '$year',
      'month': '$month',
    }).query}',
  );

  Future<Map<String, dynamic>> fetchPayrollOverview(
    String userId, {
    required int year,
    required int month,
  }) => _getStrict(
    '/payroll-overview/?${Uri(queryParameters: {
      'user_id': userId,
      'year': '$year',
      'month': '$month',
    }).query}',
  );

  Future<Map<String, dynamic>> updatePayrollOverview(
    String userId, {
    required int year,
    required int month,
    required String action,
    bool declaration = false,
  }) => _postWithResponse('/payroll-overview/', {
    'user_id': userId,
    'year': year,
    'month': month,
    'action': action,
    'declaration': declaration,
  });

  Future<Map<String, dynamic>> fetchDocuments(String userId) =>
      _getStrict('/documents/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> fetchHiringPipeline(String userId) =>
      _getStrict('/hiring-pipeline/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> updateHiringPipeline(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/hiring-pipeline/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  Future<Map<String, dynamic>> fetchProjectsFlow(String userId) =>
      _getStrict('/projects-flow/?user_id=${Uri.encodeQueryComponent(userId)}');

  Future<Map<String, dynamic>> updateProjectsFlow(
    String userId,
    String action,
    Map<String, dynamic> fields,
  ) => _postWithResponse('/projects-flow/', {
    'user_id': userId,
    'action': action,
    ...fields,
  });

  Future<Map<String, dynamic>> fetchPerformanceMatrix(String userId, String period) =>
      _getStrict('/performance-matrix/?${Uri(queryParameters: {'user_id': userId, 'period': period}).query}');

  Future<Map<String, dynamic>> updatePerformanceMatrix(
    String userId, String period, String action, Map<String, dynamic> fields,
  ) => _postWithResponse('/performance-matrix/', {'user_id': userId, 'period': period, 'action': action, ...fields});

  Future<Map<String,dynamic>> fetchReportsFlow(String userId)=>_getStrict('/reports-flow/?user_id=${Uri.encodeQueryComponent(userId)}');
  Future<Map<String,dynamic>> updateReportsFlow(String userId,String action,Map<String,dynamic> fields)=>_postWithResponse('/reports-flow/',{'user_id':userId,'action':action,...fields});

  Future<Map<String, dynamic>> fetchAuditFlow(
    String userId,
    Map<String, dynamic> filters,
  ) {
    final query = <String, String>{'user_id': userId};
    for (final entry in filters.entries) {
      if (entry.value is String && '${entry.value}'.isNotEmpty) {
        query[entry.key] = '${entry.value}';
      }
    }
    final modules = (filters['modules'] as List?) ?? const [];
    final severities = (filters['severities'] as List?) ?? const [];
    var path = '/audit-flow/?${Uri(queryParameters: query).query}';
    for (final value in modules) {
      path += '&module=${Uri.encodeQueryComponent('$value')}';
    }
    for (final value in severities) {
      path += '&severity=${Uri.encodeQueryComponent('$value')}';
    }
    return _getStrict(path);
  }

  Future<Map<String, dynamic>> emailAuditReport(
    String userId,
    Map<String, dynamic> filters,
    String format,
    List<String> include,
  ) => _postWithResponse('/audit-flow/', {
    'user_id': userId,
    'action': 'export',
    'filters': filters,
    'format': format,
    'include': include,
  });

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
