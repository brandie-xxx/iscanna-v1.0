import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../services/dialer.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'digit_correction_sheet.dart';

/// Result section: status, USSD code readout, PIN with Edit, and Dial / Copy / Add to Batch.
class CardResultsView extends StatefulWidget {
  const CardResultsView({super.key, required this.controller, required this.onDial});

  final AppController controller;
  final Future<void> Function(ScannedCard card) onDial;

  @override
  State<CardResultsView> createState() => _CardResultsViewState();
}

class _CardResultsViewState extends State<CardResultsView> {
  bool _copied = false;
  String? _shownCardId;

  @override
  Widget build(BuildContext context) {
    final card = widget.controller.card;
    // Reset transient button states when a different card is shown.
    if (card?.id != _shownCardId) {
      _shownCardId = card?.id;
      _copied = false;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: card == null
          ? _EmptyResult(key: ValueKey(widget.controller.scanError), error: widget.controller.scanError)
          : KeyedSubtree(key: ValueKey(card.id), child: _result(card)),
    );
  }

  Future<void> _copy(ScannedCard card) async {
    final ok = await copyToClipboard(card.wrappedPin);
    if (!mounted) return;
    if (!ok) {
      showToast(context, 'Copy failed');
      return;
    }
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Widget _result(ScannedCard card) {
    final queued = widget.controller.isQueued(card);

    return GroupedSection(
      header: 'Result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carrier on the left, status on the right.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Capsule(card.carrierName)),
              const SizedBox(width: AppSpace.sm),
              StatusPill(card.status),
            ],
          ),
          if (card.errorMessage != null && !card.canDial) ...[
            const SizedBox(height: AppSpace.lg),
            _Notice(message: card.errorMessage!),
          ],
          const SizedBox(height: AppSpace.xl),
          Text('USSD code', style: AppText.sectionHeader),
          const SizedBox(height: AppSpace.md),
          Semantics(
            label: 'USSD code ${card.wrappedPin.split('').join(' ')}',
            excludeSemantics: true,
            // Always shows the whole code: shrinks to fit instead of wrapping or cutting.
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  card.wrappedPin,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: kDisplayFamily,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 24,
                    letterSpacing: 1,
                    color: card.canDial ? AppColors.accent : AppColors.textSecondary,
                    shadows: card.canDial
                        ? [Shadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          const Hairline(),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voucher PIN', style: AppText.sectionHeader),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _PinText(card: card),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              AppButton(
                label: 'Edit',
                icon: LucideIcons.penLine,
                kind: ButtonKind.tinted,
                size: ButtonSize.small,
                semanticLabel: 'Edit PIN digits',
                onPressed: () => DigitCorrectionSheet.show(context, widget.controller, card),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            label: 'Dial',
            icon: LucideIcons.phoneCall,
            kind: ButtonKind.filled,
            size: ButtonSize.large,
            expand: true,
            haptic: false,
            onPressed: card.canDial ? () => widget.onDial(card) : null,
          ),
          if (card.canDial && !canDialUssd) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              "This phone can't open USSD codes from apps, so Dial copies the code for you to paste in the Phone app.",
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
          const SizedBox(height: AppSpace.md),
          // Copy Code and Add to Batch share the row. Once the card is in the batch, Add to Batch folds
          // into a round green check and Copy Code widens to take the space.
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpace.md;
              final height = ButtonSize.medium.height;
              final half = (constraints.maxWidth - gap) / 2;
              return TweenAnimationBuilder<double>(
                tween: Tween(end: queued ? 1 : 0),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOutCubicEmphasized,
                builder: (context, t, _) {
                  final addWidth = lerpDouble(half, height, t)!;
                  return Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth - gap - addWidth,
                        child: AppButton(
                          label: _copied ? 'Copied' : 'Copy Code',
                          icon: _copied ? LucideIcons.check : LucideIcons.copy,
                          kind: _copied ? ButtonKind.tinted : ButtonKind.gray,
                          expand: true,
                          onPressed: () => _copy(card),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: addWidth,
                        // Greyed out until Batch is on (target of 2 or more); a tap then says how.
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: queued || widget.controller.batchEnabled
                              ? null
                              : () => showToast(context, 'Set Cards to scan to 2 or more to use Batch.'),
                          child: _AddToBatchButton(
                            progress: t,
                            fullWidth: half,
                            enabled: widget.controller.batchEnabled,
                            onPressed: queued ? null : () => widget.controller.addToBatch(card),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Add to Batch, folding into a round green check as [progress] runs from 0 (not queued) to 1 (queued).
/// The label fades out in the first third of the fold as the check grows in, so the button is never empty.
class _AddToBatchButton extends StatelessWidget {
  const _AddToBatchButton({
    required this.progress,
    required this.fullWidth,
    required this.enabled,
    required this.onPressed,
  });

  final double progress;

  /// Width of the unfolded button, so the label keeps its layout while the button narrows.
  final double fullWidth;

  /// Batch is on (Cards to scan is 2 or more).
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final height = ButtonSize.medium.height;
    final labelOpacity = Curves.easeOut.transform((1 - t / 0.3).clamp(0.0, 1.0));
    final checkIn = Curves.easeOutBack.transform(((t - 0.3) / 0.7).clamp(0.0, 1.0));
    // Blend between opaque colours so the fill shifts hue cleanly instead of darkening mid-way.
    final greenFill = Color.alphaBlend(AppColors.success.withValues(alpha: 0.16), AppColors.panel);
    final labelColor = enabled ? AppColors.textPrimary : AppColors.textFaint;
    final added = t > 0.5;

    return Semantics(
      button: true,
      enabled: onPressed != null && enabled,
      label: added ? 'Added to batch' : 'Add to Batch',
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.surface, greenFill, t),
            borderRadius: BorderRadius.circular(lerpDouble(AppRadius.control, height / 2, t)!),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (labelOpacity > 0)
                Opacity(
                  opacity: labelOpacity,
                  // Laid out at full width and clipped, so the label never squashes as the button folds.
                  child: OverflowBox(
                    minWidth: fullWidth,
                    maxWidth: fullWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.listPlus, size: ButtonSize.medium.fontSize + 2, color: labelColor),
                          const SizedBox(width: AppSpace.sm),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Add to Batch',
                                maxLines: 1,
                                style: AppText.button.copyWith(fontSize: ButtonSize.medium.fontSize, color: labelColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (checkIn > 0)
                Opacity(
                  opacity: checkIn.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * checkIn,
                    child: Icon(LucideIcons.check, size: 20, color: AppColors.success),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PIN in 4-digit groups; digits the scan couldn't read are highlighted so they're easy to spot.
class _PinText extends StatelessWidget {
  const _PinText({required this.card});

  final ScannedCard card;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final d in card.digits) ...[
            if (d.index > 0 && d.index % 4 == 0) const TextSpan(text: '  '),
            TextSpan(
              text: d.char,
              style: d.isLowConfidence
                  ? TextStyle(
                      color: AppColors.warning,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.warning,
                      decorationThickness: 2,
                    )
                  : null,
            ),
          ],
        ],
      ),
      semanticsLabel: 'PIN ${card.rawPin.split('').join(' ')}',
      style: TextStyle(
        fontFamily: kDisplayFamily,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 16,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.control - 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.warning),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: AppText.footnote.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    return GroupedSection(
      header: 'Result',
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xxl),
      child: Column(
        children: [
          Icon(
            failed ? LucideIcons.circleAlert : LucideIcons.fileScan,
            size: 28,
            color: failed ? AppColors.warning : AppColors.textFaint,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(failed ? 'Scan Failed' : 'No Card Yet', style: AppText.headline.copyWith(fontSize: 14.5)),
          const SizedBox(height: AppSpace.sm),
          Semantics(
            liveRegion: failed,
            child: Text(
              error ?? 'The PIN and its dial code will appear here after a scan.',
              textAlign: TextAlign.center,
              style: AppText.footnote,
            ),
          ),
        ],
      ),
    );
  }
}
