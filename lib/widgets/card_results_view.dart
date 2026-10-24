import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/carriers.dart';
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
  bool _added = false;
  String? _shownCardId;

  @override
  Widget build(BuildContext context) {
    final card = widget.controller.card;
    // Reset transient button states when a different card is shown.
    if (card?.id != _shownCardId) {
      _shownCardId = card?.id;
      _copied = false;
      _added = false;
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

  void _addToBatch(ScannedCard card) {
    widget.controller.addToBatch(card);
    setState(() => _added = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added = false);
    });
  }

  Widget _result(ScannedCard card) {
    final format = findFormatById(card.carrierId);

    return GroupedSection(
      header: 'Result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and carrier wrap onto a second line rather than overflow on narrow screens.
              Expanded(
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [StatusPill(card.status), Capsule(card.carrierName)],
                ),
              ),
              if (format != null) ...[
                const SizedBox(width: AppSpace.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(format.pattern, style: AppText.code.copyWith(fontSize: 12, color: AppColors.textMuted)),
                ),
              ],
            ],
          ),
          if (card.errorMessage != null && !card.canDial) ...[
            const SizedBox(height: AppSpace.lg),
            _Notice(message: card.errorMessage!),
          ],
          const SizedBox(height: AppSpace.xl),
          const Text('USSD code', style: AppText.sectionHeader),
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
                    fontFeatures: [FontFeature.tabularFigures()],
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
                    const Text('Voucher PIN', style: AppText.sectionHeader),
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
            label: card.canDial ? 'Dial ${card.carrierName}' : 'Fix PIN to Dial',
            icon: LucideIcons.phoneCall,
            kind: ButtonKind.filled,
            size: ButtonSize.large,
            expand: true,
            haptic: false,
            onPressed: card.canDial ? () => widget.onDial(card) : null,
          ),
          if (card.canDial && !canDialUssd) ...[
            const SizedBox(height: AppSpace.sm),
            const Text(
              "iPhone can't open USSD codes from apps, so Dial copies the code for you to paste in Phone.",
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _copied ? 'Copied' : 'Copy Code',
                  icon: _copied ? LucideIcons.check : LucideIcons.copy,
                  kind: _copied ? ButtonKind.tinted : ButtonKind.gray,
                  expand: true,
                  onPressed: () => _copy(card),
                ),
              ),
              // Batch actions only exist once Batch is on (target of 2 or more).
              if (widget.controller.batchEnabled) ...[
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: AppButton(
                    label: _added ? 'Added' : 'Add to Batch',
                    icon: _added ? LucideIcons.check : LucideIcons.listPlus,
                    kind: _added ? ButtonKind.tinted : ButtonKind.gray,
                    expand: true,
                    onPressed: () => _addToBatch(card),
                  ),
                ),
              ],
            ],
          ),
        ],
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
                  ? const TextStyle(
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
      style: const TextStyle(
        fontFamily: kDisplayFamily,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
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
            const Padding(
              padding: EdgeInsets.only(top: 1),
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
