import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour tokens: dark grey surfaces with a baby-blue accent.
abstract final class AppColors {
  static const background = Color(0xFF0D0E11);
  static const panel = Color(0xFF16171C);
  static const surface = Color(0xFF1F2027);
  static const surfaceHover = Color(0xFF292A33);
  static const inset = Color(0xFF111216);
  static const border = Color(0xFF24252E);
  static const divider = Color(0xFF22232B);
  static const borderStrong = Color(0xFF353644);
  static const accent = Color(0xFF7DD3FC);
  static const accentPressed = Color(0xFF38BDF8);
  static const accentSoft = Color(0xFFBAE6FD);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const textPrimary = Color(0xFFF4F4F5);
  static const textBody = Color(0xFFE4E4E7);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const textFaint = Color(0xFF52525B);
}

abstract final class AppRadius {
  static const panel = 20.0;
  static const control = 14.0;
  static const chip = 8.0;
}

/// Spacing scale (8-point grid). Use these instead of ad-hoc numbers so rhythm stays consistent.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 40.0;

  /// Horizontal page margin.
  static const gutter = 16.0;
}

/// Minimum touch target (Apple HIG: 44pt).
const double kMinTouchTarget = 44;

/// Body and interface text (Sofia Sans, set heavy).
const String kFontFamily = 'SofiaSans';

/// Headings, titles, codes and readouts (Chivo, set heavy).
const String kDisplayFamily = 'Chivo';

/// Typography: Chivo for headings and figures, Sofia Sans for everything else.
abstract final class AppText {
  /// Screen title (centred, collapses into the navigation bar).
  static const largeTitle = TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );
  static const headline = TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textBody,
  );
  static const callout = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static const footnote = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textMuted,
  );
  static const caption = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textMuted,
  );

  /// Grouped-section header: small caps, tracked out.
  static const sectionHeader = TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: AppColors.textMuted,
  );

  /// Small tracked readout for HUD labels and counters.
  static const readout = TextStyle(
    fontFamily: kDisplayFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.accent,
  );

  /// Codes and PINs: heavy Chivo with tabular figures so digits line up.
  static const code = TextStyle(
    fontFamily: kDisplayFamily,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const button = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
  );
}

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
      error: AppColors.danger,
      onSurface: AppColors.textBody,
      outline: AppColors.border,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    // iOS-style page transitions and overscroll everywhere.
    platform: TargetPlatform.iOS,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textBody,
      displayColor: AppColors.textPrimary,
      fontFamily: kFontFamily,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
      contentTextStyle: AppText.body.copyWith(fontSize: 14, color: AppColors.textPrimary),
      actionTextColor: AppColors.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
  );
}

/// Cupertino styling for the large-title navigation bars, action sheets and alerts.
const CupertinoThemeData kCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.accent,
  scaffoldBackgroundColor: AppColors.background,
  barBackgroundColor: Color(0xCC0D0E11),
  textTheme: CupertinoTextThemeData(
    primaryColor: AppColors.accent,
    textStyle: AppText.body,
    actionTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 17, color: AppColors.accent),
    navTitleTextStyle: AppText.headline,
    navLargeTitleTextStyle: AppText.largeTitle,
    navActionTextStyle: TextStyle(fontFamily: kFontFamily, fontSize: 17, color: AppColors.accent),
  ),
);

const SystemUiOverlayStyle kSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.light,
);
