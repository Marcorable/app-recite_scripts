import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/infrastructure/telemetry/firebase_telemetry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;
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

  test('Analytics 초기화 실패가 Crashlytics 검증과 앱 시작을 막지 않는다', () async {
    final analytics = _FakeAnalyticsTelemetry(failCollectionSetup: true);
    final crash = _FakeCrashTelemetry();

    await initializeFirebaseTelemetry(
      analytics: analytics,
      crashTelemetry: crash,
      debugVerification: true,
    );

    expect(analytics.debugVerificationCount, 0);
    expect(crash.debugVerificationCount, 1);
  });

  test('Crashlytics 초기화 실패가 Analytics 검증과 앱 시작을 막지 않는다', () async {
    final analytics = _FakeAnalyticsTelemetry();
    final crash = _FakeCrashTelemetry(failCollectionSetup: true);

    await initializeFirebaseTelemetry(
      analytics: analytics,
      crashTelemetry: crash,
      debugVerification: true,
    );

    expect(analytics.debugVerificationCount, 1);
    expect(crash.debugVerificationCount, 0);
  });

  test('한 검증 채널의 실패가 다른 채널 검증을 막지 않는다', () async {
    final analytics = _FakeAnalyticsTelemetry(failDebugVerification: true);
    final crash = _FakeCrashTelemetry(failDebugVerification: true);

    await initializeFirebaseTelemetry(
      analytics: analytics,
      crashTelemetry: crash,
      debugVerification: true,
    );

    expect(analytics.debugVerificationCount, 1);
    expect(crash.debugVerificationCount, 1);
  });

  test('비동기 오류 기록 실패를 처리하고 플랫폼 오류는 처리된 것으로 반환한다', () async {
    final crash = _FakeCrashTelemetry(failFatalRecording: true);

    await initializeFirebaseTelemetry(
      analytics: _FakeAnalyticsTelemetry(),
      crashTelemetry: crash,
      debugVerification: false,
    );

    final handled = PlatformDispatcher.instance.onError!(
      StateError('user supplied message'),
      StackTrace.current,
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, isTrue);
    expect(crash.fatalRecordingCount, 1);
  });
}

final class _FakeAnalyticsTelemetry implements AnalyticsTelemetry {
  _FakeAnalyticsTelemetry({
    this.failCollectionSetup = false,
    this.failDebugVerification = false,
  });

  final bool failCollectionSetup;
  final bool failDebugVerification;
  bool? collectionEnabled;
  int debugVerificationCount = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (failCollectionSetup) {
      throw StateError('analytics setup failed');
    }
    collectionEnabled = enabled;
  }

  @override
  Future<void> logDebugVerification() async {
    debugVerificationCount += 1;
    if (failDebugVerification) {
      throw StateError('analytics verification failed');
    }
  }
}

final class _FakeCrashTelemetry implements CrashTelemetry {
  _FakeCrashTelemetry({
    this.failCollectionSetup = false,
    this.failDebugVerification = false,
    this.failFatalRecording = false,
  });

  final bool failCollectionSetup;
  final bool failDebugVerification;
  final bool failFatalRecording;
  bool? collectionEnabled;
  int debugVerificationCount = 0;
  int fatalRecordingCount = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (failCollectionSetup) {
      throw StateError('crash setup failed');
    }
    collectionEnabled = enabled;
  }

  @override
  Future<void> recordDebugVerification() async {
    debugVerificationCount += 1;
    if (failDebugVerification) {
      throw StateError('crash verification failed');
    }
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {}

  @override
  Future<void> recordFatalError(Object error, StackTrace stackTrace) async {
    fatalRecordingCount += 1;
    if (failFatalRecording) {
      throw StateError('crash recording failed');
    }
  }
}
