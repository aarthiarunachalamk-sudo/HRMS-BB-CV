import 'dart:convert';

import 'package:http/http.dart' as http;

class SaService {
  static const String baseUrl = 'http://192.168.1.56:8000/api/superadmin';

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Superadmin API failed with status ${response.statusCode}');
  }
}
