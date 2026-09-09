import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  AuthSession._();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'api_access_token';
  static const _refreshKey = 'api_refresh_token';
  static bool _hasSession = false;
  static String? _accessToken;
  static String? _refreshToken;
  static Future<void> _pendingWrite = Future<void>.value();

  // Serialize persistence so a refresh or logout cannot be overwritten by an
  // older login write that finishes later.
  static Future<void> _persist(Future<void> Function() operation) {
    final write = _pendingWrite.then((_) => operation());
    _pendingWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return write;
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _hasSession = true;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    return _persist(() async {
      await Future.wait([
        _storage.write(key: _accessKey, value: accessToken),
        _storage.write(key: _refreshKey, value: refreshToken),
      ]);
    });
  }

  static Future<String?> accessToken() =>
      _hasSession ? Future.value(_accessToken) : _storage.read(key: _accessKey);
  static Future<String?> refreshToken() => _hasSession
      ? Future.value(_refreshToken)
      : _storage.read(key: _refreshKey);

  static Future<void> clear() {
    _hasSession = true;
    _accessToken = null;
    _refreshToken = null;
    return _persist(() async {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]);
    });
  }
}
