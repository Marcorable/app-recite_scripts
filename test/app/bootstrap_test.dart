import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/app/bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Firebase 초기화가 완료된 뒤 앱을 실행한다', () async {
    final initialization = Completer<void>();
    Widget? startedApp;

    final bootstrapFuture = bootstrap(
      initializeFirebase: () => initialization.future,
      runApplication: (app) => startedApp = app,
    );

    expect(startedApp, isNull);

    initialization.complete();
    await bootstrapFuture;

    expect(startedApp, isNotNull);
  });
}
