import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'md_models.dart';

class MdService {
  final String role;

  const MdService({this.role = 'md'});

  String get _baseUrl =>
      '${ApiConfig.baseUrl}/${role == 'director' ? 'director' : 'md'}';

  Future<MdDashboardData> fetchDashboard(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/?user_id=$userId'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return MdDashboardData.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }
    throw Exception(
      'MD dashboard API failed with status ${response.statusCode}',
    );
  }

  Future<MdMeeting> scheduleMeeting(MdMeeting meeting, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({...meeting.toJson(), 'created_by': userId}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final meetingJson = data['meeting'];
      return MdMeeting.fromJson(
        Map<String, dynamic>.from((meetingJson is Map ? meetingJson : data)),
      );
    }
    throw Exception('MD meeting API failed with status ${response.statusCode}');
  }
}
