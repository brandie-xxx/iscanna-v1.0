import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour tokens carried over 1:1 from the web design.
abstract final class AppColors {
  static const background = Color(0xFF111215);
  static const panel = Color(0xFF181920);
  static const surface = Color(0xFF22232C);
  static const surfaceHover = Color(0xFF2B2C37);
  static const inset = Color(0xFF1E1F27);
  static const border = Color(0xFF272832);
  static const divider = Color(0xFF24252E);
  static const borderStrong = Color(0xFF353644);
  static const accent = Color(0xFF7DD3FC);
  static const accentPressed = Color(0xFF38BDF8);
  static const accentSoft = Color(0xFFBAE6FD);
  static const textPrimary = Color(0xFFF4F4F5);
  static const textBody = Color(0xFFE4E4E7);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF71717A);
  static const textFaint = Color(0xFF52525B);
}

abstract final class AppRadius {
  static const panel = 16.0;
  static const control = 10.0;
  static const chip = 7.0;
}

/// Spacing scale. Use these instead of ad-hoc numbers so rhythm stays consistent.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;

  /// Horizontal page margin.
  static const gutter = 16.0;
}

/// Minimum touch target, matching the web app's 44px buttons.
const double kMinTouchTarget = 44;

const String kFontFamily = 'GeistPixel';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.panel,
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.accent,
      onSurface: AppColors.textBody,
      outline: AppColors.border,
    ),
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textBody,
      displayColor: AppColors.textPrimary,
      fontFamily: kFontFamily,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.2),
      selectionHandleColor: AppColors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface,
      contentTextStyle: const TextStyle(fontFamily: kFontFamily, color: AppColors.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.borderStrong,
    ),
  );
}

const SystemUiOverlayStyle kSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.light,
);
