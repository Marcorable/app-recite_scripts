import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';

final class AppSheetAction extends StatelessWidget {
  const AppSheetAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: AppTargets.preferredConstraints,
    child: primary
        ? CupertinoButton.filled(onPressed: onPressed, child: Text(label))
        : CupertinoButton(
            color: AppColors.system,
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.primaryText),
            ),
          ),
  );
}

final class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.medium),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final reduceTransparency = MediaQuery.highContrastOf(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: reduceTransparency
            ? AppColors.system
            : AppColors.canvas.withValues(alpha: .78),
        border: Border.all(
          color: reduceTransparency
              ? AppColors.separator
              : AppColors.glassBorder,
          width: AppStrokes.hairline,
        ),
        borderRadius: AppRadii.toolbar,
        boxShadow: reduceTransparency ? null : AppShadows.glass,
      ),
      child: Padding(padding: padding, child: child),
    );
    return reduceTransparency
        ? surface
        : ClipRRect(
            borderRadius: AppRadii.toolbar,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: surface,
            ),
          );
  }
}
