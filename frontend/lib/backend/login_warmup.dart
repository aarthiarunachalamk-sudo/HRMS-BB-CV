import 'dart:async';

import 'api_client.dart';
import 'api_config.dart';

/// Overlap backend startup with the splash screen and credential entry.
class LoginWarmup {
  static Future<void>? _pending;
  static DateTime? _lastSuccess;

  static bool get isWarmedUp =>
      _lastSuccess != null &&
      DateTime.now().difference(_lastSuccess!) < const Duration(minutes: 5);

  static Future<void> start() {
    if (_pending != null) return _pending!;
    final lastSuccess = _lastSuccess;
    if (lastSuccess != null &&
        DateTime.now().difference(lastSuccess) < const Duration(minutes: 5)) {
      return Future<void>.value();
    }
    return _pending = _run().whenComplete(() => _pending = null);
  }

  static Future<void> _run() async {
    final client = ApiClient.rawClient;
    try {
      final urls = [
        ApiConfig.uri('/health/'),
        if (ApiConfig.usesPrivateNetworkAddress)
          ApiConfig.publicUri('/health/'),
      ];
      for (final url in urls) {
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final response = await client
                .get(url)
                .timeout(
                  Duration(
                    seconds:
                        ApiConfig.usesPrivateNetworkAddress && url == urls.first
                        ? 2
                        : 70,
                  ),
                );
            if (response.statusCode == 200) {
              _lastSuccess = DateTime.now();
              return;
            }
            if (response.statusCode >= 500 && attempt == 0) {
              await Future<void>.delayed(const Duration(seconds: 3));
              continue;
            }
          } catch (_) {
            if (attempt == 0) {
              await Future<void>.delayed(const Duration(seconds: 2));
              continue;
            }
          }
        }
      }
    } finally {
      // Keep persistent socket pool alive for immediate login request!
    }
  }
}
