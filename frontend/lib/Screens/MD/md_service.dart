import 'dart:convert';

import 'package:hrms_mobileapp_bitbyte/backend/api_client.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'md_models.dart';

class MdService {
  final String role;

  const MdService({this.role = 'md'});

  String get _baseUrl =>
      '${ApiConfig.baseUrl}/${role == 'director' ? 'director' : 'md'}';

  Future<MdDashboardData> fetchDashboard(String userId, {bool forceRefresh = false}) async {
    final uri = Uri.parse('$_baseUrl/dashboard/?user_id=$userId');
    try {
      final json = await ApiClient.getJsonCached(
        uri,
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );
      return MdDashboardData.fromJson(json);
    } catch (_) {
      final response = await ApiClient.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return MdDashboardData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }
      throw Exception(
        'MD dashboard API failed with status ${response.statusCode}',
      );
    }
  }

  Future<MdMeeting> scheduleMeeting(MdMeeting meeting, String userId) async {
    final response = await ApiClient.post(
      Uri.parse('$_baseUrl/meetings/'),
      body: {...meeting.toJson(), 'created_by': userId},
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
