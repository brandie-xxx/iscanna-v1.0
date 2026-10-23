import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/carriers.dart';
import '../models/models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_capture.dart';
import '../widgets/card_results_view.dart';
import '../widgets/common.dart';

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
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Scan'),
          leading: Align(widthFactor: 1, alignment: Alignment.centerLeft, child: BrandMark()),
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          transitionBetweenRoutes: false,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            MediaQuery.paddingOf(context).bottom + AppSpace.lg,
          ),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                child: Text('CARRIER', style: AppText.sectionHeader),
              ),
              SegmentedPicker<String>(
                value: controller.format.id,
                segments: {for (final f in kCarrierFormats) f.id: (f.name, f.prefix)},
                onChanged: (id) => controller.selectFormat(findFormatById(id)!),
              ),
              const SizedBox(height: AppSpace.xxl),
              CameraCapture(controller: controller),
              const SizedBox(height: AppSpace.xxl),
              _BatchTargetSection(controller: controller),
              const SizedBox(height: AppSpace.xxl),
              CardResultsView(controller: controller, onDial: onDial),
              const AuthorFooter(),
            ],
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
      header: 'Batch Target',
      footer: target > 1
          ? 'Verified scans are added to the batch automatically until the target is reached.'
          : 'Raise the target to queue verified scans automatically.',
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Cards to scan', style: AppText.body)),
              Text(
                '$target',
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 17,
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
                        const SizedBox(height: AppSpace.sm),
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
