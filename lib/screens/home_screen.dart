import 'dart:async';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../services/dialer.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'batch_tab.dart';
import 'scan_tab.dart';

/// App shell: Scan / Batch tabs behind a translucent bottom tab bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 600));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Celebration ONLY when handing a code to the dialer (never on scan).
  Future<void> _dial(ScannedCard card) async {
    if (!canDialUssd) {
      final ok = await copyToClipboard(card.wrappedPin);
      if (mounted) showToast(context, ok ? 'Code copied. Paste it in the Phone app to dial.' : 'Copy failed');
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    _confetti.play();
    final opened = await openDialer(card.wrappedPin);
    if (mounted && !opened) showToast(context, "Couldn't open the dialer. Copy the code and dial manually.");
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kSystemUiStyle,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => Scaffold(
          // Content scrolls under the translucent tab bar.
          extendBody: true,
          body: Stack(
            children: [
              // Switching tabs disposes the other tab, which also releases the camera.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                child: app.tab == AppTab.scanner
                    ? ScanTab(key: const ValueKey('scan'), controller: app, onDial: _dial)
                    : BatchTab(key: const ValueKey('batch'), controller: app, onDial: _dial),
              ),
              Align(
                alignment: const Alignment(0, 0.2),
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  emissionFrequency: 0.6,
                  gravity: 0.25,
                  colors: const [
                    AppColors.accent,
                    AppColors.accentPressed,
                    AppColors.accentSoft,
                    AppColors.textPrimary,
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _TabBar(
            current: app.tab,
            batchCount: app.batch.length,
            batchEnabled: app.batchEnabled,
            onSelect: app.selectTab,
            onBatchLocked: () =>
                showToast(context, 'Set Cards to scan to 2 or more on the Scan screen to turn on Batch.'),
          ),
        ),
      ),
    );
  }
}

/// Frosted HIG tab bar with icon + label items and a count badge on Batch.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.batchCount,
    required this.batchEnabled,
    required this.onSelect,
    required this.onBatchLocked,
  });

  final AppTab current;
  final int batchCount;

  /// Batch stays greyed out until the target is 2 or more.
  final bool batchEnabled;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onBatchLocked;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _TabItem(
                    icon: LucideIcons.scanLine,
                    label: 'Scan',
                    selected: current == AppTab.scanner,
                    onTap: () => onSelect(AppTab.scanner),
                  ),
                  _TabItem(
                    icon: LucideIcons.menu,
                    label: 'Batch',
                    badge: batchEnabled ? batchCount : 0,
                    selected: current == AppTab.batch,
                    enabled: batchEnabled,
                    onTap: batchEnabled ? () => onSelect(AppTab.batch) : onBatchLocked,
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accent
        : enabled
        ? AppColors.textMuted
        : AppColors.textFaint.withValues(alpha: 0.6);
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: !enabled
            ? '$label, off. Set 2 or more cards to scan to turn on'
            : badge > 0
            ? '$label, $badge queued'
            : label,
        excludeSemantics: true,
        child: Pressable(
          onTap: selected ? null : onTap,
          pressedScale: 0.92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, size: 24, color: color),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -12,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            fontFamily: kButtonFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kButtonFamily,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
