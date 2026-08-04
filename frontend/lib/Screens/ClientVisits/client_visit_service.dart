import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'client_visit_models.dart';

class ClientVisitService {
  static final Uri _base = ApiConfig.uri('/client-visits/');

  Future<ClientVisitListResult> fetchVisits(
    String userId, {
    String status = '',
  }) async {
    final response = await http
        .get(
          _base.replace(
            queryParameters: {
              'user_id': userId,
              if (status.isNotEmpty) 'status': status,
            },
          ),
        )
        .timeout(const Duration(seconds: 20));
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
    final response = await http.get(
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

  Future<void> uploadFiles(
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
    for (final path in paths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    _body(await http.Response.fromStream(await request.send()));
  }

  Map<String, dynamic> _body(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw Exception('The client visit server returned invalid data.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('${body['message'] ?? 'Client visit request failed.'}');
    }
    return body;
  }
}
