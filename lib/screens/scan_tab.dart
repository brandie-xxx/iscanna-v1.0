import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/carriers.dart';
import '../models/models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_capture.dart';
import '../widgets/card_results_view.dart';
import '../widgets/common.dart';
import '../widgets/screen_header.dart';
import 'about_sheet.dart';

/// Scan tab: carrier choice, scanner, batch target and the latest result.
class ScanTab extends StatelessWidget {
  const ScanTab({super.key, required this.controller, required this.onDial});

  final AppController controller;
  final Future<void> Function(ScannedCard card) onDial;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        ScreenHeader(
          title: 'Scan',
          leading: const BrandMark(),
          trailing: IconCircleButton(
            icon: LucideIcons.info,
            label: 'About iscanna',
            size: 36,
            color: AppColors.accent,
            background: Colors.transparent,
            onPressed: () => AboutSheet.show(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
          sliver: SliverList.list(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
                child: Text('Carrier', style: AppText.sectionHeader),
              ),
              SegmentedPicker<String>(
                value: controller.format.id,
                segments: {for (final f in kCarrierFormats) f.id: (f.name, f.prefix)},
                onChanged: (id) => controller.selectFormat(findFormatById(id)!),
              ),
              const SizedBox(height: AppSpace.section),
              CameraCapture(controller: controller),
              const SizedBox(height: AppSpace.section),
              _BatchTargetSection(controller: controller),
              const SizedBox(height: AppSpace.section),
              CardResultsView(controller: controller, onDial: onDial),
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

/// "Cards to scan" stepper with progress; above 1, verified scans queue themselves.
class _BatchTargetSection extends StatelessWidget {
  const _BatchTargetSection({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final target = controller.targetScanCount;
    final queued = controller.batch.length;
    final fraction = (queued / target).clamp(0.0, 1.0);
    return GroupedSection(
      header: 'Batch target',
      footer: target > 1
          ? 'Batch is on. Verified scans join the queue automatically until the target is reached.'
          : 'Set 2 or more cards to turn on Batch and queue verified scans automatically.',
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Cards to scan', style: AppText.body)),
              Text(
                '$target',
                style: const TextStyle(
                  fontFamily: kButtonFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              StepperControl(
                semanticValue: 'target $target',
                onDecrement: target > 1 ? controller.decrementTarget : null,
                onIncrement: controller.incrementTarget,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: target <= 1
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpace.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('$queued of $target queued', style: AppText.footnote)),
                            Text('${(fraction * 100).round()}%', style: AppText.readout),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: fraction),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, _) => LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: AppColors.surface,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
