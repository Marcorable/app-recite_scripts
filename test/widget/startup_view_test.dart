import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/app/startup_view.dart';

void main() {
  test('기본 선택 애니메이션 시간은 2초다', () {
    final view = StartupView(
      initialization: Future<void>.value(),
      appBuilder: () => const _ReadyApp(),
    );

    expect(view.duration, const Duration(seconds: 2));
  });

  testWidgets('초기화가 빨라도 선택 애니메이션을 끝낸 뒤 앱을 표시한다', (tester) async {
    await tester.pumpWidget(
      StartupView(
        initialization: Future<void>.value(),
        appBuilder: () => const _ReadyApp(),
        duration: const Duration(milliseconds: 100),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-logo')), findsOneWidget);
    expect(find.text('준비 완료'), findsNothing);

    await tester.pump(const Duration(milliseconds: 99));
    expect(find.byKey(const Key('startup-logo')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('준비 완료'), findsOneWidget);
  });

  testWidgets('2초 뒤에도 초기화 중이면 완료 상태를 유지한다', (tester) async {
    final initialization = Completer<void>();
    await tester.pumpWidget(
      StartupView(
        initialization: initialization.future,
        appBuilder: () => const _ReadyApp(),
        duration: const Duration(milliseconds: 100),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('startup-logo')), findsOneWidget);
    expect(find.text('준비 완료'), findsNothing);

    initialization.complete();
    await tester.pumpAndSettle();
    expect(find.text('준비 완료'), findsOneWidget);
  });

  testWidgets('동작 줄이기에서는 커서 이동 없이 준비된 앱을 표시한다', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);

    await tester.pumpWidget(
      StartupView(
        initialization: Future<void>.value(),
        appBuilder: () => const _ReadyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('준비 완료'), findsOneWidget);
  });

  testWidgets('지정한 256 논리 픽셀 크기로 로고를 표시한다', (tester) async {
    await tester.pumpWidget(
      StartupView(
        initialization: Completer<void>().future,
        appBuilder: () => const _ReadyApp(),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('startup-logo'))),
      const Size.square(256),
    );
  });
}

final class _ReadyApp extends StatelessWidget {
  const _ReadyApp();

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(home: Text('준비 완료'));
  }
}
