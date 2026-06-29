import 'dart:convert';

import 'package:http/http.dart' as http;

class TlService {
  static const String baseUrl = 'http://192.168.1.56:8000/api/tl';

  Future<Map<String, dynamic>> fetchDashboard(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/?user_id=$userId'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception('TL API failed with status ${response.statusCode}');
  }

  Future<void> scheduleMeeting(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Schedule meeting failed with status ${response.statusCode}');
    }
  }
}
