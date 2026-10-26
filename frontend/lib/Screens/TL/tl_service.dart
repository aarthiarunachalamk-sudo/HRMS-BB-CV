import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class TlService {
  static const String baseUrl = '${ApiConfig.baseUrl}/tl';

  Future<Map<String, dynamic>> fetchDashboard(String userId, {bool forceRefresh = false}) async {
    final uri = Uri.parse(
      '$baseUrl/dashboard/',
    ).replace(queryParameters: {'user_id': userId});
    try {
      return await ApiClient.getJsonCached(
        uri,
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      final response = await ApiClient.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      throw Exception(_errorMessage(response, 'TL API failed'));
    }
  }

  Future<Map<String, dynamic>> fetchApprovals(String userId, {bool forceRefresh = false}) async {
    final uri = Uri.parse(
      '$baseUrl/approvals/',
    ).replace(queryParameters: {'user_id': userId});
    try {
      return await ApiClient.getJsonCached(
        uri,
        ttl: const Duration(seconds: 20),
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      final response = await ApiClient.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      throw Exception(_errorMessage(response, 'TL approvals API failed'));
    }
  }

  Future<void> markNotificationRead(String userId, int notificationId) async {
    final response = await ApiClient.post(
      ApiConfig.uri('/notifications/$notificationId/read/'),
      body: {'user_id': userId},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response, 'Unable to mark notification as read'),
      );
    }
  }

  Future<Map<String, dynamic>> fetchLeaveRequest(int leaveId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/leave-requests/$leaveId/'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception(_errorMessage(response, 'Leave detail failed'));
  }

  Future<void> scheduleMeeting(Map<String, dynamic> payload) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/meetings/'),
      body: payload,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Schedule meeting failed'));
    }
  }

  Future<void> createTask(Map<String, dynamic> payload) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/tasks/'),
      body: payload,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Create task failed'));
    }
  }

  Future<void> updateLeaveRequest(
    int leaveId,
    String status,
    String userId, {
    String rejectionReason = '',
  }) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/leave-requests/$leaveId/'),
      body: {
        'status': status,
        'user_id': userId,
        'reviewed_by': userId,
        'rejection_reason': rejectionReason,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Leave approval failed'));
    }
  }

  Future<void> updateCheckoutPermission(
    int permissionId,
    String status,
    String userId, {
    String rejectionReason = '',
  }) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/checkout-permissions/$permissionId/'),
      body: {
        'status': status,
        'user_id': userId,
        'review_note': rejectionReason,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response, 'Check-out permission approval failed'),
      );
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return '$fallback: ${decoded['message']}';
      }
    } catch (_) {
      // Keep the status/body fallback below.
    }
    final body = response.body.trim();
    return body.isEmpty
        ? '$fallback with status ${response.statusCode}'
        : '$fallback with status ${response.statusCode}: $body';
  }
}
