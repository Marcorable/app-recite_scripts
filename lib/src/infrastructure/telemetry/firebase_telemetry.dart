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
    unawaited(_recordFlutterFatalError(details));
  }

  Future<void> _recordFlutterFatalError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordError(
        StateError('flutter_fatal_error'),
        details.stack ?? StackTrace.current,
        reason: details.exception.runtimeType.toString(),
        fatal: true,
      );
    } catch (error, stackTrace) {
      _debugTelemetryFailure(
        'Crashlytics Flutter error recording',
        error,
        stackTrace,
      );
    }
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

  final analyticsReady = await _enableTelemetryCollection(
    'Analytics collection setup',
    () => analyticsTelemetry.setCollectionEnabled(true),
  );
  final crashlyticsReady = await _enableTelemetryCollection(
    'Crashlytics collection setup',
    () => crashReporter.setCollectionEnabled(true),
  );

  if (crashlyticsReady) {
    FlutterError.onError = (details) {
      _debugTelemetryFailure(
        'Flutter fatal error',
        details.exception,
        details.stack ?? StackTrace.current,
      );
      crashReporter.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _debugTelemetryFailure('Unhandled async error', error, stackTrace);
      unawaited(_recordFatalErrorSafely(crashReporter, error, stackTrace));
      return true;
    };
  }

  if (!kDebugMode || !debugVerification) {
    return;
  }

  if (analyticsReady) {
    await _runTelemetryOperation(
      'Analytics debug verification',
      analyticsTelemetry.logDebugVerification,
    );
  }
  if (crashlyticsReady) {
    await _runTelemetryOperation(
      'Crashlytics debug verification',
      crashReporter.recordDebugVerification,
    );
  }
}

Future<bool> _enableTelemetryCollection(
  String operation,
  Future<void> Function() enable,
) async {
  try {
    await enable();
    return true;
  } catch (error, stackTrace) {
    _debugTelemetryFailure(operation, error, stackTrace);
    return false;
  }
}

Future<void> _runTelemetryOperation(
  String operation,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    _debugTelemetryFailure(operation, error, stackTrace);
  }
}

Future<void> _recordFatalErrorSafely(
  CrashTelemetry crashReporter,
  Object error,
  StackTrace stackTrace,
) async {
  try {
    await crashReporter.recordFatalError(error, stackTrace);
  } catch (recordingError, recordingStackTrace) {
    _debugTelemetryFailure(
      'Crashlytics async error recording',
      recordingError,
      recordingStackTrace,
    );
  }
}

void _debugTelemetryFailure(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('$operation failed (${error.runtimeType}).');
  debugPrintStack(stackTrace: stackTrace);
}
