import 'package:flutter/cupertino.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFFFFFFF);
  static const selectionSoft = Color(0xFFF0EFFF);
  static const system = Color(0xFFF2F2F7);
  static const glassBorder = Color(0xFFFFFFFF);
  static const separator = Color(0xFFD9D9DE);
  static const brand = Color(0xFF5856D6);
  static const destructive = Color(0xFFFF3B30);
  static const dialogOverlay = Color(0x3D000000);
  static const sheetOverlay = Color(0x38000000);
  static const placeholder = Color(0xFFAEAEB2);
  static const primaryText = Color(0xFF222222);
  static const secondaryText = Color(0xFF6E6E73);
}

abstract final class AppSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
  static const double section = 32;
}

abstract final class AppTargets {
  static const double minimum = 44;
  static const double preferred = 48;

  static const BoxConstraints preferredConstraints = BoxConstraints(
    minWidth: preferred,
    minHeight: preferred,
  );
}

abstract final class AppRadii {
  static const BorderRadius accessibility = BorderRadius.all(
    Radius.circular(8),
  );
  static const BorderRadius action = BorderRadius.all(Radius.circular(12));
  static const BorderRadius control = BorderRadius.all(Radius.circular(10));
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(14));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(20),
  );
  static const BorderRadius surface = BorderRadius.all(Radius.circular(16));
  static const BorderRadius toolbar = BorderRadius.all(Radius.circular(18));
  static const BorderRadius medium = action;
}

abstract final class AppTypography {
  static const String family = '.SF Pro Text';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 17,
    color: AppColors.primaryText,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    color: AppColors.secondaryText,
  );
  static const dialogTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: semibold,
    color: AppColors.primaryText,
  );
  static const footnote = TextStyle(
    fontFamily: family,
    fontSize: 13,
    color: AppColors.secondaryText,
  );
  static const reading = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 1.55,
    color: AppColors.primaryText,
  );
  static const readingXL = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 1.5,
    color: AppColors.primaryText,
  );
  static const status = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: semibold,
    color: AppColors.primaryText,
  );
  static const subheadline = TextStyle(
    fontFamily: family,
    fontSize: 15,
    color: AppColors.secondaryText,
  );
}

abstract final class AppShadows {
  static const dialog = [
    BoxShadow(color: Color(0x24000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const glass = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const glassXL = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

abstract final class AppStrokes {
  static const double hairline = 0.5;
  static const double icon = 1.5;
}

abstract final class AppMotion {
  static const Duration none = Duration.zero;
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration scroll = Duration(milliseconds: 250);
}
