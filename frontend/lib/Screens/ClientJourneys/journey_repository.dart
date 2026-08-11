import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../backend/api_config.dart';
import '../../backend/auth_session.dart';
import 'journey_location_queue.dart';
import 'journey_models.dart';

class JourneyRepository {
  JourneyRepository({http.Client? client, JourneyPointQueue? queue})
    : _client = client ?? http.Client(),
      queue = queue ?? SqliteJourneyPointQueue.instance;

  final http.Client _client;
  final JourneyPointQueue queue;

  Future<Map<String, String>> _headers() async {
    final token = await AuthSession.accessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Please sign in again to use journey tracking.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    bool retry = true,
  }) async {
    final request = http.Request(method, ApiConfig.uri(path));
    request.headers.addAll(await _headers());
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 && retry && await _refresh()) {
      return _send(method, path, body: body, retry: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decode(response);
      throw JourneyApiException(
        '${decoded['detail'] ?? decoded['message'] ?? 'Journey request failed.'}',
        response.statusCode,
      );
    }
    return response;
  }

  Future<bool> _refresh() async {
    final refresh = await AuthSession.refreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    final response = await _client.post(
      ApiConfig.uri('/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (response.statusCode != 200) return false;
    final access = '${_decode(response)['access'] ?? ''}';
    if (access.isEmpty) return false;
    await AuthSession.saveTokens(accessToken: access, refreshToken: refresh);
    return true;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  Future<List<ClientJourney>> list({
    bool team = false,
    bool history = false,
  }) async {
    final path = team
        ? '/team/client-journeys/${history ? 'history' : 'active'}/'
        : '/client-journeys/?page_size=100';
    final data = _decode(await _send('GET', path));
    final rows = data['results'] as List? ?? const [];
    return rows
        .map(
          (item) =>
              ClientJourney.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> assignees() async {
    final data = _decode(await _send('GET', '/client-journeys/assignees/'));
    return (data['results'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<ClientJourney> create(Map<String, dynamic> data) async =>
      ClientJourney.fromJson(
        _decode(await _send('POST', '/client-journeys/', body: data)),
      );

  Future<ClientJourney> action(
    int id,
    String action, {
    Map<String, dynamic>? body,
  }) async => ClientJourney.fromJson(
    _decode(
      await _send(
        'POST',
        '/client-journeys/$id/$action/',
        body: body ?? const {},
      ),
    ),
  );

  Future<ClientJourney?> activeForEmployee() async {
    final journeys = await list();
    for (final journey in journeys) {
      if (journey.isActive) return journey;
    }
    return null;
  }

  Future<JourneyLocationPoint?> latest(int id) async {
    final data = _decode(
      await _send('GET', '/client-journeys/$id/latest-location/'),
    );
    final point = data['location'];
    return point is Map
        ? JourneyLocationPoint.fromJson({
            ...Map<String, dynamic>.from(point),
            'journey_id': id,
          })
        : null;
  }

  Future<JourneyRoute> route(int id) async {
    final data = _decode(await _send('GET', '/client-journeys/$id/route/'));
    return JourneyRoute.fromJson(data);
  }

  Future<void> syncPending(int journeyId) async {
    while (true) {
      final pending = await queue.pending(journeyId);
      if (pending.isEmpty) return;
      final data = _decode(
        await _send(
          'POST',
          '/client-journeys/$journeyId/locations/batch/',
          body: {
            'points': pending.map((point) => point.toUploadJson()).toList(),
          },
        ),
      );
      final accepted = (data['accepted'] as List? ?? const []).map(
        (id) => '$id',
      );
      final duplicates = (data['duplicates'] as List? ?? const []).map(
        (id) => '$id',
      );
      await queue.acknowledge({...accepted, ...duplicates});
      final rejected = <String, String>{};
      for (final row in data['rejected'] as List? ?? const []) {
        final item = Map<String, dynamic>.from(row as Map);
        rejected['${item['client_generated_id']}'] = '${item['reason']}';
      }
      await queue.reject(rejected);
      if (accepted.isEmpty && duplicates.isEmpty) return;
    }
  }

  Future<WebSocketChannel> connect(int journeyId) async {
    final token = await AuthSession.accessToken();
    final base = Uri.parse(ApiConfig.baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/client-journeys/$journeyId/tracking/',
      queryParameters: {'token': token ?? ''},
    );
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    return channel;
  }
}

class JourneyRoute {
  final ClientJourney journey;
  final List<JourneyLocationPoint> points;
  final List<Map<String, dynamic>> stops;
  final List<Map<String, dynamic>> gaps;

  const JourneyRoute(this.journey, this.points, this.stops, this.gaps);

  factory JourneyRoute.fromJson(Map<String, dynamic> json) => JourneyRoute(
    ClientJourney.fromJson(Map<String, dynamic>.from(json['journey'] as Map)),
    (json['points'] as List? ?? const [])
        .map(
          (point) => JourneyLocationPoint.fromJson({
            ...Map<String, dynamic>.from(point as Map),
            'journey_id': (json['journey'] as Map)['id'],
          }),
        )
        .toList(growable: false),
    (json['stops'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false),
    (json['gaps'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false),
  );
}

class JourneyApiException implements Exception {
  final String message;
  final int statusCode;
  const JourneyApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
