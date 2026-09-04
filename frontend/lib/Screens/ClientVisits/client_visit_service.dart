import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'client_visit_models.dart';

class ClientVisitService {
  static final Uri _base = ApiConfig.uri('/client-visits/');

  static Uri get _clientDetailsUri =>
      ApiConfig.uri('/client-visits/client-details/');

  Future<http.Response> _getWithRenderRetry(Uri uri) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 65));
        if (!{502, 503, 504}.contains(response.statusCode) || attempt == 2) {
          return response;
        }
        lastError = Exception('Server returned ${response.statusCode}.');
      } catch (error) {
        lastError = error;
        if (attempt == 2) rethrow;
      }
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    throw Exception('Client Visit server is unavailable: $lastError');
  }

  Future<List<Map<String, dynamic>>> fetchVisitApprovers(
    String userId, {
    bool requiresRoleAwareApprovers = false,
  }) async {
    var response = await http
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
      response = await http
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
    required String clientDetails,
  }) async {
    final response = await http
        .post(
          _clientDetailsUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'client_name': clientName,
            'client_email': clientEmail,
            'client_mobile': clientMobile,
            'client_details': clientDetails,
          }),
        )
        .timeout(const Duration(seconds: 65));
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

  Future<ClientVisitListResult> fetchVisits(
    String userId, {
    String status = '',
  }) async {
    final response = await _getWithRenderRetry(
      _base.replace(
        queryParameters: {
          'user_id': userId,
          if (status.isNotEmpty) 'status': status,
        },
      ),
    );
    final body = _body(response);
    final visits = (body['visits'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ClientVisit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final summary = <String, int>{};
    (body['summary'] as Map? ?? const {}).forEach((key, value) {
      summary['$key'] = int.tryParse('$value') ?? 0;
    });
    return ClientVisitListResult(visits, summary);
  }

  Future<ClientVisit> fetchVisit(String userId, int id) async {
    final response = await _getWithRenderRetry(
      Uri.parse('$_base$id/').replace(queryParameters: {'user_id': userId}),
    );
    return ClientVisit.fromJson(
      Map<String, dynamic>.from(_body(response)['visit'] as Map),
    );
  }

  Future<ClientVisit> create(String userId, Map<String, dynamic> fields) async {
    final response = await http.post(
      _base,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, ...fields}),
    );
    return ClientVisit.fromJson(
      Map<String, dynamic>.from(_body(response)['visit'] as Map),
    );
  }

  Future<ClientVisit> action(
    String userId,
    int id,
    String action,
    Map<String, dynamic> fields,
  ) async {
    final response = await http.post(
      Uri.parse('$_base$id/$action/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, ...fields}),
    );
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
      if (response.statusCode >= 500) {
        throw Exception(
          'Client Visit server error (${response.statusCode}). Please try again.',
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
