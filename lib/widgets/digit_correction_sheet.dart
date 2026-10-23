import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../services/pin_parser.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Bottom sheet with the 4×4 digit grid and keypad. Cancel discards edits.
class DigitCorrectionSheet extends StatefulWidget {
  const DigitCorrectionSheet({super.key, required this.card, required this.onSave});

  final ScannedCard card;
  final ValueChanged<String> onSave;

  static Future<void> show(BuildContext context, AppController controller, ScannedCard card) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
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
    // Start on the least certain digit (e.g. a scratched one).
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Semantics(header: true, child: const Text('Edit PIN', style: AppText.title)),
                const Spacer(),
                Text(
                  'Digit ${_selected + 1} of $kPinLength',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var block = 0; block < 4; block++) ...[
                  if (block > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          for (var sub = 0; sub < 4; sub++) ...[
                            if (sub > 0) const SizedBox(width: 2),
                            Expanded(child: _digitCell(block * 4 + sub, lowConfidence)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Inset(
              padding: const EdgeInsets.all(8),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.4,
                children: [
                  for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) _Key(label: n, onTap: () => _press(n)),
                  _Key(label: 'C', semanticLabel: 'Clear digit', muted: true, onTap: _clear),
                  _Key(label: '0', onTap: () => _press('0')),
                  _Key(icon: LucideIcons.delete, semanticLabel: 'Backspace', accent: true, onTap: _backspace),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(label: 'Cancel', expand: true, onPressed: () => Navigator.of(context).pop()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Save',
                    variant: ButtonVariant.primary,
                    expand: true,
                    haptic: false,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          duration: const Duration(milliseconds: 120),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border(
              bottom: BorderSide(color: flagged && !selected ? AppColors.accent : Colors.transparent, width: 2),
            ),
          ),
          child: Text(
            _digits[i],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.background : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({this.label, this.icon, this.semanticLabel, required this.onTap, this.muted = false, this.accent = false});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool muted;
  final bool accent;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final fg = _down
        ? AppColors.background
        : widget.accent
        ? AppColors.accent
        : widget.muted
        ? AppColors.textSecondary
        : AppColors.textPrimary;
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
          duration: const Duration(milliseconds: 80),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _down ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(7),
          ),
          child: widget.icon != null
              ? Icon(widget.icon, size: 18, color: fg)
              : Text(
                  widget.label!,
                  style: TextStyle(fontSize: widget.muted ? 13 : 17, fontWeight: FontWeight.w600, color: fg),
                ),
        ),
      ),
    );
  }
}
