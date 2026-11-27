abstract interface class DuoToolbarController {
  Future<bool> isVerticalToolbar();

  Future<void> setAddVisible(bool visible);

  void setHandlers({
    required Future<void> Function() onOpenCreate,
    required void Function(bool isVertical) onVerticalToolbarChanged,
  });

  void dispose();
}
