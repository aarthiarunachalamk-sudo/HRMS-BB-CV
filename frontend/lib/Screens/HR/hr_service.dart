import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class HrService {
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http
        .get(ApiConfig.uri('/profile/?user_id=$userId'))
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to load profile');
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final response = await http
        .patch(
          ApiConfig.uri('/profile/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, ...fields}),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to update profile');
  }

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
    return _decodeEmployeeResponse(
      response,
      'Unable to load employee identity',
    );
  }

  Future<Map<String, dynamic>> fetchEmployeeDetails(String employeeId) async {
    final response = await http
        .get(ApiConfig.uri('/hr/employees/$employeeId/details/'))
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to load employee details');
  }

  Future<Map<String, dynamic>> fetchAttendanceDetails(int attendanceId) async {
    final response = await http
        .get(ApiConfig.uri('/hr/attendance/$attendanceId/'))
        .timeout(_timeout);
    return _decodeEmployeeResponse(
      response,
      'Unable to load attendance details',
    );
  }

  Future<Map<String, dynamic>> fetchDocuments(
    String userId, {
    String query = '',
    String status = '',
  }) async {
    final parameters = <String, String>{'user_id': userId};
    if (query.trim().isNotEmpty) parameters['query'] = query.trim();
    if (status.trim().isNotEmpty) parameters['status'] = status.trim();
    final response = await http
        .get(
          ApiConfig.uri('/hr/documents/').replace(queryParameters: parameters),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to load documents');
  }

  Future<Map<String, dynamic>> fetchMeetingCenter(String userId) async {
    final response = await http
        .get(
          ApiConfig.uri(
            '/hr/meetings/',
          ).replace(queryParameters: {'user_id': userId}),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to load meetings');
  }

  Future<Map<String, dynamic>> scheduleMeeting(
    String userId,
    Map<String, dynamic> meeting,
  ) async {
    final response = await http
        .post(
          ApiConfig.uri('/hr/meetings/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, ...meeting}),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to schedule meeting');
  }

  Future<Map<String, dynamic>> cancelMeeting(
    String userId,
    int meetingId,
  ) async {
    final response = await http
        .patch(
          ApiConfig.uri('/hr/meetings/$meetingId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'action': 'cancel'}),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to cancel meeting');
  }

  Future<Map<String, dynamic>> uploadDocument(
    String userId, {
    required String filePath,
    required String documentType,
    required String ownerUserId,
    required String ownerRole,
    String documentNumber = '',
    String expiryDate = '',
    String remarks = '',
  }) async {
    final request =
        http.MultipartRequest('POST', ApiConfig.uri('/hr/documents/'))
          ..fields.addAll({
            'user_id': userId,
            'document_type': documentType,
            'owner_user_id': ownerUserId,
            'owner_role': ownerRole,
            'document_number': documentNumber,
            'expiry_date': expiryDate,
            'remarks': remarks,
          })
          ..files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    return _decodeEmployeeResponse(response, 'Unable to upload document');
  }

  Future<Map<String, dynamic>> updateDocumentStatus(
    String userId,
    int documentId,
    String status, {
    String remarks = '',
  }) async {
    final response = await http
        .patch(
          ApiConfig.uri('/hr/documents/$documentId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'status': status,
            'remarks': remarks,
          }),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to update document');
  }

  Future<Map<String, dynamic>> deleteDocument(
    String userId,
    int documentId,
  ) async {
    final response = await http
        .delete(
          ApiConfig.uri(
            '/hr/documents/$documentId/',
          ).replace(queryParameters: {'user_id': userId}),
        )
        .timeout(_timeout);
    return _decodeEmployeeResponse(response, 'Unable to delete document');
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
    return _decodeEmployeeResponse(
      response,
      'Unable to update employee identity',
    );
  }

  Map<String, dynamic> _decodeEmployeeResponse(
    http.Response response,
    String fallback,
  ) {
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

  Future<void> updateLeaveRequest(
    int leaveId,
    String status,
    String userId,
    String approverComments,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/leave-requests/$leaveId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': status,
            'user_id': userId,
            'reviewed_by': userId,
            'approver_comments': approverComments,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Leave approval failed with status ${response.statusCode}',
      );
    }
  }

  Future<void> updateCheckoutPermission(
    int permissionId,
    String status,
    String userId,
    String approverComments,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/checkout-permissions/$permissionId/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': status,
            'user_id': userId,
            'review_note': approverComments,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Check-out permission approval failed (${response.statusCode})',
      );
    }
  }

  Future<Map<String, dynamic>> scheduleInterview(
    int candidateId,
    Map<String, dynamic> data,
  ) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/recruitment/candidates/$candidateId/schedule-interview/',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    final decoded = jsonDecode(response.body);
    if (decoded is Map &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception(
      decoded is Map && decoded['message'] != null
          ? '${decoded['message']}'
          : 'Unable to schedule interview (${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> generatePayroll(
    String userId,
    DateTime month,
  ) async {
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
    throw Exception(
      'Generate payroll failed with status ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> fetchPayrollProcess(DateTime month) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/payroll/process/').replace(
            queryParameters: {
              'year': '${month.year}',
              'month': '${month.month}',
            },
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
            'issue_id': ?issueId,
            'options': ?options,
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
      if (decoded is Map && decoded['message'] != null) {
        return '${decoded['message']}';
      }
    } catch (_) {}
    return '$fallback with status ${response.statusCode}';
  }
}
