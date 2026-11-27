import 'dart:async';

import 'package:maltto/src/features/scripts/presentation/duo_toolbar_controller.dart';
import 'package:maltto/src/infrastructure/duo_toolbar/generated/duo_toolbar_api.g.dart';

final class PigeonDuoToolbarController
    implements DuoToolbarController, DuoToolbarFlutterApi {
  PigeonDuoToolbarController({DuoToolbarHostApi? host})
    : _host = host ?? DuoToolbarHostApi();

  final DuoToolbarHostApi _host;
  Future<void> Function()? _onOpenCreate;
  void Function(bool isVertical)? _onVerticalToolbarChanged;

  @override
  Future<bool> isVerticalToolbar() => _host.isVerticalToolbar();

  @override
  Future<void> setAddVisible(bool visible) => _host.setAddVisible(visible);

  @override
  void setHandlers({
    required Future<void> Function() onOpenCreate,
    required void Function(bool isVertical) onVerticalToolbarChanged,
  }) {
    _onOpenCreate = onOpenCreate;
    _onVerticalToolbarChanged = onVerticalToolbarChanged;
    DuoToolbarFlutterApi.setUp(this);
  }

  @override
  void openCreate() {
    unawaited(_onOpenCreate?.call());
  }

  @override
  void verticalToolbarChanged(bool isVertical) {
    _onVerticalToolbarChanged?.call(isVertical);
  }

  @override
  void dispose() {
    DuoToolbarFlutterApi.setUp(null);
    _onOpenCreate = null;
    _onVerticalToolbarChanged = null;
  }
}
