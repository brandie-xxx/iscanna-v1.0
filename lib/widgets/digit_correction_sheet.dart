import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../services/pin_parser.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// iOS-style sheet: Cancel · Edit PIN · Save, the 16 digit cells, and a keypad. Cancel discards edits.
class DigitCorrectionSheet extends StatefulWidget {
  const DigitCorrectionSheet({super.key, required this.card, required this.onSave});

  final ScannedCard card;
  final ValueChanged<String> onSave;

  static Future<void> show(BuildContext context, AppController controller, ScannedCard card) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.panel + 4)),
      ),
      builder: (_) => DigitCorrectionSheet(card: card, onSave: (pin) => controller.saveCorrection(card, pin)),
    );
  }

  @override
  State<DigitCorrectionSheet> createState() => _DigitCorrectionSheetState();
}

class _DigitCorrectionSheetState extends State<DigitCorrectionSheet> {
  late final List<String> _digits;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _digits = widget.card.rawPin.padRight(kPinLength, '0').substring(0, kPinLength).split('');
    // Start on the least certain digit (e.g. one the scan couldn't read).
    final digits = widget.card.digits;
    _selected = digits.isEmpty ? 0 : digits.reduce((a, b) => b.confidence < a.confidence ? b : a).index;
  }

  void _press(String n) {
    HapticFeedback.selectionClick();
    setState(() {
      _digits[_selected] = n;
      if (_selected < kPinLength - 1) _selected++;
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _digits[_selected] = '0';
      if (_selected > 0) _selected--;
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() => _digits[_selected] = '0');
  }

  void _save() {
    HapticFeedback.mediumImpact();
    widget.onSave(_digits.join());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lowConfidence = {
      for (final d in widget.card.digits)
        if (d.isLowConfidence) d.index,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: kMinTouchTarget,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: 'Cancel',
                        kind: ButtonKind.plain,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Semantics(header: true, child: const Text('Edit PIN', style: AppText.headline)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(label: 'Save', kind: ButtonKind.plain, haptic: false, onPressed: _save),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Center(child: Text('Digit ${_selected + 1} of $kPinLength', style: AppText.readout)),
            const SizedBox(height: AppSpace.md),
            // One row of 4 groups when each digit has room; otherwise two rows of 2 groups.
            LayoutBuilder(
              builder: (context, constraints) {
                final minDigitWidth = MediaQuery.textScalerOf(context).scale(22);
                final groupsPerRow = constraints.maxWidth / kPinLength >= minDigitWidth ? 4 : 2;
                return Column(
                  children: [
                    for (var row = 0; row < 4 ~/ groupsPerRow; row++) ...[
                      if (row > 0) const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          for (var g = 0; g < groupsPerRow; g++) ...[
                            if (g > 0) const SizedBox(width: AppSpace.sm),
                            Expanded(child: _group(row * groupsPerRow + g, lowConfidence)),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpace.xl),
            // Phone-style keypad: round number keys, plain icons for clear and backspace.
            for (final row in [
              [
                for (final n in ['1', '2', '3']) _Key(label: n, onTap: () => _press(n)),
              ],
              [
                for (final n in ['4', '5', '6']) _Key(label: n, onTap: () => _press(n)),
              ],
              [
                for (final n in ['7', '8', '9']) _Key(label: n, onTap: () => _press(n)),
              ],
              [
                _Key(icon: LucideIcons.eraser, semanticLabel: 'Clear digit', muted: true, onTap: _clear),
                _Key(label: '0', onTap: () => _press('0')),
                _Key(icon: LucideIcons.delete, semanticLabel: 'Backspace', muted: true, onTap: _backspace),
              ],
            ]) ...[
              Row(
                children: [for (final key in row) Expanded(child: Center(child: key))],
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ],
        ),
      ),
    );
  }

  Widget _group(int block, Set<int> lowConfidence) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      color: AppColors.inset,
      child: Row(
        children: [
          for (var sub = 0; sub < 4; sub++) ...[
            if (sub > 0) const SizedBox(width: 3),
            Expanded(child: _digitCell(block * 4 + sub, lowConfidence)),
          ],
        ],
      ),
    );
  }

  Widget _digitCell(int i, Set<int> lowConfidence) {
    final selected = i == _selected;
    final flagged = lowConfidence.contains(i);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Digit ${i + 1}: ${_digits[i]}${flagged ? ', needs review' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selected = i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 46,
          alignment: Alignment.center,
          // Sharp, square-cornered digit boxes.
          decoration: BoxDecoration(color: selected ? AppColors.accent : AppColors.surface),
          child: Text(
            _digits[i],
            style: TextStyle(
              fontFamily: kDisplayFamily,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              fontSize: 16,
              color: selected
                  ? AppColors.background
                  : flagged
                  ? AppColors.warning
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({this.label, this.icon, this.semanticLabel, required this.onTap, this.muted = false});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool muted;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.muted ? AppColors.textSecondary : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _down
                ? AppColors.surfaceHover
                : widget.muted
                ? Colors.transparent
                : AppColors.surface,
          ),
          child: widget.icon != null
              ? Icon(widget.icon, size: 22, color: fg)
              : Text(
                  widget.label!,
                  style: TextStyle(fontFamily: kButtonFamily, fontSize: 21, fontWeight: FontWeight.w600, color: fg),
                ),
        ),
      ),
    );
  }
}
