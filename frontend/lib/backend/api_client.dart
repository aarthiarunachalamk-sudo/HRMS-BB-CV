import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_session.dart';

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isFresh(Duration ttl) =>
      DateTime.now().difference(timestamp) < ttl;
}

/// Centralized, high-performance API client.
/// Provides HTTP Keep-Alive connection pooling, automatic Authorization header
/// injection, safe default timeouts, and optional in-memory caching.
class ApiClient {
  ApiClient._();

  static final http.Client _client = http.Client();
  static final Map<String, _CacheEntry> _memoryCache = {};

  static http.Client get rawClient => _client;

  static Future<Map<String, String>> _prepareHeaders(
    Map<String, String>? headers,
  ) async {
    final finalHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };
    if (!finalHeaders.containsKey('Authorization')) {
      final token = await AuthSession.accessToken();
      if (token != null && token.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
      }
    }
    return finalHeaders;
  }

  /// Sends a GET request with connection pooling and standard timeout.
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final prepared = await _prepareHeaders(headers);
    return _client.get(uri, headers: prepared).timeout(timeout);
  }

  /// Cached GET request. Returns fresh cached data if available (TTL default 45s).
  /// If [forceRefresh] is true, ignores cache and updates it on success.
  static Future<Map<String, dynamic>> getJsonCached(
    Uri uri, {
    Duration ttl = const Duration(seconds: 45),
    bool forceRefresh = false,
  }) async {
    final key = uri.toString();
    if (!forceRefresh) {
      final cached = _memoryCache[key];
      if (cached != null && cached.isFresh(ttl) && cached.data is Map) {
        return Map<String, dynamic>.from(cached.data as Map);
      }
    }

    final response = await get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final result = Map<String, dynamic>.from(decoded);
        _memoryCache[key] = _CacheEntry(result);
        return result;
      }
    }
    throw Exception('Request to $uri failed with status ${response.statusCode}');
  }

  /// Clears in-memory API cache (e.g., on logout or manual refresh).
  static void clearCache() {
    _memoryCache.clear();
  }

  /// Sends a POST request with connection pooling.
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final prepared = await _prepareHeaders({
      'Content-Type': 'application/json',
      ...?headers,
    });
    final payload = body is String ? body : (body != null ? jsonEncode(body) : null);
    return _client.post(uri, headers: prepared, body: payload).timeout(timeout);
  }

  /// Sends a PATCH request with connection pooling.
  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final prepared = await _prepareHeaders({
      'Content-Type': 'application/json',
      ...?headers,
    });
    final payload = body is String ? body : (body != null ? jsonEncode(body) : null);
    return _client.patch(uri, headers: prepared, body: payload).timeout(timeout);
  }

  /// Sends a PUT request with connection pooling.
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final prepared = await _prepareHeaders({
      'Content-Type': 'application/json',
      ...?headers,
    });
    final payload = body is String ? body : (body != null ? jsonEncode(body) : null);
    return _client.put(uri, headers: prepared, body: payload).timeout(timeout);
  }

  /// Sends a DELETE request with connection pooling.
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final prepared = await _prepareHeaders(headers);
    final payload = body is String ? body : (body != null ? jsonEncode(body) : null);
    return _client.delete(uri, headers: prepared, body: payload).timeout(timeout);
  }

  /// Sends a multipart request using connection pooling.
  static Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final token = await AuthSession.accessToken();
    if (token != null && token.isNotEmpty && !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _client.send(request).timeout(timeout);
  }
}
