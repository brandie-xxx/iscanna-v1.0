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
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
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

/// Mode (Scan / Batch) and carrier (NetOne / Econet) radio groups.
class NavigationControlBar extends StatelessWidget {
  const NavigationControlBar({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final batchCount = controller.batch.length;
    final onBatch = controller.tab == AppTab.batch;
    return Panel(
      padding: const EdgeInsets.all(8),
      child: Column(
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
                trailing: batchCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: onBatch ? AppColors.accent : AppColors.border,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '$batchCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: onBatch ? AppColors.background : AppColors.textSecondary,
                          ),
                        ),
                      )
                    : null,
                onTap: () => controller.selectTab(AppTab.batch),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentTrack(
            children: [
              for (final fmt in kCarrierFormats)
                SegmentOption(
                  selected: controller.format.id == fmt.id,
                  label: fmt.name,
                  semanticLabel: '${fmt.name} format ${fmt.pattern}',
                  trailing: Text(fmt.prefix, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  onTap: () => controller.selectFormat(fmt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling preset chips that load a drawn sample card.
class SampleCardSelector extends StatelessWidget {
  const SampleCardSelector({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: kSampleScenarios.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final sc = kSampleScenarios[i];
          return SegmentOptionChip(
            selected: controller.activeSampleId == sc.id,
            label: sc.title,
            semanticLabel: 'Sample: ${sc.title}. ${sc.subtitle}',
            onTap: () => controller.scanSample(sc),
          );
        },
      ),
    );
  }
}

/// Standalone outlined chip variant of [SegmentOption].
class SegmentOptionChip extends StatelessWidget {
  const SegmentOptionChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.label,
    this.semanticLabel,
  });

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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Row(
            children: [
              RadioDot(selected: selected),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
