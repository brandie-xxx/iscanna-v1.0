import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shown in About; keep in step with `version` in pubspec.yaml.
const String kAppVersion = '1.0.0';

/// "About iscanna" sheet: what it does, how to use it, batch and privacy in brief.
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.panel + 4)),
      ),
      builder: (_) => const FractionallySizedBox(heightFactor: 0.94, child: AboutSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpace.sm),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(3)),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Semantics(header: true, child: const Text('About', style: AppText.headline)),
              Positioned(
                right: AppSpace.sm,
                top: 0,
                bottom: 0,
                child: Center(
                  widthFactor: 1,
                  child: AppButton(label: 'Done', kind: ButtonKind.plain, onPressed: () => Navigator.of(context).pop()),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.lg,
              AppSpace.gutter,
              MediaQuery.paddingOf(context).bottom + AppSpace.lg,
            ),
            children: const [
              _Hero(),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'How it works',
                footer: 'On iPhone, Dial copies the code for you to paste into Phone.',
                padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                child: Column(
                  children: [
                    _Step(number: 1, title: 'Scan', text: 'Point the camera at the PIN strip, or choose a photo.'),
                    Hairline(indent: 48),
                    _Step(number: 2, title: 'Check', text: 'Fix any digit marked for review.'),
                    Hairline(indent: 48),
                    _Step(
                      number: 3,
                      title: 'Dial',
                      text: 'The full code opens in your dialer: *133*PIN# for NetOne, *121*PIN# for Econet.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'Batch',
                child: Text(
                  'Set Cards to scan to 2 or more. Verified scans are queued so you can dial, copy or export them.',
                  style: AppText.callout,
                ),
              ),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'Privacy',
                child: Text('Cards are read on your phone. Nothing is uploaded.', style: AppText.callout),
              ),
              SizedBox(height: AppSpace.xxl),
              Center(child: Text('Version $kAppVersion', style: AppText.caption)),
              AuthorFooter(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderStrong, width: 0.5),
          ),
          child: const Icon(LucideIcons.scanLine, size: 30, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpace.lg),
        const Text.rich(
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
          style: TextStyle(fontFamily: kFontFamily, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
        const SizedBox(height: AppSpace.xs),
        const Text('Scan a recharge card and dial it in one tap.', textAlign: TextAlign.center, style: AppText.callout),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text});

  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Text('$number', style: AppText.code.copyWith(fontSize: 15, color: AppColors.accent)),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.headline.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(text, style: AppText.footnote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
