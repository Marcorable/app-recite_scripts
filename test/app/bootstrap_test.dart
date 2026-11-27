import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/app/bootstrap.dart';
import 'package:maltto/src/app/startup_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('앱을 먼저 실행하고 Firebase, App Check, telemetry를 순서대로 초기화한다', () async {
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

    expect(startedApp, isA<StartupView>());

    firebaseInitialization.complete();
    await Future<void>.delayed(Duration.zero);
    expect(startedApp, isA<StartupView>());

    appCheckInitialization.complete();
    await Future<void>.delayed(Duration.zero);
    expect(startedApp, isA<StartupView>());

    telemetryInitialization.complete();
    await bootstrapFuture;

    expect(startedApp, isA<StartupView>());
  });
}
