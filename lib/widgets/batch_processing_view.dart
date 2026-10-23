import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/batch_export.dart';
import '../services/dialer.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'digit_correction_sheet.dart';

/// "Batch Queue" tab: list, per-card actions, copy all, and CSV/JSON/TXT export.
class BatchProcessingView extends StatefulWidget {
  const BatchProcessingView({super.key, required this.controller, required this.onDial});

  final AppController controller;
  final Future<void> Function(ScannedCard card) onDial;

  @override
  State<BatchProcessingView> createState() => _BatchProcessingViewState();
}

class _BatchProcessingViewState extends State<BatchProcessingView> {
  ExportFormat _format = ExportFormat.csv;
  bool _copiedAll = false;
  bool _exporting = false;

  AppController get _app => widget.controller;

  Future<void> _copyAll() async {
    final ok = await copyToClipboard(_app.batch.map((c) => c.wrappedPin).join('\n'));
    if (!mounted) return;
    if (!ok) {
      showToast(context, 'Copy failed');
      return;
    }
    setState(() => _copiedAll = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedAll = false);
    });
  }

  Future<void> _export(Rect? origin) async {
    setState(() => _exporting = true);
    try {
      final now = DateTime.now();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${exportFileName(_format, now)}');
      await file.writeAsString(buildExport(_app.batch, _format));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: _format.mimeType)],
          subject: 'iscanna1.0 batch export',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) showToast(context, 'Export failed');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.panel),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Clear queue?', style: AppText.title),
        content: Text('Remove all ${_app.batch.length} cards from the batch.', style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await HapticFeedback.mediumImpact();
      _app.clearBatch();
    }
  }

  void _remove(ScannedCard card) {
    _app.removeFromBatch(card.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Card removed'),
          action: SnackBarAction(label: 'Undo', textColor: AppColors.accent, onPressed: () => _app.addToBatch(card)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _app.batch;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Batch Queue',
            leadingBadge: Tag('${cards.length}'),
            trailing: cards.isEmpty
                ? null
                : AppButton(label: 'Clear', icon: LucideIcons.trash2, height: 40, onPressed: _confirmClear),
          ),
          if (cards.isEmpty)
            _EmptyQueue(onScan: () => _app.selectTab(AppTab.scanner))
          else ...[
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.sm),
              _BatchRow(
                key: ValueKey(cards[i].id),
                index: i,
                card: cards[i],
                onDial: () => widget.onDial(cards[i]),
                onEdit: () {
                  _app.focusCard(cards[i]);
                  DigitCorrectionSheet.show(context, _app, cards[i]);
                },
                onRemove: () => _remove(cards[i]),
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            const SectionLabel('Export format'),
            SegmentTrack(
              children: [
                for (final f in ExportFormat.values)
                  SegmentOption(
                    selected: f == _format,
                    label: f.extension.toUpperCase(),
                    semanticLabel: 'Export as ${f.extension}',
                    onTap: () => setState(() => _format = f),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _copiedAll ? 'Copied All' : 'Copy All',
                    icon: _copiedAll ? LucideIcons.check : LucideIcons.copy,
                    highlighted: _copiedAll,
                    expand: true,
                    height: 48,
                    onPressed: _copyAll,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Builder(
                    builder: (btnContext) => AppButton(
                      label: _exporting ? 'Exporting…' : 'Export ${_format.extension.toUpperCase()}',
                      icon: LucideIcons.share2,
                      variant: ButtonVariant.primary,
                      expand: true,
                      height: 48,
                      onPressed: _exporting
                          ? null
                          : () {
                              // iPad share sheets need an anchor rect.
                              final box = btnContext.findRenderObject() as RenderBox?;
                              final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
                              _export(origin);
                            },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One queued card: header row with number, carrier and actions; then the full USSD code and PIN.
class _BatchRow extends StatelessWidget {
  const _BatchRow({
    super.key,
    required this.index,
    required this.card,
    required this.onDial,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final ScannedCard card;
  final VoidCallback onDial;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.control);
    return Dismissible(
      key: ValueKey('dismiss-${card.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: radius),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        child: const Icon(LucideIcons.trash2, size: 18, color: AppColors.accent),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: radius,
          border: Border.all(color: card.canDial ? AppColors.border : AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(child: Tag(card.carrierName)),
                      if (!card.canDial) ...[
                        const SizedBox(width: 6),
                        const Flexible(child: Tag('Review', soft: true)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                AppButton(
                  label: card.canDial ? 'Dial voucher' : 'Fix PIN before dialing',
                  icon: LucideIcons.phoneCall,
                  variant: ButtonVariant.ghost,
                  highlighted: true,
                  iconOnly: true,
                  haptic: false,
                  onPressed: card.canDial ? onDial : null,
                ),
                AppButton(
                  label: 'Edit digits',
                  icon: LucideIcons.penLine,
                  variant: ButtonVariant.ghost,
                  iconOnly: true,
                  onPressed: onEdit,
                ),
                AppButton(
                  label: 'Remove',
                  icon: LucideIcons.trash2,
                  variant: ButtonVariant.ghost,
                  iconOnly: true,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              // The whole code is always visible: it shrinks to fit rather than being cut off.
              child: SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card.wrappedPin,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              card.formattedPin,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Inset(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: 36),
      child: Column(
        children: [
          const Text('Queue Empty', style: AppText.title),
          const SizedBox(height: AppSpace.sm),
          const Text(
            'Scan recharge vouchers to queue them for batch copying or spreadsheet export.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(label: 'Scan Cards', icon: LucideIcons.plus, variant: ButtonVariant.primary, onPressed: onScan),
        ],
      ),
    );
  }
}
