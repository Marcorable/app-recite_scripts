import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

const _debugVerificationEnabled = bool.fromEnvironment(
  'FIREBASE_APP_CHECK_DEBUG_VERIFICATION',
);
const _debugToken = String.fromEnvironment('FIREBASE_APP_CHECK_DEBUG_TOKEN');

abstract interface class AppCheckClient {
  Future<void> activate({
    required AndroidAppCheckProvider providerAndroid,
    required AppleAppCheckProvider providerApple,
  });

  Future<String?> getToken({required bool forceRefresh});
}

final class FirebaseAppCheckClient implements AppCheckClient {
  FirebaseAppCheckClient({FirebaseAppCheck? appCheck})
    : _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseAppCheck _appCheck;

  @override
  Future<void> activate({
    required AndroidAppCheckProvider providerAndroid,
    required AppleAppCheckProvider providerApple,
  }) {
    return _appCheck.activate(
      providerAndroid: providerAndroid,
      providerApple: providerApple,
    );
  }

  @override
  Future<String?> getToken({required bool forceRefresh}) {
    return _appCheck.getToken(forceRefresh);
  }
}

Future<void> initializeFirebaseAppCheck({
  AppCheckClient? appCheck,
  bool debugMode = kDebugMode,
  bool debugVerification = _debugVerificationEnabled,
}) async {
  final client = appCheck ?? FirebaseAppCheckClient();
  final androidProvider = debugMode
      ? AndroidDebugProvider(debugToken: _debugToken.nullIfEmpty)
      : const AndroidPlayIntegrityProvider();
  final appleProvider = debugMode
      ? AppleDebugProvider(debugToken: _debugToken.nullIfEmpty)
      : const AppleAppAttestProvider();

  final activated = await _runAppCheckOperation(
    'Firebase App Check activation',
    () => client.activate(
      providerAndroid: androidProvider,
      providerApple: appleProvider,
    ),
  );
  if (!activated || !debugMode || !debugVerification) {
    return;
  }

  await _runAppCheckOperation(
    'Firebase App Check debug verification',
    () async {
      final token = await client.getToken(forceRefresh: true);
      debugPrint(
        token == null
            ? 'Firebase App Check debug verification returned no token.'
            : 'Firebase App Check debug verification succeeded.',
      );
    },
  );
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

Future<bool> _runAppCheckOperation(
  String operation,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error, stackTrace) {
    if (!kDebugMode) {
      return false;
    }
    final errorCode = error is FirebaseException ? ', code: ${error.code}' : '';
    debugPrint('$operation failed (${error.runtimeType}$errorCode).');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
