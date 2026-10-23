import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/carriers.dart';
import '../models/models.dart';
import '../services/dialer.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'digit_correction_sheet.dart';

/// "Scanned Card" panel: status, wrapped USSD code, PIN, and Dial / Copy / Batch actions.
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
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
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
    final statusLabel = switch (card.status) {
      CardStatus.success => 'Verified',
      CardStatus.warning => 'Review Needed',
      CardStatus.error => 'Unreadable',
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Scanned Card',
            leadingBadge: Tag(card.carrierName),
            trailing: Tag(statusLabel, soft: true),
          ),
          if (card.errorMessage != null && !card.canDial) ...[
            _Notice(icon: LucideIcons.circleAlert, message: card.errorMessage!),
            const SizedBox(height: 12),
          ],
          Inset(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('USSD RECHARGE CODE (${card.carrierName.toUpperCase()})', style: AppText.label),
                    ),
                    if (format != null)
                      Text(format.pattern, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: 'USSD code ${card.wrappedPin.split('').join(' ')}',
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      card.wrappedPin,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 1.6,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Inset(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('16-DIGIT VOUCHER PIN', style: AppText.label),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _PinText(card: card),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Edit',
                  icon: LucideIcons.penLine,
                  highlighted: true,
                  height: 38,
                  semanticLabel: 'Edit PIN digits',
                  onPressed: () => DigitCorrectionSheet.show(context, widget.controller, card),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: card.canDial ? 'Dial Code (${card.carrierName})' : 'Review PIN to Dial',
            icon: LucideIcons.phoneCall,
            variant: ButtonVariant.primary,
            expand: true,
            height: 48,
            haptic: false,
            onPressed: card.canDial ? () => widget.onDial(card) : null,
          ),
          if (card.canDial && !canDialUssd) ...[
            const SizedBox(height: 6),
            const Text(
              'iPhone can\'t open USSD codes from apps. Dial copies the code: paste it in Phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _copied ? 'Copied' : 'Copy Code',
                  icon: _copied ? LucideIcons.check : LucideIcons.copy,
                  highlighted: _copied,
                  expand: true,
                  onPressed: () => _copy(card),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: _added ? 'Added' : 'Batch Queue',
                  icon: _added ? LucideIcons.check : LucideIcons.plus,
                  variant: ButtonVariant.secondary,
                  highlighted: _added,
                  expand: true,
                  semanticLabel: 'Add to batch queue',
                  onPressed: () => _addToBatch(card),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// PIN in 4-digit groups; low-confidence digits are underlined so they're easy to spot.
class _PinText extends StatelessWidget {
  const _PinText({required this.card});

  final ScannedCard card;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final d in card.digits) ...[
            if (d.index > 0 && d.index % 4 == 0) const TextSpan(text: ' '),
            TextSpan(
              text: d.char,
              style: d.isLowConfidence
                  ? const TextStyle(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                      decorationThickness: 2,
                    )
                  : null,
            ),
          ],
        ],
      ),
      semanticsLabel: 'PIN ${card.rawPin.split('').join(' ')}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Inset(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              error != null ? LucideIcons.circleAlert : LucideIcons.penLine,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(error != null ? 'Scan Failed' : 'Awaiting Voucher Card', style: AppText.title),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: error != null,
            child: Text(
              error ?? 'Position a NetOne or Econet card in frame, upload a photo, or tap a preset above.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}
