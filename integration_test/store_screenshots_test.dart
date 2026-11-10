import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maltto/src/app/app.dart';
import 'package:maltto/src/features/reading/presentation/reading_setup_view.dart';
import 'package:maltto/src/features/reading/presentation/reading_setup_view_model.dart';
import 'package:maltto/src/features/reading/presentation/reading_view.dart';
import 'package:maltto/src/features/reading/presentation/reading_view_model.dart';
import 'package:maltto/src/features/scripts/presentation/script_create_view.dart';
import 'package:maltto/src/features/scripts/presentation/script_create_view_model.dart';
import 'package:maltto/src/features/scripts/presentation/script_list_view_model.dart';

import 'support/store_screenshot_fixture.dart';

const _largeText = bool.fromEnvironment('STORE_LARGE_TEXT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 script list', (tester) async {
    final scripts = StoreScreenshotScriptRepository(
      scripts: storeScreenshotScripts,
    );
    final reading = StoreScreenshotReadingRepository();
    addTearDown(scripts.dispose);
    addTearDown(reading.dispose);

    await _pump(
      tester,
      MalttoApp(
        scriptListViewModel: ScriptListViewModel(scripts),
        createScriptViewModel: () => ScriptCreateViewModel(scripts),
        readingSetupBuilder: (script) => ReadingSetupView(
          viewModel: ReadingSetupViewModel(script: script, repository: reading),
        ),
      ),
    );
    await _capture(binding, tester, '01-script-list');
  });

  testWidgets('02 script editor', (tester) async {
    final scripts = StoreScreenshotScriptRepository();
    addTearDown(scripts.dispose);

    await _pump(
      tester,
      CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: ScriptCreateView(viewModel: ScriptCreateViewModel(scripts)),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('script-title-field')),
      storeScreenshotTitle,
    );
    await tester.enterText(
      find.byKey(const Key('script-body-field')),
      storeScreenshotBody,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await _capture(binding, tester, '02-script-editor');
  });

  testWidgets('03 reading setup', (tester) async {
    final reading = StoreScreenshotReadingRepository();
    addTearDown(reading.dispose);
    final viewModel = ReadingSetupViewModel(
      script: storeScreenshotScript,
      repository: reading,
    )..selectRepetitions(3);

    await _pump(
      tester,
      CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: ReadingSetupView(viewModel: viewModel),
      ),
    );
    await _capture(binding, tester, '03-reading-setup');
  });

  testWidgets('04 reading progress', (tester) async {
    final state = storeScreenshotReadingState();
    final reading = StoreScreenshotReadingRepository(initialState: state);
    addTearDown(reading.dispose);

    await _pump(
      tester,
      CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: ReadingView(
          viewModel: ReadingViewModel(repository: reading, initialState: state),
        ),
      ),
    );
    await _capture(binding, tester, '04-reading-progress');
  });
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  if (_largeText) {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
  }
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}
