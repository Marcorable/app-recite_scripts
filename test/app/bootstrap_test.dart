import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/app/bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Firebase, App Check와 telemetry 초기화가 완료된 뒤 앱을 실행한다', () async {
    final firebaseInitialization = Completer<void>();
    final appCheckInitialization = Completer<void>();
    final telemetryInitialization = Completer<void>();
    Widget? startedApp;

    final bootstrapFuture = bootstrap(
      initializeFirebase: () => firebaseInitialization.future,
      initializeAppCheck: () => appCheckInitialization.future,
      initializeTelemetry: () => telemetryInitialization.future,
      runApplication: (app) => startedApp = app,
    );

    expect(startedApp, isNull);

    firebaseInitialization.complete();
    await Future<void>.delayed(Duration.zero);
    expect(startedApp, isNull);

    appCheckInitialization.complete();
    await Future<void>.delayed(Duration.zero);
    expect(startedApp, isNull);

    telemetryInitialization.complete();
    await bootstrapFuture;

    expect(startedApp, isNotNull);
  });
}
