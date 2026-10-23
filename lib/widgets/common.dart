import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Rounded container used for every top-level section.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Panel title row with a hairline divider underneath.
/// The title side takes all space the trailing widget doesn't need, so it is never cut short.
class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, this.leadingBadge, this.trailing});

  final String title;
  final Widget? leadingBadge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (leadingBadge != null) ...[const SizedBox(width: AppSpace.sm), leadingBadge!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpace.md), trailing!],
        ],
      ),
    );
  }
}

/// Small uppercase heading above a control group, e.g. "CARRIER".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.label)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Darker recessed box used inside panels.
class Inset extends StatelessWidget {
  const Inset({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

abstract final class AppText {
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.55);
  static const label = TextStyle(
    fontSize: 10.5,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const button = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
}

/// Small rounded tag, e.g. the carrier name or "Verified".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.soft = false, this.filled = false});

  final String text;

  /// Translucent accent background (status badges).
  final bool soft;

  /// Solid accent background (active count bubbles).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.accent
            : soft
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: filled ? null : Border.all(color: soft ? AppColors.accent.withValues(alpha: 0.2) : AppColors.border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: filled ? AppColors.background : AppColors.accent,
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, ghost }

/// Button with the web app's three looks, a press-scale animation and haptic tick.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ButtonVariant.secondary,
    this.highlighted = false,
    this.expand = false,
    this.height = kMinTouchTarget,
    this.semanticLabel,
    this.haptic = true,
    this.iconOnly = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;

  /// Accent outline, used for confirmed states like "Copied".
  final bool highlighted;
  final bool expand;
  final double height;
  final String? semanticLabel;
  final bool haptic;

  /// Renders only the icon; [label] becomes the tooltip/semantic label.
  final bool iconOnly;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (widget.variant) {
      ButtonVariant.primary => (
        _pressed ? AppColors.accentPressed : AppColors.accent,
        AppColors.background,
        Colors.transparent,
      ),
      ButtonVariant.secondary => (
        _pressed ? AppColors.surfaceHover : AppColors.surface,
        widget.highlighted ? AppColors.accent : AppColors.textPrimary,
        widget.highlighted ? AppColors.accent : AppColors.border,
      ),
      ButtonVariant.ghost => (
        _pressed ? AppColors.surface : Colors.transparent,
        widget.highlighted ? AppColors.accent : AppColors.textSecondary,
        Colors.transparent,
      ),
    };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) Icon(widget.icon, size: 16, color: fg),
        if (widget.icon != null && !widget.iconOnly) const SizedBox(width: AppSpace.sm),
        if (!widget.iconOnly)
          Flexible(
            // Shrinks a little rather than cutting the label off when space is tight.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                maxLines: 1,
                style: AppText.button.copyWith(
                  color: fg,
                  fontWeight: widget.variant == ButtonVariant.primary ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );

    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: widget.height,
              constraints: BoxConstraints(minWidth: widget.iconOnly ? widget.height : 0),
              padding: EdgeInsets.symmetric(horizontal: widget.iconOnly ? 0 : AppSpace.md),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: border),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    return widget.iconOnly ? Tooltip(message: widget.label, child: button) : button;
  }
}

/// The web app's custom radio indicator: an accent ring with a dot when selected.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected, this.size = 14});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.accent : AppColors.textFaint),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: size * 0.43,
          height: size * 0.43,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Recessed track holding a row of [SegmentOption]s (the web "fieldset" radio groups).
class SegmentTrack extends StatelessWidget {
  const SegmentTrack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.control + 2),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.xs),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class SegmentOption extends StatelessWidget {
  const SegmentOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.label,
    this.icon,
    this.trailing,
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.control - 2),
            border: Border.all(color: selected ? AppColors.borderStrong : Colors.transparent),
          ),
          // Scales down as a unit on narrow screens instead of truncating.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioDot(selected: selected),
                  const SizedBox(width: AppSpace.sm),
                  if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 6)],
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                  ),
                  if (trailing != null) ...[const SizedBox(width: AppSpace.sm), trailing!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}
