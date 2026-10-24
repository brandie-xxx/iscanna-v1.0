import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
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
import '../widgets/common.dart';
import '../widgets/digit_correction_sheet.dart';
import '../widgets/screen_header.dart';

/// Batch tab: queued cards (tap for actions, swipe to delete), export, and Clear in the nav bar.
class BatchTab extends StatefulWidget {
  const BatchTab({super.key, required this.controller, required this.onDial});

  final AppController controller;
  final Future<void> Function(ScannedCard card) onDial;

  @override
  State<BatchTab> createState() => _BatchTabState();
}

class _BatchTabState extends State<BatchTab> {
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
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${exportFileName(_format, DateTime.now())}');
      await file.writeAsString(buildExport(_app.batch, _format));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: _format.mimeType)],
          subject: 'iscanna1.0 batch export',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) showToast(context, 'Export failed');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmClear() async {
    final count = _app.batch.length;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear Batch?', style: TextStyle(fontFamily: kFontFamily)),
        content: Text(
          'This removes all $count ${count == 1 ? 'card' : 'cards'} from the queue.',
          style: const TextStyle(fontFamily: kFontFamily),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: kButtonFamily)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(fontFamily: kButtonFamily)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      unawaited(HapticFeedback.mediumImpact());
      _app.clearBatch();
    }
  }

  void _remove(ScannedCard card) {
    _app.removeFromBatch(card.id);
    showToast(
      context,
      'Card removed',
      action: SnackBarAction(label: 'Undo', onPressed: () => _app.addToBatch(card)),
    );
  }

  Future<void> _copy(ScannedCard card) async {
    final ok = await copyToClipboard(card.wrappedPin);
    if (mounted) showToast(context, ok ? 'Code copied' : 'Copy failed');
  }

  Future<void> _showActions(ScannedCard card) async {
    unawaited(HapticFeedback.selectionClick());
    if (!mounted) return;
    const action = TextStyle(fontFamily: kButtonFamily, fontSize: 16.5, fontWeight: FontWeight.w600);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          card.wrappedPin,
          style: const TextStyle(
            fontFamily: kDisplayFamily,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        message: Text(
          '${card.carrierName} · ${card.formattedPin}',
          style: const TextStyle(fontFamily: kFontFamily, fontSize: 12.5),
        ),
        actions: [
          if (card.canDial)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDial(card);
              },
              child: Text('Dial ${card.carrierName}', style: action),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _copy(card);
            },
            child: const Text('Copy Code', style: action),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              DigitCorrectionSheet.show(context, _app, card);
            },
            child: const Text('Edit PIN', style: action),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _remove(card);
            },
            child: const Text('Remove from Batch', style: action),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(fontFamily: kButtonFamily, fontSize: 16.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _app.batch;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        ScreenHeader(
          title: 'Batch',
          leading: const BrandMark(),
          trailing: cards.isEmpty
              ? null
              : CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                  onPressed: _confirmClear,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: kButtonFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
          sliver: SliverList.list(
            children: [
              if (cards.isEmpty)
                _EmptyBatch(onScan: () => _app.selectTab(AppTab.scanner))
              else ...[
                GroupedSection(
                  header: 'Queued',
                  headerTrailing: Text(
                    '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                    style: AppText.readout,
                  ),
                  footer: 'Tap a card for actions. Swipe left to remove.',
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.panel),
                    child: Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const Hairline(indent: 64),
                          _BatchRow(
                            key: ValueKey(cards[i].id),
                            index: i,
                            card: cards[i],
                            onTap: () => _showActions(cards[i]),
                            onRemove: () => _remove(cards[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.section),
                // Export sits directly on the page: no card, just the format row and actions.
                const Padding(
                  padding: EdgeInsets.only(left: AppSpace.lg, bottom: AppSpace.md),
                  child: Text('Export', style: AppText.sectionHeader),
                ),
                _FormatRow(value: _format, onChanged: (f) => setState(() => _format = f)),
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _copiedAll ? 'Copied' : 'Copy All',
                        icon: _copiedAll ? LucideIcons.check : LucideIcons.copy,
                        kind: _copiedAll ? ButtonKind.tinted : ButtonKind.gray,
                        expand: true,
                        onPressed: _copyAll,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Builder(
                        builder: (btnContext) => AppButton(
                          label: _exporting ? 'Exporting…' : 'Export',
                          icon: LucideIcons.share,
                          kind: ButtonKind.filled,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
                  child: Text(
                    'Export opens the share sheet so you can save or send the file.',
                    style: AppText.footnote,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Credit sits at the very bottom of the page, however short the content.
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              child: const AuthorFooter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({super.key, required this.index, required this.card, required this.onTap, required this.onRemove});

  final int index;
  final ScannedCard card;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${card.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                fontFamily: kButtonFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      child: Semantics(
        button: true,
        label: '${card.carrierName} card ${index + 1}${card.canDial ? '' : ', needs review'}. Opens actions',
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.99,
          haptic: false,
          child: ColoredBox(
            color: AppColors.panel,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.lg),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: card.canDial
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: kDisplayFamily,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 10.5,
                        color: card.canDial ? AppColors.accent : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The whole code is always visible: it shrinks to fit rather than being cut off.
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              card.wrappedPin,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: kDisplayFamily,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: card.carrierName),
                              if (!card.canDial) ...[
                                const TextSpan(text: '  ·  '),
                                const TextSpan(
                                  text: 'Review',
                                  style: TextStyle(color: AppColors.warning),
                                ),
                              ],
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.footnote,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBatch extends StatelessWidget {
  const _EmptyBatch({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxxl * 2),
      child: Column(
        children: [
          const Text('No Cards Yet', style: AppText.headline),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.xxl),
            child: Text(
              'Verified scans join the batch automatically, ready to dial, copy or export.',
              textAlign: TextAlign.center,
              style: AppText.callout,
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          AppButton(label: 'Start Scanning', icon: LucideIcons.scanLine, kind: ButtonKind.tinted, onPressed: onScan),
        ],
      ),
    );
  }
}

/// Export format choice: plain labels divided by thin separators, no surrounding box.
class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.value, required this.onChanged});

  final ExportFormat value;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    const formats = ExportFormat.values;
    return SizedBox(
      height: kMinTouchTarget,
      child: Row(
        children: [
          for (var i = 0; i < formats.length; i++) ...[
            if (i > 0) const SizedBox(width: 1, height: 18, child: ColoredBox(color: AppColors.borderStrong)),
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: formats[i] == value,
                button: true,
                label: 'Export as ${formats[i].extension}',
                excludeSemantics: true,
                child: Pressable(
                  onTap: formats[i] == value ? null : () => onChanged(formats[i]),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 13.5,
                        fontWeight: formats[i] == value ? FontWeight.w700 : FontWeight.w500,
                        color: formats[i] == value ? AppColors.accent : AppColors.textMuted,
                      ),
                      child: Text(formats[i].extension.toUpperCase()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
