import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class AccountServiceException implements Exception {
  final String message;
  final int? statusCode;

  AccountServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AccountService {
  /// Fetches any active deletion request for the given user.
  Future<Map<String, dynamic>> fetchActiveDeletionRequest(String userId) async {
    try {
      final uri = ApiConfig.uri('/account/delete-request/').replace(
        queryParameters: {'user_id': userId},
      );
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'has_active_request': false, 'request': null};
      }

      final errorMsg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Unable to check account deletion status.';
      throw AccountServiceException(errorMsg, response.statusCode);
    } on SocketException {
      throw AccountServiceException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw AccountServiceException('Request timed out. Please try again.');
    } on AccountServiceException {
      rethrow;
    } catch (e) {
      throw AccountServiceException('An unexpected error occurred: $e');
    }
  }

  /// Submits an account deletion request to the backend.
  Future<Map<String, dynamic>> requestAccountDeletion({
    required String userId,
    String? password,
    String? reason,
    String? details,
  }) async {
    try {
      final uri = ApiConfig.uri('/account/delete-request/');
      final payload = {
        'user_id': userId,
        if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      };

      final response = await ApiClient.post(uri, body: payload);
      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode >= 200 && response.statusCode < 300)) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Account deletion request submitted.'};
      }

      if (response.statusCode == 409) {
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'You already have an active deletion request pending review.';
        throw AccountServiceException(msg, 409);
      }

      if (response.statusCode == 400) {
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'Invalid password or verification failed.';
        throw AccountServiceException(msg, 400);
      }

      final errorMsg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Unable to submit deletion request.';
      throw AccountServiceException(errorMsg, response.statusCode);
    } on SocketException {
      throw AccountServiceException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw AccountServiceException('Request timed out. Please try again.');
    } on AccountServiceException {
      rethrow;
    } catch (e) {
      throw AccountServiceException('Unable to complete request. Please try again later.');
    }
  }

  /// Cancels an existing pending or under review deletion request.
  Future<Map<String, dynamic>> cancelDeletionRequest(String userId) async {
    try {
      final uri = ApiConfig.uri('/account/delete-request/cancel/');
      final response = await ApiClient.post(uri, body: {'user_id': userId});
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Request cancelled.'};
      }

      final errorMsg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Unable to cancel deletion request.';
      throw AccountServiceException(errorMsg, response.statusCode);
    } on SocketException {
      throw AccountServiceException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw AccountServiceException('Request timed out. Please try again.');
    } on AccountServiceException {
      rethrow;
    } catch (e) {
      throw AccountServiceException('Unable to cancel deletion request. Please try again.');
    }
  }

  /// Admin: Fetches all account deletion requests with optional filter & search.
  Future<Map<String, dynamic>> fetchAdminDeletionRequests({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toUpperCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = ApiConfig.uri('/account/delete-requests/').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'requests': [], 'counts': {}};
      }

      final errorMsg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Unable to load deletion requests.';
      throw AccountServiceException(errorMsg, response.statusCode);
    } on SocketException {
      throw AccountServiceException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw AccountServiceException('Request timed out. Please try again.');
    } on AccountServiceException {
      rethrow;
    } catch (e) {
      throw AccountServiceException('Failed to load deletion requests: $e');
    }
  }

  /// Admin: Updates status of a deletion request (under_review, approve, reject, complete).
  Future<Map<String, dynamic>> updateAdminDeletionRequest({
    required int id,
    required String action,
    String? remarks,
  }) async {
    try {
      final uri = ApiConfig.uri('/account/delete-requests/$id/action/');
      final payload = {
        'action': action,
        if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      };
      final response = await ApiClient.post(uri, body: payload);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Status updated.'};
      }

      final errorMsg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Unable to update request status.';
      throw AccountServiceException(errorMsg, response.statusCode);
    } on SocketException {
      throw AccountServiceException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw AccountServiceException('Request timed out. Please try again.');
    } on AccountServiceException {
      rethrow;
    } catch (e) {
      throw AccountServiceException('Failed to update request: $e');
    }
  }
}
