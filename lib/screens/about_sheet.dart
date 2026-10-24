import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shown in About; keep in step with `version` in pubspec.yaml.
const String kAppVersion = '1.0.0';

/// "About iscanna" sheet: what it solves, how it works, and why it's private.
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
              SizedBox(height: AppSpace.xxxl),
              GroupedSection(
                header: 'Why iscanna',
                child: Text(
                  'Recharge PINs are 16 digits long. Typing them into the dialer one by one is slow, '
                  'and a single wrong digit means starting over. Loading a stack of cards for a shop, '
                  'an office or the whole family turns into minutes of careful typing.\n\n'
                  'iscanna reads the PIN for you and hands the complete recharge code to your dialer, '
                  'so every card takes a scan and a tap.',
                  style: AppText.callout,
                ),
              ),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'How it works',
                footer: "On iPhone, Dial copies the code for you to paste into Phone, because iOS doesn't let apps open USSD codes.",
                padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                child: Column(
                  children: [
                    _Step(
                      number: 1,
                      title: 'Scan',
                      text: 'Point the camera at the PIN strip, or choose a photo of the card.',
                    ),
                    Hairline(indent: 48),
                    _Step(
                      number: 2,
                      title: 'Check',
                      text:
                          "All 16 digits are read and any it isn't sure of are flagged, so you can fix them in a tap.",
                    ),
                    Hairline(indent: 48),
                    _Step(
                      number: 3,
                      title: 'Dial',
                      text: 'The full code opens in your dialer, ready to send: *133*PIN# for NetOne, *121*PIN# for Econet.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'Built for batches',
                padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                child: Column(
                  children: [
                    _Feature(
                      icon: LucideIcons.layers,
                      title: 'Queue a whole stack',
                      text: 'Set a target of 2 or more cards and every verified scan joins the batch automatically.',
                    ),
                    Hairline(indent: 48),
                    _Feature(
                      icon: LucideIcons.phoneCall,
                      title: 'Dial one after another',
                      text: 'Work down the list with a tap per card. Nothing to retype.',
                    ),
                    Hairline(indent: 48),
                    _Feature(
                      icon: LucideIcons.share,
                      title: 'Copy or export',
                      text: 'Copy every code at once, or share the batch as CSV, JSON or TXT.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpace.xxl),
              GroupedSection(
                header: 'Private by design',
                padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                child: Column(
                  children: [
                    _Feature(
                      icon: LucideIcons.cpu,
                      title: 'Read on your phone',
                      text: 'Text recognition runs on the device. It even works without a connection.',
                    ),
                    Hairline(indent: 48),
                    _Feature(
                      icon: LucideIcons.shieldCheck,
                      title: 'Nothing is uploaded',
                      text: 'Card photos and PINs never leave your phone.',
                    ),
                  ],
                ),
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
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceHover, AppColors.panel],
            ),
            border: Border.all(color: AppColors.borderStrong, width: 0.5),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 28)],
          ),
          child: const Icon(LucideIcons.scanLine, size: 40, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpace.xl),
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
          style: TextStyle(fontFamily: kDisplayFamily, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8),
        ),
        const SizedBox(height: AppSpace.sm),
        const Text(
          'Recharge without the typing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kDisplayFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Text(
            'Scan a NetOne or Econet card and dial its PIN in one tap. One card or a whole stack.',
            textAlign: TextAlign.center,
            style: AppText.callout,
          ),
        ),
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

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 32, child: Icon(icon, size: 20, color: AppColors.accent)),
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
