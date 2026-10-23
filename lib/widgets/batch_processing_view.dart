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
                : AppButton(label: 'Clear', icon: LucideIcons.trash2, height: 36, onPressed: _confirmClear),
          ),
          if (cards.isEmpty)
            _EmptyQueue(onScan: () => _app.selectTab(AppTab.scanner))
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('FORMAT', style: AppText.label),
                  const SizedBox(width: 8),
                  Expanded(
                    // Scale down rather than overflow on narrow screens / large text.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final f in ExportFormat.values)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _FormatOption(
                                format: f,
                                selected: f == _format,
                                onTap: () => setState(() => _format = f),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _copiedAll ? 'Copied All' : 'Copy All',
                    icon: _copiedAll ? LucideIcons.check : LucideIcons.copy,
                    highlighted: _copiedAll,
                    expand: true,
                    onPressed: _copyAll,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (btnContext) => AppButton(
                      label: _exporting ? 'Exporting…' : 'Export ${_format.extension.toUpperCase()}',
                      icon: LucideIcons.share2,
                      variant: ButtonVariant.primary,
                      expand: true,
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
    return Dismissible(
      key: ValueKey('dismiss-${card.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: AppColors.surface,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, size: 18, color: AppColors.accent),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.wrappedPin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.carrierName} • ${card.formattedPin}${card.canDial ? '' : ' • needs review'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            AppButton(
              label: card.canDial ? 'Dial voucher' : 'Review PIN before dialing',
              icon: LucideIcons.phoneCall,
              variant: ButtonVariant.ghost,
              highlighted: true,
              iconOnly: true,
              height: 40,
              haptic: false,
              onPressed: card.canDial ? onDial : null,
            ),
            AppButton(
              label: 'Edit digits',
              icon: LucideIcons.penLine,
              variant: ButtonVariant.ghost,
              iconOnly: true,
              height: 40,
              onPressed: onEdit,
            ),
            AppButton(
              label: 'Remove',
              icon: LucideIcons.trash2,
              variant: ButtonVariant.ghost,
              iconOnly: true,
              height: 40,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({required this.format, required this.selected, required this.onTap});

  final ExportFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: 'Export as ${format.extension}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: selected ? AppColors.borderStrong : Colors.transparent),
          ),
          child: Row(
            children: [
              RadioDot(selected: selected, size: 10),
              const SizedBox(width: 6),
              Text(
                format.extension.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          const Text('Queue Empty', style: AppText.title),
          const SizedBox(height: 4),
          const Text(
            'Scan recharge vouchers to queue them for batch copying or spreadsheet export.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Scan Cards', icon: LucideIcons.plus, variant: ButtonVariant.primary, onPressed: onScan),
        ],
      ),
    );
  }
}
