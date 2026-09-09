import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Overlap backend startup with the splash screen and credential entry.
class LoginWarmup {
  static Future<void>? _pending;
  static DateTime? _lastSuccess;

  static Future<void> start() {
    if (_pending != null) return _pending!;
    final lastSuccess = _lastSuccess;
    if (lastSuccess != null &&
        DateTime.now().difference(lastSuccess) < const Duration(minutes: 1)) {
      return Future<void>.value();
    }
    return _pending = _run().whenComplete(() => _pending = null);
  }

  static Future<void> _run() async {
    final client = http.Client();
    try {
      final urls = [
        ApiConfig.uri('/health/'),
        if (ApiConfig.usesPrivateNetworkAddress)
          ApiConfig.publicUri('/health/'),
      ];
      for (final url in urls) {
        try {
          final response = await client
              .get(url)
              .timeout(
                Duration(
                  seconds:
                      ApiConfig.usesPrivateNetworkAddress && url == urls.first
                      ? 1
                      : 65,
                ),
              );
          if (response.statusCode == 200) {
            _lastSuccess = DateTime.now();
            return;
          }
        } catch (_) {
          // Best effort: the login request reports actual connection failures.
        }
      }
    } finally {
      client.close();
    }
  }
}
