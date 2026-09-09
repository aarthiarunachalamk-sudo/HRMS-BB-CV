import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/backend/auth_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await AuthSession.clear();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('tokens are usable while secure storage is still writing', () async {
    final blocked = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'write') await blocked.future;
      return null;
    });
    final saved = AuthSession.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    expect(await AuthSession.accessToken(), 'access');
    expect(await AuthSession.refreshToken(), 'refresh');
    blocked.complete();
    await saved;
  });

  test(
    'clear waits for older writes and immediately hides cached tokens',
    () async {
      final blocked = Completer<void>();
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'write') await blocked.future;
        return null;
      });
      final saved = AuthSession.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      await Future<void>.delayed(Duration.zero);
      final cleared = AuthSession.clear();
      expect(await AuthSession.accessToken(), isNull);
      expect(calls, ['write', 'write']);
      blocked.complete();
      await Future.wait([saved, cleared]);
      expect(calls, ['write', 'write', 'delete', 'delete']);
    },
  );
}
