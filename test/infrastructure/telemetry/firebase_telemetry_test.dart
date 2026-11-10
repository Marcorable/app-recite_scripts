import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/infrastructure/telemetry/firebase_telemetry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
  });

  test('collection을 활성화하고 일반 실행에서는 검증 데이터를 만들지 않는다', () async {
    final analytics = _FakeAnalyticsTelemetry();
    final crash = _FakeCrashTelemetry();

    await initializeFirebaseTelemetry(
      analytics: analytics,
      crashTelemetry: crash,
      debugVerification: false,
    );

    expect(analytics.collectionEnabled, isTrue);
    expect(crash.collectionEnabled, isTrue);
    expect(analytics.debugVerificationCount, 0);
    expect(crash.debugVerificationCount, 0);
  });

  test('Debug 검증이 켜지면 안전한 검증 데이터를 한 번 기록한다', () async {
    final analytics = _FakeAnalyticsTelemetry();
    final crash = _FakeCrashTelemetry();

    await initializeFirebaseTelemetry(
      analytics: analytics,
      crashTelemetry: crash,
      debugVerification: true,
    );

    expect(analytics.debugVerificationCount, 1);
    expect(crash.debugVerificationCount, 1);
  });
}

final class _FakeAnalyticsTelemetry implements AnalyticsTelemetry {
  bool? collectionEnabled;
  int debugVerificationCount = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> logDebugVerification() async {
    debugVerificationCount += 1;
  }
}

final class _FakeCrashTelemetry implements CrashTelemetry {
  bool? collectionEnabled;
  int debugVerificationCount = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> recordDebugVerification() async {
    debugVerificationCount += 1;
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {}

  @override
  Future<void> recordFatalError(Object error, StackTrace stackTrace) async {}
}
