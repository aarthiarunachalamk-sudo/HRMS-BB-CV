import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'client_visit_models.dart';

class ClientDetailsApiUnavailableException implements Exception {
  const ClientDetailsApiUnavailableException();

  @override
  String toString() =>
      'Client Details server update is pending. Your details will be saved on this device and synced automatically.';
}

class ClientVisitService {
  // A mobile connection should not leave a screen blocked for over a minute.
  // Thirty seconds still covers Render's normal cold-start window, while the
  // single retry handles a transient gateway response without compounding it.
  static const _requestTimeout = Duration(seconds: 30);
  static const _retryDelay = Duration(seconds: 2);
  static final http.Client _client = ApiClient.rawClient;

  static final Uri _base = ApiConfig.uri('/client-visits/');

  static Uri get _clientDetailsUri =>
      ApiConfig.uri('/client-visits/client-details/');

  Future<http.Response> _getWithRenderRetry(Uri uri) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .get(uri)
            .timeout(_requestTimeout);
        if (!{502, 503, 504}.contains(response.statusCode) || attempt == 1) {
          return response;
        }
        lastError = Exception('Server returned ${response.statusCode}.');
      } catch (error) {
        lastError = error;
        if (attempt == 1) rethrow;
      }
      await Future<void>.delayed(_retryDelay);
    }
    throw Exception('Client Visit server is unavailable: $lastError');
  }

  Future<List<Map<String, dynamic>>> fetchVisitApprovers(
    String userId, {
    bool requiresRoleAwareApprovers = false,
  }) async {
    var response = await _client
        .get(
          ApiConfig.uri(
            '/client-visits/approvers/',
          ).replace(queryParameters: {'user_id': userId}),
        )
        .timeout(const Duration(seconds: 20));
    var responseKey = 'approvers';
    // Backward compatibility while an older Render release is still active.
    // The new endpoint includes HR; the legacy endpoint contains TLs only.
    if (response.statusCode == 404) {
      if (requiresRoleAwareApprovers) {
        throw Exception(
          'The server update for role-based approvers is not deployed yet. Please deploy the latest backend and retry.',
        );
      }
      response = await _client
          .get(ApiConfig.uri('/hr/reporting-tls/'))
          .timeout(const Duration(seconds: 20));
      responseKey = 'tls';
    }
    final body = _body(response);
    return (body[responseKey] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final value = Map<String, dynamic>.from(item);
          value.putIfAbsent('role', () => 'tl');
          value.putIfAbsent('role_label', () => 'Team Lead');
          return value;
        })
        .where((item) => '${item['employee_id'] ?? ''}'.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> saveClientDetails(
    String userId, {
    required String clientName,
    required String clientEmail,
    required String clientMobile,
    required String clientGst,
    required String clientAddress,
    required String clientDetails,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            _clientDetailsUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'client_name': clientName,
              'client_email': clientEmail,
              'client_mobile': clientMobile,
              'client_gst': clientGst,
              'client_address': clientAddress,
              'client_details': clientDetails,
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const ClientDetailsApiUnavailableException();
    } on http.ClientException {
      throw const ClientDetailsApiUnavailableException();
    }
    if (response.statusCode == 404 ||
        {502, 503, 504}.contains(response.statusCode)) {
      throw const ClientDetailsApiUnavailableException();
    }
    return Map<String, dynamic>.from(_body(response)['client_detail'] as Map);
  }

  Future<List<Map<String, dynamic>>> fetchClientDetails(String userId) async {
    final response = await _getWithRenderRetry(
      _clientDetailsUri.replace(queryParameters: {'user_id': userId}),
    );
    return (_body(response)['client_details'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static final Map<int, String> _localRequirementStatuses = {};
  static bool _prefsLoaded = false;

  static Future<void> _ensurePrefsLoaded() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('saved_requirement_statuses');
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          decoded.forEach((key, val) {
            final id = int.tryParse('$key');
            if (id != null && val is String && val.isNotEmpty) {
              _localRequirementStatuses[id] = val;
            }
          });
        }
      }
      _prefsLoaded = true;
    } catch (_) {}
  }

  static Future<void> _persistRequirementStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _localRequirementStatuses.map((k, v) => MapEntry('$k', v));
      await prefs.setString('saved_requirement_statuses', jsonEncode(mapToSave));
    } catch (_) {}
  }

  static final List<ClientVisit> _locallyCreatedVisits = [];

  static void registerLocallyCreatedVisit(ClientVisit visit) {
    _locallyCreatedVisits.removeWhere(
      (v) => v.id == visit.id || (v.visitId.isNotEmpty && v.visitId == visit.visitId),
    );
    _locallyCreatedVisits.insert(0, visit);
  }

  Future<ClientVisitListResult> fetchVisits(
    String userId, {
    String status = '',
    String requirementStatus = '',
  }) async {
    await _ensurePrefsLoaded();
    final response = await _getWithRenderRetry(
      _base.replace(
        queryParameters: {
          'user_id': userId,
          if (status.isNotEmpty) 'status': status,
          if (requirementStatus.isNotEmpty)
            'requirement_status': requirementStatus,
        },
      ),
    );
    final body = _body(response);
    final visits = (body['visits'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final v = ClientVisit.fromJson(Map<String, dynamic>.from(item));
          final localReq = _localRequirementStatuses[v.id];
          if (localReq != null && localReq.isNotEmpty) {
            return v.copyWith(requirementStatus: localReq);
          }
          return v;
        })
        .toList();

    // Ensure recently submitted visits are included immediately
    for (final lv in _locallyCreatedVisits) {
      if (!visits.any((v) => v.id == lv.id || (v.visitId.isNotEmpty && v.visitId == lv.visitId))) {
        visits.insert(0, lv);
      }
    }

    final summary = <String, int>{};
    (body['summary'] as Map? ?? const {}).forEach((key, value) {
      summary['$key'] = int.tryParse('$value') ?? 0;
    });
    return ClientVisitListResult(visits, summary);
  }

  Future<ClientVisit> fetchVisit(String userId, int id) async {
    await _ensurePrefsLoaded();
    final response = await _getWithRenderRetry(
      Uri.parse('$_base$id/').replace(queryParameters: {'user_id': userId}),
    );
    final v = ClientVisit.fromJson(
      Map<String, dynamic>.from(_body(response)['visit'] as Map),
    );
    final localReq = _localRequirementStatuses[v.id];
    if (localReq != null && localReq.isNotEmpty) {
      return v.copyWith(requirementStatus: localReq);
    }
    return v;
  }

  Future<ClientVisit> create(String userId, Map<String, dynamic> fields) async {
    final response = await _client.post(
      _base,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, ...fields}),
    ).timeout(_requestTimeout);
    final v = ClientVisit.fromJson(
      Map<String, dynamic>.from(_body(response)['visit'] as Map),
    );
    final reqStatus = '${fields['requirement_status'] ?? fields['client_status'] ?? ''}'.trim();
    final finalVisit = reqStatus.isNotEmpty
        ? v.copyWith(requirementStatus: reqStatus)
        : v;
    if (reqStatus.isNotEmpty) {
      _localRequirementStatuses[v.id] = reqStatus;
      await _persistRequirementStatuses();
    }
    registerLocallyCreatedVisit(finalVisit);
    return finalVisit;
  }

  Future<ClientVisit> updateRequirementStatus(
    String userId,
    int id,
    String requirementStatus, {
    ClientVisit? fallbackVisit,
  }) async {
    _localRequirementStatuses[id] = requirementStatus;
    await _persistRequirementStatuses();
    try {
      final response = await _client.post(
        Uri.parse('$_base$id/requirement-status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'requirement_status': requirementStatus,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _body(response);
        if (body['visit'] is Map) {
          final updated = ClientVisit.fromJson(
            Map<String, dynamic>.from(body['visit'] as Map),
          );
          _localRequirementStatuses[id] = requirementStatus;
          await _persistRequirementStatuses();
          return updated.copyWith(requirementStatus: requirementStatus);
        }
      }
    } catch (_) {
      // Local fallback handles 404 or transient network offline seamlessly
    }
    if (fallbackVisit != null) {
      return fallbackVisit.copyWith(requirementStatus: requirementStatus);
    }
    try {
      final v = await fetchVisit(userId, id);
      return v.copyWith(requirementStatus: requirementStatus);
    } catch (_) {
      return fallbackVisit ?? (throw Exception('Unable to update requirement status'));
    }
  }

  Future<ClientVisit> action(
    String userId,
    int id,
    String action,
    Map<String, dynamic> fields,
  ) async {
    final response = await _client.post(
      Uri.parse('$_base$id/$action/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, ...fields}),
    ).timeout(_requestTimeout);
    return ClientVisit.fromJson(
      Map<String, dynamic>.from(_body(response)['visit'] as Map),
    );
  }

  Future<void> addExpense(
    String userId,
    int id,
    String category,
    double amount,
    String note,
  ) async {
    final response = await http.post(
      Uri.parse('$_base$id/expenses/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'category': category,
        'amount': amount,
        'note': note,
      }),
    );
    _body(response);
  }

  Future<void> trackLocation(
    String userId,
    int id, {
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
  }) async {
    final response = await http.post(
      Uri.parse('$_base$id/location/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
      }),
    );
    _body(response);
  }

  Future<String> createTrackingLink(
    String userId,
    int id, {
    double? destinationLatitude,
    double? destinationLongitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base$id/tracking-link/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'destination_latitude': destinationLatitude,
            'destination_longitude': destinationLongitude,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final url = '${_body(response)['tracking_url'] ?? ''}'.trim();
    if (url.isEmpty) {
      throw Exception('The server did not return a live tracking link.');
    }
    return url;
  }

  Future<void> uploadFiles(
    String userId,
    int id,
    String category,
    List<String> paths, {
    String fallbackCategory = '',
  }) async {
    try {
      await _uploadFiles(userId, id, category, paths);
    } catch (error) {
      final message = '$error'.toLowerCase();
      if (fallbackCategory.isEmpty ||
          !message.contains('invalid attachment category')) {
        rethrow;
      }
      await _uploadFiles(userId, id, fallbackCategory, paths);
    }
  }

  Future<void> _uploadFiles(
    String userId,
    int id,
    String category,
    List<String> paths,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base$id/attachments/'),
    );
    request.fields.addAll({'user_id': userId, 'category': category});
    const selfieCategories = {
      'check_in',
      'office_checkout',
      'client_check_in',
      'checkout',
    };
    for (final path in paths) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          path,
          filename: selfieCategories.contains(category)
              ? 'client_visit_selfie_${DateTime.now().microsecondsSinceEpoch}.jpg'
              : null,
          contentType: selfieCategories.contains(category)
              ? MediaType('image', 'jpeg')
              : null,
        ),
      );
    }
    _body(await http.Response.fromStream(await request.send()));
  }

  Map<String, dynamic> _body(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false)
          .firstMatch(response.body);
      final rawTitle = titleMatch
          ?.group(1)
          ?.replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final pageTitle =
          rawTitle != null && !rawTitle.toLowerCase().contains('server error')
              ? rawTitle
              : null;
      if (response.statusCode >= 500) {
        throw Exception(
          pageTitle != null
              ? 'Client Visit server error (${response.statusCode}): $pageTitle. Please try again.'
              : 'Client Visit server error (${response.statusCode}). Please try again.',
        );
      }
      throw Exception(
        'Unexpected Client Visit response (${response.statusCode}). Please try again.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('${body['message'] ?? 'Client visit request failed.'}');
    }
    return body;
  }
}
