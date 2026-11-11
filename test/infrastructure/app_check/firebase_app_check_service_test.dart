import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/infrastructure/app_check/firebase_app_check_service.dart';

void main() {
  test('Debug 빌드는 양 플랫폼의 debug provider를 사용한다', () async {
    final client = _FakeAppCheckClient();

    await initializeFirebaseAppCheck(appCheck: client, debugMode: true);

    expect(client.androidProvider, isA<AndroidDebugProvider>());
    expect(client.appleProvider, isA<AppleDebugProvider>());
  });

  test('Release 빌드는 Play Integrity와 App Attest를 사용한다', () async {
    final client = _FakeAppCheckClient();

    await initializeFirebaseAppCheck(appCheck: client, debugMode: false);

    expect(client.androidProvider, isA<AndroidPlayIntegrityProvider>());
    expect(client.appleProvider, isA<AppleAppAttestProvider>());
  });

  test('App Check 활성화 실패가 앱 시작을 막지 않는다', () async {
    final client = _FakeAppCheckClient(error: StateError('activation failed'));

    await expectLater(initializeFirebaseAppCheck(appCheck: client), completes);
  });

  test('명시한 Debug 검증에서 토큰을 강제 갱신한다', () async {
    final client = _FakeAppCheckClient(token: 'registered-debug-token');

    await initializeFirebaseAppCheck(
      appCheck: client,
      debugMode: true,
      debugVerification: true,
    );

    expect(client.forceRefresh, isTrue);
  });

  test('Debug 토큰 검증 실패가 앱 시작을 막지 않는다', () async {
    final client = _FakeAppCheckClient(tokenError: StateError('token failed'));

    await expectLater(
      initializeFirebaseAppCheck(
        appCheck: client,
        debugMode: true,
        debugVerification: true,
      ),
      completes,
    );
  });
}

final class _FakeAppCheckClient implements AppCheckClient {
  _FakeAppCheckClient({this.error, this.token, this.tokenError});

  final Object? error;
  final String? token;
  final Object? tokenError;
  AndroidAppCheckProvider? androidProvider;
  AppleAppCheckProvider? appleProvider;
  bool? forceRefresh;

  @override
  Future<void> activate({
    required AndroidAppCheckProvider providerAndroid,
    required AppleAppCheckProvider providerApple,
  }) async {
    androidProvider = providerAndroid;
    appleProvider = providerApple;
    if (error case final activationError?) {
      throw activationError;
    }
  }

  @override
  Future<String?> getToken({required bool forceRefresh}) async {
    this.forceRefresh = forceRefresh;
    if (tokenError case final getTokenError?) {
      throw getTokenError;
    }
    return token;
  }
}
