import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

const _debugVerificationEnabled = bool.fromEnvironment(
  'FIREBASE_DEBUG_VERIFICATION',
);

abstract interface class AnalyticsTelemetry {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> logDebugVerification();
}

abstract interface class CrashTelemetry {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> recordDebugVerification();

  void recordFlutterFatalError(FlutterErrorDetails details);

  Future<void> recordFatalError(Object error, StackTrace stackTrace);
}

final class FirebaseAnalyticsTelemetry implements AnalyticsTelemetry {
  FirebaseAnalyticsTelemetry({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logDebugVerification() {
    return _analytics.logEvent(name: 'debug_verification');
  }
}

final class FirebaseCrashTelemetry implements CrashTelemetry {
  FirebaseCrashTelemetry({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> recordDebugVerification() {
    return _crashlytics.recordError(
      StateError('firebase_debug_verification'),
      StackTrace.current,
      reason: 'Synthetic non-fatal error for Debug collection verification',
      fatal: false,
    );
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    unawaited(
      _crashlytics.recordError(
        StateError('flutter_fatal_error'),
        details.stack ?? StackTrace.current,
        reason: details.exception.runtimeType.toString(),
        fatal: true,
      ),
    );
  }

  @override
  Future<void> recordFatalError(Object error, StackTrace stackTrace) {
    return _crashlytics.recordError(
      StateError('unhandled_async_error'),
      stackTrace,
      reason: error.runtimeType.toString(),
      fatal: true,
    );
  }
}

Future<void> initializeFirebaseTelemetry({
  AnalyticsTelemetry? analytics,
  CrashTelemetry? crashTelemetry,
  bool debugVerification = _debugVerificationEnabled,
}) async {
  final analyticsTelemetry = analytics ?? FirebaseAnalyticsTelemetry();
  final crashReporter = crashTelemetry ?? FirebaseCrashTelemetry();

  await analyticsTelemetry.setCollectionEnabled(true);
  await crashReporter.setCollectionEnabled(true);

  FlutterError.onError = crashReporter.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(crashReporter.recordFatalError(error, stackTrace));
    return true;
  };

  if (!kDebugMode || !debugVerification) {
    return;
  }

  await analyticsTelemetry.logDebugVerification();
  await crashReporter.recordDebugVerification();
}
