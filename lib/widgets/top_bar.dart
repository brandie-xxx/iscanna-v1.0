import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/carriers.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Minimal brand header: ● iscanna1.0
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpace.sm),
                Semantics(
                  header: true,
                  label: 'iscanna 1.0',
                  excludeSemantics: true,
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'iscanna',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        TextSpan(
                          text: '1.0',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode (Scan / Batch) switch, followed by the carrier (NetOne / Econet) choice.
class NavigationControlBar extends StatelessWidget {
  const NavigationControlBar({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final batchCount = controller.batch.length;
    final onBatch = controller.tab == AppTab.batch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentTrack(
          children: [
            SegmentOption(
              selected: !onBatch,
              label: 'Scan',
              icon: LucideIcons.camera,
              onTap: () => controller.selectTab(AppTab.scanner),
            ),
            SegmentOption(
              selected: onBatch,
              label: 'Batch',
              icon: LucideIcons.layers,
              semanticLabel: 'Batch, $batchCount queued',
              trailing: batchCount > 0 ? _CountBubble(count: batchCount, active: onBatch) : null,
              onTap: () => controller.selectTab(AppTab.batch),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        const SectionLabel('Carrier'),
        SegmentTrack(
          children: [
            for (final fmt in kCarrierFormats)
              SegmentOption(
                selected: controller.format.id == fmt.id,
                label: fmt.name,
                semanticLabel: '${fmt.name} format ${fmt.pattern}',
                trailing: Text(fmt.prefix, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onTap: () => controller.selectFormat(fmt),
              ),
          ],
        ),
      ],
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.background : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Labelled row of equal-width chips that load a drawn sample card.
class SampleCardSelector extends StatelessWidget {
  const SampleCardSelector({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Try a sample card'),
        Row(
          children: [
            for (var i = 0; i < kSampleScenarios.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: SampleChip(
                  selected: controller.activeSampleId == kSampleScenarios[i].id,
                  label: kSampleScenarios[i].title,
                  semanticLabel: 'Sample: ${kSampleScenarios[i].title}. ${kSampleScenarios[i].subtitle}',
                  onTap: () => controller.scanSample(kSampleScenarios[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Outlined chip with a radio dot; scales its content down rather than truncating.
class SampleChip extends StatelessWidget {
  const SampleChip({super.key, required this.selected, required this.onTap, required this.label, this.semanticLabel});

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
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
          height: kMinTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioDot(selected: selected),
                  const SizedBox(width: AppSpace.sm),
                  Icon(LucideIcons.creditCard, size: 15, color: selected ? AppColors.accent : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
