import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Native drawing of a sample recharge card (replaces the web app's generated SVG).
/// Laid out on a 640×360 design canvas and scaled to fit.
class SampleCardArt extends StatelessWidget {
  const SampleCardArt({super.key, required this.scenario});

  final SampleScenario scenario;

  @override
  Widget build(BuildContext context) {
    final pin = scenario.expectedPin;

    return Semantics(
      image: true,
      label: '${scenario.carrierName} sample recharge card',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 640 / 360,
        child: FittedBox(
          child: SizedBox(
            width: 640,
            height: 360,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2B2C37), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: const Color(0xFF111216), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text(
                          '${scenario.carrierName.toUpperCase()} RECHARGE',
                          style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        const Text('iscanna1.0', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Scratch strip to reveal 16-digit voucher PIN',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 104,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111216),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2B2C37)),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(8)),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            for (var i = 0; i < pin.length; i++) ...[
                              if (i > 0 && i % 4 == 0) const TextSpan(text: ' '),
                              TextSpan(text: pin[i]),
                            ],
                          ],
                        ),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(scenario.footnote, style: const TextStyle(color: AppColors.accent, fontSize: 13)),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
