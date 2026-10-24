import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// App mark for the navigation bar: scan glyph + "iscanna1.0" wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'iscanna 1.0',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.scanLine, size: 18, color: AppColors.accent),
          const SizedBox(width: 7),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'iscanna',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: '1.0',
                  style: TextStyle(color: AppColors.accent),
                ),
              ],
            ),
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// HIG inset-grouped section: optional small-caps header, rounded card, optional footnote.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.child,
    this.header,
    this.headerTrailing,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  });

  final Widget child;
  final String? header;
  final Widget? headerTrailing;
  final String? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.xs, AppSpace.md),
            child: Row(
              children: [
                Expanded(child: Text(header!, style: AppText.sectionHeader)),
                ?headerTrailing,
              ],
            ),
          ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.5),
          ),
          child: child,
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
            child: Text(footer!, style: AppText.footnote),
          ),
      ],
    );
  }
}

/// Hairline separator used between rows inside a grouped section.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: SizedBox(
        height: 0.5,
        width: double.infinity,
        child: ColoredBox(color: AppColors.borderStrong),
      ),
    );
  }
}

/// Scales its child down while pressed, with a selection haptic on tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.haptic = true, this.pressedScale = 0.97});

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _down ? 0.8 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

/// HIG button styles.
enum ButtonKind { filled, tinted, gray, plain }

enum ButtonSize {
  large(50, 15),
  medium(44, 14),
  small(34, 13);

  const ButtonSize(this.height, this.fontSize);
  final double height;
  final double fontSize;
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.kind = ButtonKind.gray,
    this.size = ButtonSize.medium,
    this.expand = false,
    this.destructive = false,
    this.semanticLabel,
    this.haptic = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final ButtonSize size;
  final bool expand;
  final bool destructive;
  final String? semanticLabel;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.danger : AppColors.accent;
    final (bg, fg) = switch (kind) {
      ButtonKind.filled => (tint, AppColors.onAccent),
      ButtonKind.tinted => (tint.withValues(alpha: 0.14), tint),
      ButtonKind.gray => (AppColors.surface, destructive ? AppColors.danger : AppColors.textPrimary),
      ButtonKind.plain => (Colors.transparent, tint),
    };
    final enabled = onPressed != null;
    // HIG: disabled buttons turn grey rather than fading their tint.
    final (bgOut, fgOut) = enabled || kind == ButtonKind.plain
        ? (bg, fg)
        : (kind == ButtonKind.gray ? bg : AppColors.surface, AppColors.textFaint);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        haptic: haptic,
        child: AnimatedOpacity(
          opacity: enabled || kind != ButtonKind.plain ? 1 : 0.4,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: size.height,
            padding: EdgeInsets.symmetric(horizontal: kind == ButtonKind.plain ? AppSpace.sm : AppSpace.lg),
            decoration: BoxDecoration(
              color: bgOut,
              borderRadius: BorderRadius.circular(size == ButtonSize.small ? 10 : AppRadius.control),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: size.fontSize + 2, color: fgOut),
                  const SizedBox(width: AppSpace.sm),
                ],
                Flexible(
                  // Shrinks a little rather than cutting the label off when space is tight.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppText.button.copyWith(fontSize: size.fontSize, color: fgOut),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon-only button (toolbar / camera controls).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.size = kMinTouchTarget,
    this.color,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final double size;

  /// Icon colour; defaults to the primary text colour.
  final Color? color;

  /// Fill colour; defaults to the surface colour.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Pressable(
          onTap: onPressed,
          pressedScale: 0.92,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onPressed == null
                  ? AppColors.surface
                  : (active ? AppColors.accent : background ?? AppColors.surface),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: size * 0.42,
              color: onPressed == null
                  ? AppColors.textFaint
                  : (active ? AppColors.onAccent : color ?? AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status pill with a glowing dot: Verified / Needs Review / Unreadable.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final CardStatus status;

  static (String, Color) describe(CardStatus status) => switch (status) {
    CardStatus.success => ('Verified', AppColors.accent),
    CardStatus.warning => ('Review', AppColors.warning),
    CardStatus.error => ('Unreadable', AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = describe(status);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, 4, 10, 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontFamily: kFontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral capsule, e.g. a carrier name.
class Capsule extends StatelessWidget {
  const Capsule(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(100)),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Radio buttons laid out side by side: a ring per option, filled when selected.
class RadioPicker<T extends Object> extends StatelessWidget {
  const RadioPicker({super.key, required this.value, required this.options, required this.onChanged});

  final T value;

  /// Value → (title, optional detail shown dimmed after it).
  final Map<T, (String, String?)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          for (final MapEntry(:key, value: (title, detail)) in options.entries)
            Expanded(
              child: _RadioOption(title: title, detail: detail, selected: key == value, onTap: () => onChanged(key)),
            ),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.title, required this.detail, required this.selected, required this.onTap});

  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: title,
      excludeSemantics: true,
      child: Pressable(
        onTap: selected ? null : onTap,
        pressedScale: 1,
        child: SizedBox(
          height: kMinTouchTarget,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? AppColors.accent : AppColors.borderStrong, width: 2),
                    ),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: selected ? 1 : 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm + 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: kButtonFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      detail!,
                      style: TextStyle(
                        fontFamily: kDisplayFamily,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 11,
                        color: selected ? AppColors.accent : AppColors.textFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer credit linking to the author's X profile: small, muted and centred at the end of a page,
/// with clear space above it so it never crowds the content or the tab bar.
class AuthorFooter extends StatelessWidget {
  const AuthorFooter({super.key, this.top = AppSpace.xxxl});

  /// Space above the credit.
  final double top;

  static final Uri profile = Uri.parse('https://x.com/exxstatix');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: AppSpace.md),
      // heightFactor 1: hug the link vertically instead of filling the space it's given.
      child: Center(
        heightFactor: 1,
        child: Semantics(
          link: true,
          label: 'exxstatix on X',
          excludeSemantics: true,
          child: Pressable(
            onTap: () async {
              var ok = false;
              try {
                ok = await launchUrl(profile, mode: LaunchMode.externalApplication);
              } catch (_) {}
              if (!ok && context.mounted) showToast(context, "Couldn't open x.com/exxstatix");
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
              // Deliberately quiet: a small, muted credit rather than a call to action.
              child: Text(
                '*exxstatix',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action, duration: const Duration(seconds: 3)));
}
