import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

import 'employee_models.dart';

class EmployeeService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/employee';

  Future<EmployeeDashboardData> fetchDashboard(
    String userId,
    String email,
  ) async {
    final uri = Uri.parse('$_baseUrl/dashboard/?user_id=$userId&email=$email');
    final response = await http.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return EmployeeDashboardData.fromJson(
        _decodeMap(response, 'Employee dashboard API returned invalid data'),
      );
    }
    throw Exception(_responseError(response, 'Employee dashboard API failed'));
  }

  Future<Map<String, dynamic>> checkIn(
    String userId,
    Map<String, dynamic> attendanceProof,
  ) {
    return _postAttendance('/check-in/', {
      'user_id': userId,
      ...attendanceProof,
    });
  }

  Future<Map<String, dynamic>> checkOut(
    String userId,
    Map<String, dynamic> attendanceProof,
  ) {
    return _postAttendance('/check-out/', {
      'user_id': userId,
      ...attendanceProof,
    });
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceHistory(
    String userId,
    DateTime fromDate,
    DateTime toDate,
  ) {
    return _getRecords('/attendance-history/', userId, fromDate, toDate);
  }

  Future<EmployeeLeaveHistoryResult> fetchLeaveHistory(
    String userId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final body = await _getRecordBody('/leave-history/', userId, fromDate, toDate);
    return EmployeeLeaveHistoryResult(
      records: _recordsFromBody(body),
      leaveBalances: Map<String, dynamic>.from(
        body['leave_balances'] is Map ? body['leave_balances'] as Map : const {},
      ),
    );
  }

  Future<Map<String, dynamic>> submitLeave(
    String userId,
    Map<String, dynamic> leave,
  ) async {
    final certificatePath = '${leave['medical_certificate_path'] ?? ''}';
    if (certificatePath.isEmpty) {
      return _post('/leave-request/', {'user_id': userId, ...leave});
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/leave-request/'),
    );
    request.fields['user_id'] = userId;
    for (final entry in leave.entries) {
      if (entry.key != 'medical_certificate_path') {
        request.fields[entry.key] = '${entry.value}';
      }
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        'medical_certificate',
        certificatePath,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(response, 'Employee API returned invalid data');
    }
    throw Exception(_responseError(response, 'Employee API failed'));
  }

  Future<Map<String, dynamic>> fetchPayslip(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payslip/').replace(
        queryParameters: {'user_id': userId},
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeMap(response, 'Employee payslip API returned invalid data');
      return Map<String, dynamic>.from(body['payslip'] is Map ? body['payslip'] as Map : const {});
    }
    throw Exception(_responseError(response, 'Employee payslip API failed'));
  }

  Future<Map<String, dynamic>> reuploadDocument(
    String userId,
    String documentKey,
    String filePath,
    String fileType,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/documents/reupload/'),
    );
    request.fields['user_id'] = userId;
    request.fields['document_key'] = documentKey;
    request.fields['file_type'] = fileType;
    request.files.add(await http.MultipartFile.fromPath('document', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(response, 'Employee document API returned invalid data');
    }
    throw Exception(_responseError(response, 'Employee document API failed'));
  }

  Future<Map<String, dynamic>> completeTask(String userId, Object taskId) {
    return _post('/task-complete/', {'user_id': userId, 'task_id': taskId});
  }

  Future<Map<String, dynamic>> fetchApprovals(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/approvals/').replace(queryParameters: {'user_id': userId}));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(response, 'Employee approvals API returned invalid data');
    }
    throw Exception(_responseError(response, 'Employee approvals API failed'));
  }

  Future<Map<String, dynamic>> submitDailyApproval(String userId, Map<String, dynamic> request) {
    return _post('/approvals/', {'user_id': userId, ...request});
  }

  Future<Map<String, dynamic>> updateApproval(
    String userId,
    Object approvalId,
    String action, {
    String comment = '',
  }) => _post('/approvals/$approvalId/action/', {
    'user_id': userId,
    'action': action,
    'comment': comment,
  });

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(response, 'Employee API returned invalid data');
    }
    throw Exception(_responseError(response, 'Employee API failed'));
  }

  Future<List<Map<String, dynamic>>> _getRecords(
    String path,
    String userId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    return _recordsFromBody(
      await _getRecordBody(path, userId, fromDate, toDate),
    );
  }

  Future<Map<String, dynamic>> _getRecordBody(
    String path,
    String userId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: {
        'user_id': userId,
        'from_date': _dateParam(fromDate),
        'to_date': _dateParam(toDate),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(response, 'Employee API returned invalid data');
    }
    throw Exception(_responseError(response, 'Employee API failed'));
  }

  List<Map<String, dynamic>> _recordsFromBody(Map<String, dynamic> body) {
    return List<Map<String, dynamic>>.from(
      (body['records'] is List ? body['records'] as List : const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  String _dateParam(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Map<String, dynamic>> _postAttendance(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    final selfiePath = '${payload['selfie_path'] ?? ''}';

    for (final entry in payload.entries) {
      if (entry.key != 'selfie_path') {
        request.fields[entry.key] = '${entry.value}';
      }
    }
    if (selfiePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('selfie', selfiePath),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeMap(
        response,
        'Employee attendance API returned invalid data',
      );
    }
    throw Exception(_responseError(response, 'Employee attendance API failed'));
  }

  Map<String, dynamic> _decodeMap(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception(_nonJsonMessage(response, fallback));
    }
    throw Exception(fallback);
  }

  String _responseError(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return '${decoded['message']}';
      }
    } catch (_) {
      return _nonJsonMessage(response, fallback);
    }
    return '$fallback with status ${response.statusCode}';
  }

  String _nonJsonMessage(http.Response response, String fallback) {
    final body = response.body.trimLeft();
    if (body.startsWith('<!DOCTYPE html') || body.startsWith('<html')) {
      return '$fallback with status ${response.statusCode}. Backend returned an HTML error page. Run Django migrations and check backend logs.';
    }
    return '$fallback with status ${response.statusCode}. Backend did not return JSON.';
  }
}

class EmployeeLeaveHistoryResult {
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> leaveBalances;

  const EmployeeLeaveHistoryResult({
    required this.records,
    required this.leaveBalances,
  });
}
