import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One set of colour tokens. [AppColors] reads from the active palette.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.panel,
    required this.surface,
    required this.surfaceHover,
    required this.inset,
    required this.border,
    required this.divider,
    required this.borderStrong,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.scrim,
  });

  final Brightness brightness;
  final Color background;
  final Color panel;
  final Color surface;
  final Color surfaceHover;
  final Color inset;
  final Color border;
  final Color divider;
  final Color borderStrong;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;

  /// Text and icons on a filled accent background.
  final Color onAccent;

  /// Confirmation, e.g. a card that is in the batch.
  final Color success;
  final Color warning;
  final Color danger;
  final Color textPrimary;
  final Color textBody;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  /// Modal barrier behind sheets.
  final Color scrim;

  /// Dark grey surfaces with a sky-blue accent.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0D0E11),
    panel: Color(0xFF16171C),
    surface: Color(0xFF1F2027),
    surfaceHover: Color(0xFF292A33),
    inset: Color(0xFF111216),
    border: Color(0xFF24252E),
    divider: Color(0xFF22232B),
    borderStrong: Color(0xFF353644),
    accent: Color(0xFF38BDF8),
    accentPressed: Color(0xFF0EA5E9),
    accentSoft: Color(0xFF7DD3FC),
    onAccent: Color(0xFF0D0E11),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    textPrimary: Color(0xFFF4F4F5),
    textBody: Color(0xFFE4E4E7),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    textFaint: Color(0xFF52525B),
    scrim: Color(0x99000000),
  );

  /// iOS-style grouped light: soft grey page, white panels, a deeper blue for contrast on white.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF2F3F7),
    panel: Color(0xFFFFFFFF),
    surface: Color(0xFFEBECF0),
    surfaceHover: Color(0xFFDEDFE5),
    inset: Color(0xFFF5F6F9),
    border: Color(0xFFE3E4E9),
    divider: Color(0xFFE6E7EB),
    borderStrong: Color(0xFFCDCED6),
    accent: Color(0xFF0284C7),
    accentPressed: Color(0xFF0369A1),
    accentSoft: Color(0xFF38BDF8),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    textPrimary: Color(0xFF0B0C0F),
    textBody: Color(0xFF1C1D22),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF6B6B74),
    textFaint: Color(0xFF9D9DA6),
    scrim: Color(0x66000000),
  );
}

/// Colour tokens for the active palette (follows the phone's light/dark setting).
abstract final class AppColors {
  /// The active palette; set from the phone's brightness at start-up and whenever it changes.
  static AppPalette palette = AppPalette.dark;

  static Brightness get brightness => palette.brightness;
  static Color get background => palette.background;
  static Color get panel => palette.panel;
  static Color get surface => palette.surface;
  static Color get surfaceHover => palette.surfaceHover;
  static Color get inset => palette.inset;
  static Color get border => palette.border;
  static Color get divider => palette.divider;
  static Color get borderStrong => palette.borderStrong;
  static Color get accent => palette.accent;
  static Color get accentPressed => palette.accentPressed;
  static Color get accentSoft => palette.accentSoft;
  static Color get onAccent => palette.onAccent;
  static Color get success => palette.success;
  static Color get warning => palette.warning;
  static Color get danger => palette.danger;
  static Color get textPrimary => palette.textPrimary;
  static Color get textBody => palette.textBody;
  static Color get textSecondary => palette.textSecondary;
  static Color get textMuted => palette.textMuted;
  static Color get textFaint => palette.textFaint;
  static Color get scrim => palette.scrim;
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
  static const xxl = 32.0;
  static const xxxl = 44.0;

  /// Gap between top-level sections on a screen.
  static const section = 40.0;

  /// Horizontal page margin.
  static const gutter = 20.0;
}

/// Minimum touch target (Apple HIG: 44pt).
const double kMinTouchTarget = 44;

/// Interface text: headings, labels and body (Inter).
const String kFontFamily = 'Inter';

/// Buttons and controls (Sofia Sans, set heavy).
const String kButtonFamily = 'SofiaSans';

/// Codes, PINs and other figures (Chivo, set heavy).
const String kDisplayFamily = 'Chivo';

/// Edit PIN keypad digits (Inter Tight, extra bold).
const String kKeypadFamily = 'InterTight';

/// Typography: Inter for text, Sofia Sans for buttons, Chivo for figures.
/// Casing is always standard (sentence/title case): never force uppercase.
abstract final class AppText {
  /// Screen title once collapsed into the top bar, and sheet titles.
  static TextStyle get barTitle => largeTitle.copyWith(fontSize: 14);

  /// Screen title (centred, collapses into the navigation bar).
  static TextStyle get largeTitle => TextStyle(
    fontFamily: kFontFamily,
    // Same size as the header wordmark.
    fontSize: 15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );
  static TextStyle get headline => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  static TextStyle get body => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.textBody,
  );
  static TextStyle get callout => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.1,
    color: AppColors.textSecondary,
  );
  static TextStyle get footnote => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );
  static TextStyle get caption => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textMuted,
  );

  /// Grouped-section header, in standard casing.
  static TextStyle get sectionHeader => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textMuted,
  );

  /// Small accent label for HUD hints and counters.
  static TextStyle get readout =>
      TextStyle(fontFamily: kFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.accent);

  /// Codes and PINs: heavy Chivo with tabular figures so digits line up.
  static const code = TextStyle(
    fontFamily: kDisplayFamily,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const button = TextStyle(
    fontFamily: kButtonFamily,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.1,
  );
}

ThemeData buildAppTheme() {
  final dark = AppColors.brightness == Brightness.dark;
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    surface: AppColors.panel,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accent,
    error: AppColors.danger,
    onSurface: AppColors.textBody,
    outline: AppColors.border,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: AppColors.brightness,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
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
      backgroundColor: dark ? AppColors.surface : AppColors.textPrimary,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
      contentTextStyle: AppText.body.copyWith(fontSize: 13.5, color: dark ? AppColors.textPrimary : AppColors.panel),
      actionTextColor: dark ? AppColors.accent : AppColors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: dark ? BorderSide(color: AppColors.borderStrong) : BorderSide.none,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
  );
}

/// Cupertino styling for action sheets and alerts.
CupertinoThemeData buildCupertinoTheme() => CupertinoThemeData(
  brightness: AppColors.brightness,
  primaryColor: AppColors.accent,
  scaffoldBackgroundColor: AppColors.background,
  barBackgroundColor: AppColors.background.withValues(alpha: 0.8),
  textTheme: CupertinoTextThemeData(
    primaryColor: AppColors.accent,
    textStyle: AppText.body,
    actionTextStyle: TextStyle(
      fontFamily: kButtonFamily,
      fontSize: 15.5,
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
    ),
    navTitleTextStyle: AppText.headline,
    navLargeTitleTextStyle: AppText.largeTitle,
    navActionTextStyle: TextStyle(
      fontFamily: kButtonFamily,
      fontSize: 15.5,
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
    ),
  ),
);

/// Status and navigation bar styling to match the active palette.
SystemUiOverlayStyle systemUiStyle() {
  final dark = AppColors.brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: AppColors.brightness,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
  );
}
