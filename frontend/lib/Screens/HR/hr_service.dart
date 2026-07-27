import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class HrService {
  static const String baseUrl = '${ApiConfig.baseUrl}/hr';
  static const Duration _timeout = Duration(seconds: 60);

  Future<Map<String, dynamic>> fetchDashboard(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/dashboard/?user_id=$userId'))
        .timeout(_timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception(_payrollError(response, 'HR dashboard API failed'));
  }

  Future<Map<String, dynamic>> fetchEmployeeIdentity(String employeeId) async {
    final response = await http
        .get(ApiConfig.uri('/hr/employees/$employeeId/identity/'))
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to load employee identity');
  }

  Future<Map<String, dynamic>> updateEmployeeIdentity(
    String currentEmployeeId,
    Map<String, dynamic> changes,
  ) async {
    final response = await http
        .patch(
          ApiConfig.uri('/hr/employees/$currentEmployeeId/identity/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(changes),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to update employee identity');
  }

  Map<String, dynamic> _decodeEmployeeResponse(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['success'] == true) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map && decoded['message'] != null) {
        throw Exception('${decoded['message']}');
      }
    } catch (error) {
      if (error is Exception) rethrow;
    }
    throw Exception('$fallback (${response.statusCode})');
  }

  Future<void> updateLeaveRequest(int leaveId, String status, String userId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/leave-requests/$leaveId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': status, 'user_id': userId, 'reviewed_by': userId}),
        )
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Leave approval failed with status ${response.statusCode}');
    }
  }

  Future<void> updateCheckoutPermission(
    int permissionId,
    String status,
    String userId,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/checkout-permissions/$permissionId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': status, 'user_id': userId}),
        )
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Check-out permission approval failed (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> generatePayroll(String userId, DateTime month) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/payroll/generate/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'year': month.year,
            'month': month.month,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    dynamic errorBody;
    try {
      errorBody = jsonDecode(response.body);
    } catch (_) {}
    if (errorBody is Map && errorBody['message'] != null) {
      throw Exception('${errorBody['message']}');
    }
    throw Exception('Generate payroll failed with status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchPayrollProcess(DateTime month) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/payroll/process/').replace(
            queryParameters: {'year': '${month.year}', 'month': '${month.month}'},
          ),
        )
        .timeout(_timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception(_payrollError(response, 'Load payroll process failed'));
  }

  Future<Map<String, dynamic>> updatePayrollProcess(
    String userId,
    DateTime month,
    String action, {
    String? issueId,
    Map<String, dynamic>? options,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/payroll/process/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'year': month.year,
            'month': month.month,
            'action': action,
            if (issueId != null) 'issue_id': issueId,
            if (options != null) 'options': options,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception(_payrollError(response, 'Payroll process update failed'));
  }

  String _payrollError(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) return '${decoded['message']}';
    } catch (_) {}
    return '$fallback with status ${response.statusCode}';
  }
}
