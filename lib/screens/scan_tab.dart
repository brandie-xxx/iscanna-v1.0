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
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
                child: Text('Carrier', style: AppText.sectionHeader),
              ),
              SegmentedPicker<String>(
                value: controller.format.id,
                segments: {for (final f in kCarrierFormats) f.id: (f.name, f.prefix)},
                onChanged: (id) => controller.selectFormat(findFormatById(id)!),
              ),
              const SizedBox(height: AppSpace.xxl),
              _BatchTarget(controller: controller),
              const SizedBox(height: AppSpace.section),
              CameraCapture(controller: controller),
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
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpace.lg),
              child: const AuthorFooter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// One plain line: "Cards to scan  − 2 +". At 2 or more, Batch turns on and a queue count appears.
class _BatchTarget extends StatelessWidget {
  const _BatchTarget({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final target = controller.targetScanCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Cards to scan', style: AppText.body)),
              _RoundStep(
                icon: LucideIcons.minus,
                label: 'Decrease cards to scan, now $target',
                onTap: target > 1 ? controller.decrementTarget : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$target',
                  textAlign: TextAlign.center,
                  style: AppText.code.copyWith(fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
              _RoundStep(
                icon: LucideIcons.plus,
                label: 'Increase cards to scan, now $target',
                onTap: controller.incrementTarget,
              ),
            ],
          ),
          if (target > 1) ...[
            const SizedBox(height: AppSpace.xs),
            Text('${controller.batch.length}/$target queued', style: AppText.footnote),
          ],
        ],
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Icon(icon, size: 15, color: onTap == null ? AppColors.textFaint : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
