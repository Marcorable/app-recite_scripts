import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/app/app.dart';
import 'package:maltto/src/features/scripts/data/script_repository.dart';
import 'package:maltto/src/features/scripts/model/script.dart';
import 'package:maltto/src/features/scripts/presentation/script_create_view_model.dart';
import 'package:maltto/src/features/scripts/presentation/script_list_view_model.dart';
import 'package:maltto/src/infrastructure/stt/stt_models.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';

void main() {
  testWidgets('시스템이 다크 모드여도 앱은 라이트 모드를 유지한다', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repository = _WidgetScriptRepository();

    await tester.pumpWidget(_buildApp(repository));
    await tester.pump();

    final context = tester.element(find.text('저장된 대본이 없습니다.'));
    expect(CupertinoTheme.of(context).brightness, Brightness.light);
    expect(
      CupertinoTheme.of(context).scaffoldBackgroundColor,
      AppColors.canvas,
    );
  });

  testWidgets('빈 상태에서 대본을 추가하고 목록에서 삭제한다', (tester) async {
    final repository = _WidgetScriptRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.pump();

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.text('저장된 대본이 없습니다.'), findsOneWidget);
    expect(find.text('대본 추가'), findsOneWidget);
    final emptyAddButton = find.ancestor(
      of: find.text('대본 추가'),
      matching: find.byType(CupertinoButton),
    );
    expect(
      tester.getSize(emptyAddButton.first).width,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(emptyAddButton.first).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('대본 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('script-title-field')),
      '발표 준비',
    );
    await tester.enterText(
      find.byKey(const Key('script-body-field')),
      '직접 작성한 문장을 천천히 읽습니다.',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('발표 준비'), findsOneWidget);
    expect(repository.scripts.single.body, '직접 작성한 문장을 천천히 읽습니다.');

    await tester.tap(find.byIcon(CupertinoIcons.delete));
    await tester.pumpAndSettle();
    expect(find.text('대본을 삭제할까요?'), findsOneWidget);
    expect(find.text('“발표 준비” 대본을 기기에서 삭제합니다.'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('저장된 대본이 없습니다.'), findsOneWidget);
    expect(repository.scripts, isEmpty);
  });

  testWidgets('대본 추가는 full-screen modal route로 열리고 취소로 닫힌다', (tester) async {
    final repository = _WidgetScriptRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('script-list-add-button')));
    await tester.pumpAndSettle();

    final route = ModalRoute.of(
      tester.element(find.byKey(const Key('script-title-field'))),
    );
    expect(route, isA<CupertinoPageRoute<void>>());
    expect((route! as CupertinoPageRoute<void>).fullscreenDialog, isTrue);

    await tester.tap(find.byKey(const Key('script-create-cancel-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('script-title-field')), findsNothing);
  });

  testWidgets('앱 정보에서 오픈소스 라이선스를 확인할 수 있다', (tester) async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        'test_package',
      ], 'Test package license.');
    });
    final repository = _WidgetScriptRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    final infoButton = find.byKey(const Key('script-list-info-button'));
    expect(infoButton, findsOneWidget);
    expect(tester.getSize(infoButton).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(infoButton).height, greaterThanOrEqualTo(48));

    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.text('오픈소스 라이선스'), findsOneWidget);
    expect(find.textContaining('공개 포트폴리오'), findsOneWidget);
    expect(find.text('test_package'), findsOneWidget);
  });

  testWidgets('권한 거부는 OS 요청을 반복하지 않고 앱 설정 안내를 표시한다', (tester) async {
    final script = _script(id: 1, title: '권한 확인 대본', body: '직접 작성한 문장을 읽습니다.');
    var prepareCalls = 0;
    var settingsCalls = 0;
    await tester.pumpWidget(
      MalttoApp(
        scriptListViewModel: ScriptListViewModel(
          _WidgetScriptRepository(initialScripts: [script]),
        ),
        createScriptViewModel: () =>
            ScriptCreateViewModel(_WidgetScriptRepository()),
        readingSetupBuilder: (_) => const SizedBox.shrink(),
        prepareReading: () async {
          prepareCalls++;
          return const SttPreparation(
            status: SttPreparationStatus.permissionDenied,
          );
        },
        openAppSettings: () async {
          settingsCalls++;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('권한 확인 대본'));
    await tester.pumpAndSettle();
    expect(find.text('마이크 접근이 필요해요'), findsOneWidget);
    expect(find.text('설정에서 마이크 접근을 허용한 뒤 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('permission-close-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('권한 확인 대본'));
    await tester.pumpAndSettle();
    expect(prepareCalls, 2);
    await tester.tap(find.byKey(const Key('permission-settings-button')));
    await tester.pumpAndSettle();
    expect(settingsCalls, 1);
  });

  testWidgets('권한 준비 예외는 안내하고 다음 선택에서 다시 시도할 수 있다', (tester) async {
    final repository = _WidgetScriptRepository(
      initialScripts: [
        _script(id: 1, title: '준비 확인 대본', body: '직접 작성한 문장을 읽습니다.'),
      ],
    );
    var prepareCalls = 0;
    await tester.pumpWidget(
      _buildAppWithReading(
        repository,
        prepareReading: () async {
          prepareCalls++;
          throw StateError('플랫폼 준비 실패');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('준비 확인 대본'));
    await tester.pumpAndSettle();
    expect(find.text('낭독을 준비할 수 없습니다'), findsOneWidget);
    expect(find.textContaining('준비하지 못했습니다'), findsOneWidget);
    expect(find.byKey(const Key('reading-setup-probe')), findsNothing);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('준비 확인 대본'));
    await tester.pumpAndSettle();
    expect(prepareCalls, 2);
  });

  testWidgets('빠른 연속 선택은 권한 준비와 setup sheet를 한 번만 연다', (tester) async {
    final preparation = Completer<SttPreparation>();
    final repository = _WidgetScriptRepository(
      initialScripts: [
        _script(id: 1, title: '연속 선택 대본', body: '직접 작성한 문장을 읽습니다.'),
      ],
    );
    var prepareCalls = 0;
    var setupBuilds = 0;
    await tester.pumpWidget(
      _buildAppWithReading(
        repository,
        prepareReading: () {
          prepareCalls++;
          return preparation.future;
        },
        readingSetupBuilder: (_) {
          setupBuilds++;
          return const ColoredBox(
            key: Key('reading-setup-probe'),
            color: CupertinoColors.white,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('연속 선택 대본'));
    await tester.tap(find.text('연속 선택 대본'));
    await tester.pump();
    expect(prepareCalls, 1);

    preparation.complete(
      const SttPreparation(status: SttPreparationStatus.ready),
    );
    await tester.pumpAndSettle();
    expect(setupBuilds, 1);
    expect(find.byKey(const Key('reading-setup-probe')), findsOneWidget);
  });

  testWidgets('지원 불가와 모델 준비 중은 안내 후 setup을 열지 않는다', (tester) async {
    for (final scenario in [
      (
        status: SttPreparationStatus.unsupported,
        message: '이 기기에서 온디바이스 한국어 음성 인식을 사용할 수 없습니다.',
      ),
      (
        status: SttPreparationStatus.modelDownloading,
        message: '음성 인식을 준비 중입니다. 잠시 후 다시 시도해 주세요.',
      ),
    ]) {
      final repository = _WidgetScriptRepository(
        initialScripts: [
          _script(id: 1, title: '상태 확인 대본', body: '직접 작성한 문장을 읽습니다.'),
        ],
      );
      var setupBuilds = 0;
      await tester.pumpWidget(
        _buildAppWithReading(
          repository,
          prepareReading: () async => SttPreparation(status: scenario.status),
          readingSetupBuilder: (_) {
            setupBuilds++;
            return const SizedBox(key: Key('reading-setup-probe'));
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('상태 확인 대본'));
      await tester.pumpAndSettle();
      expect(find.text(scenario.message), findsOneWidget);
      expect(setupBuilds, 0);
      expect(find.byKey(const Key('reading-setup-probe')), findsNothing);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('빈 제목과 공백뿐인 본문을 같은 화면에서 안내한다', (tester) async {
    final repository = _WidgetScriptRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.pump();
    await tester.tap(find.text('대본 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('script-title-field')), '   ');
    await tester.enterText(find.byKey(const Key('script-body-field')), '\n\t ');
    await tester.tap(find.text('저장'));
    await tester.pump();

    expect(find.text('제목을 입력하세요.'), findsOneWidget);
    expect(find.text('본문을 입력하세요.'), findsOneWidget);
    expect(find.byKey(const Key('script-title-field')), findsOneWidget);
    expect(repository.scripts, isEmpty);
  });

  testWidgets('저장 실패 시 추가 화면을 유지하고 다시 시도 안내를 표시한다', (tester) async {
    final repository = _WidgetScriptRepository(failCreate: true);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pump();
    await tester.tap(find.text('대본 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('script-title-field')),
      '연습 제목',
    );
    await tester.enterText(
      find.byKey(const Key('script-body-field')),
      '직접 작성한 문장을 읽습니다.',
    );
    await tester.tap(find.byKey(const Key('script-create-save-button')));
    await tester.pump();

    expect(find.text('저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('script-title-field')), findsOneWidget);
    expect(repository.scripts, isEmpty);
  });

  testWidgets('iOS와 Android에서 추가 버튼의 화면 위치가 같다', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    final buttonRects = <TargetPlatform, Rect>{};
    final labelRects = <TargetPlatform, Rect>{};

    try {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        final repository = _WidgetScriptRepository();

        await tester.pumpWidget(_buildApp(repository));
        await tester.pumpAndSettle();

        buttonRects[platform] = tester.getRect(
          find.byKey(const Key('script-list-add-button')),
        );
        labelRects[platform] = tester.getRect(find.text('추가'));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }

    expect(
      buttonRects[TargetPlatform.android],
      buttonRects[TargetPlatform.iOS],
    );
    expect(labelRects[TargetPlatform.android], labelRects[TargetPlatform.iOS]);
    expect(
      labelRects[TargetPlatform.iOS]!.center.dy,
      kMinInteractiveDimensionCupertino / 2,
    );
  });

  testWidgets('iOS와 Android 추가 버튼은 200% 배율과 접근성을 보존한다', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    final semantics = tester.ensureSemantics();
    final scaledButtonRects = <TargetPlatform, Rect>{};
    try {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        tester.platformDispatcher.textScaleFactorTestValue = 1;
        await tester.pumpWidget(_buildApp(_WidgetScriptRepository()));
        await tester.pumpAndSettle();

        final addButton = find.byKey(const Key('script-list-add-button'));
        final unscaledButtonRect = tester.getRect(addButton);
        final unscaledLabelRect = tester.getRect(find.text('추가'));
        expect(unscaledButtonRect.width, greaterThanOrEqualTo(48));
        expect(unscaledButtonRect.height, greaterThanOrEqualTo(48));

        await tester.pumpWidget(const SizedBox.shrink());
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpWidget(_buildApp(_WidgetScriptRepository()));
        await tester.pumpAndSettle();

        final scaledButtonRect = tester.getRect(addButton);
        final scaledLabelRect = tester.getRect(find.text('추가'));
        scaledButtonRects[platform] = scaledButtonRect;

        expect(tester.takeException(), isNull);
        expect(scaledButtonRect.width, greaterThanOrEqualTo(48));
        expect(scaledButtonRect.height, greaterThanOrEqualTo(48));
        expect(scaledButtonRect.topRight, unscaledButtonRect.topRight);
        expect(
          scaledLabelRect.width,
          greaterThan(unscaledLabelRect.width * 1.8),
        );
        expect(
          scaledLabelRect.height,
          greaterThan(unscaledLabelRect.height * 1.8),
        );
        expect(scaledButtonRect.contains(scaledLabelRect.topLeft), isTrue);
        expect(scaledButtonRect.contains(scaledLabelRect.bottomRight), isTrue);

        final addButtonSemantics = find.bySemanticsLabel('새 대본 추가');
        expect(addButtonSemantics, findsOneWidget);
        expect(
          tester
              .getSemantics(addButtonSemantics)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );

        final buttonRenderObject = tester.renderObject(addButton);
        for (final position in [
          scaledButtonRect.topLeft + const Offset(1, 1),
          scaledButtonRect.bottomRight - const Offset(1, 1),
        ]) {
          final hitTest = tester.hitTestOnBinding(position);
          expect(
            hitTest.path.any((entry) => entry.target == buttonRenderObject),
            isTrue,
          );
        }

        await tester.tapAt(scaledButtonRect.bottomRight - const Offset(1, 1));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('script-title-field')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    } finally {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      semantics.dispose();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }

    expect(
      scaledButtonRects[TargetPlatform.android],
      scaledButtonRects[TargetPlatform.iOS],
    );
  });

  testWidgets('Android 추가 화면 내비게이션 조작의 터치 영역이 48 이상이다', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_buildApp(_WidgetScriptRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('script-list-add-button')));
      await tester.pumpAndSettle();
      for (final key in [
        const Key('script-create-cancel-button'),
        const Key('script-create-save-button'),
      ]) {
        final button = find.byKey(key);
        expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('Android 큰 글씨에서도 우측 상단 추가 버튼이 잘리지 않는다', (tester) async {
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    final repository = _WidgetScriptRepository();

    try {
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      final buttonRect = tester.getRect(
        find.byKey(const Key('script-list-add-button')),
      );
      final screenRect = tester.getRect(find.byType(CupertinoPageScaffold));
      final labelRect = tester.getRect(find.text('추가'));

      expect(tester.takeException(), isNull);
      expect(buttonRect.width, greaterThanOrEqualTo(48));
      expect(buttonRect.height, greaterThanOrEqualTo(48));
      expect(buttonRect.top, screenRect.top);
      expect(buttonRect.right, screenRect.right - 16);
      expect(buttonRect.contains(labelRect.topLeft), isTrue);
      expect(buttonRect.contains(labelRect.bottomRight), isTrue);
    } finally {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      debugDefaultTargetPlatformOverride = originalPlatform;
    }
  });

  testWidgets('대형 제목이 축소되는 동안 추가 버튼은 우측 상단을 유지한다', (tester) async {
    final repository = _WidgetScriptRepository(
      initialScripts: List.generate(
        20,
        (index) => _script(
          id: index + 1,
          title: '직접 작성한 대본 ${index + 1}',
          body: '직접 작성한 문장을 천천히 읽습니다.',
        ),
      ),
    );

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    final addButton = find.byKey(const Key('script-list-add-button'));
    final initialButtonRect = tester.getRect(addButton);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(52));
    expect(tester.getRect(addButton), initialButtonRect);
  });

  testWidgets('큰 글씨에서 긴 제목이 줄바꿈되고 주요 터치 영역이 48 이상이다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = _WidgetScriptRepository(
      initialScripts: [
        _script(
          id: 1,
          title: '여러 줄로 표시되는 직접 작성한 매우 긴 대본 제목',
          body: '직접 작성한 긴 본문을 화면에서 확인합니다.',
        ),
      ],
    );
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('대본 여러 줄로 표시되는 직접 작성한 매우 긴 대본 제목 삭제'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byIcon(CupertinoIcons.delete)).width,
      lessThan(48),
    );
    final deleteButton = find.ancestor(
      of: find.byIcon(CupertinoIcons.delete),
      matching: find.byType(CupertinoButton),
    );
    expect(tester.getSize(deleteButton.first).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(deleteButton.first).height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });
}

Widget _buildApp(_WidgetScriptRepository repository) {
  return MalttoApp(
    scriptListViewModel: ScriptListViewModel(repository),
    createScriptViewModel: () => ScriptCreateViewModel(repository),
    readingSetupBuilder: (_) => const SizedBox.shrink(),
  );
}

Widget _buildAppWithReading(
  _WidgetScriptRepository repository, {
  required Future<SttPreparation> Function() prepareReading,
  Widget Function(Script script)? readingSetupBuilder,
}) {
  return MalttoApp(
    scriptListViewModel: ScriptListViewModel(repository),
    createScriptViewModel: () => ScriptCreateViewModel(repository),
    readingSetupBuilder:
        readingSetupBuilder ??
        (_) => const SizedBox(key: Key('reading-setup-probe')),
    prepareReading: prepareReading,
  );
}

Script _script({required int id, required String title, required String body}) {
  final now = DateTime.utc(2026, 10, 31);
  return Script(
    id: id,
    title: title,
    body: body,
    createdAt: now,
    updatedAt: now,
  );
}

final class _WidgetScriptRepository implements ScriptRepository {
  _WidgetScriptRepository({
    List<Script> initialScripts = const [],
    this.failCreate = false,
  }) : scripts = [...initialScripts];

  final _controller = StreamController<List<Script>>.broadcast();
  final List<Script> scripts;
  final bool failCreate;
  int _nextId = 1;

  @override
  Stream<List<Script>> watchAll() async* {
    yield List.unmodifiable(scripts);
    yield* _controller.stream;
  }

  @override
  Future<List<Script>> getAll() async => List.unmodifiable(scripts);

  @override
  Future<Script> create({required String title, required String body}) async {
    if (failCreate) throw StateError('저장 실패');
    final script = _script(id: _nextId++, title: title, body: body);
    scripts.insert(0, script);
    _controller.add(List.unmodifiable(scripts));
    return script;
  }

  @override
  Future<void> delete(int id) async {
    scripts.removeWhere((script) => script.id == id);
    _controller.add(List.unmodifiable(scripts));
  }
}
