import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'lib/src/infrastructure/duo_toolbar/generated/duo_toolbar_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Generated/DuoToolbarApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'DuoToolbarPigeonError'),
  ),
)
@HostApi()
abstract class DuoToolbarHostApi {
  bool isVerticalToolbar();

  void setAddVisible(bool visible);
}

@FlutterApi()
abstract class DuoToolbarFlutterApi {
  void openCreate();

  void verticalToolbarChanged(bool isVertical);
}
