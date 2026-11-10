import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maltto/src/shared/design/app_components.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';

void main() {
  testWidgets('일반 모드는 그림자를 clip 바깥에 두고 blur와 표면을 radius 안에 둔다', (tester) async {
    await _pumpSurface(tester);

    final outerSurface = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration ==
              const BoxDecoration(
                borderRadius: AppRadii.toolbar,
                boxShadow: AppShadows.glass,
              ),
    );
    final clip = find.byType(ClipRRect);
    final blur = find.byType(BackdropFilter);
    final innerSurface = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration ==
              BoxDecoration(
                color: AppColors.canvas.withValues(alpha: .78),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: AppStrokes.hairline,
                ),
                borderRadius: AppRadii.toolbar,
              ),
    );

    expect(outerSurface, findsOneWidget);
    expect(clip, findsOneWidget);
    expect(tester.widget<ClipRRect>(clip).borderRadius, AppRadii.toolbar);
    expect(find.ancestor(of: clip, matching: outerSurface), findsOneWidget);
    expect(find.ancestor(of: outerSurface, matching: clip), findsNothing);
    expect(find.ancestor(of: blur, matching: clip), findsOneWidget);
    expect(find.ancestor(of: innerSurface, matching: clip), findsOneWidget);
    expect(find.ancestor(of: innerSurface, matching: blur), findsOneWidget);
  });

  testWidgets('고대비 모드는 blur와 glass shadow 없이 불투명 표면과 separator를 쓴다', (
    tester,
  ) async {
    await _pumpSurface(tester, highContrast: true);

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(ClipRRect), findsNothing);

    final surface = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration ==
              BoxDecoration(
                color: AppColors.system,
                border: Border.all(
                  color: AppColors.separator,
                  width: AppStrokes.hairline,
                ),
                borderRadius: AppRadii.toolbar,
              ),
    );
    expect(surface, findsOneWidget);
  });
}

Future<void> _pumpSurface(WidgetTester tester, {bool highContrast = false}) =>
    tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: const CupertinoPageScaffold(
            child: Center(child: AppGlassSurface(child: Text('테스트 문장'))),
          ),
        ),
      ),
    );
