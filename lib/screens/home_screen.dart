import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/dialer.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/batch_processing_view.dart';
import '../widgets/camera_capture.dart';
import '../widgets/card_results_view.dart';
import '../widgets/common.dart';
import '../widgets/top_bar.dart';

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
    await HapticFeedback.heavyImpact();
    _confetti.play();
    final opened = await openDialer(card.wrappedPin);
    if (mounted && !opened) showToast(context, "Couldn't open the dialer. Copy the code and dial manually.");
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kSystemUiStyle,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: app,
                    builder: (context, _) => CustomScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.gutter,
                            AppSpace.xl,
                            AppSpace.gutter,
                            AppSpace.xxl,
                          ),
                          sliver: SliverList.list(
                            children: [
                              NavigationControlBar(controller: app),
                              const SizedBox(height: AppSpace.xl),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: app.tab == AppTab.scanner
                                    ? Column(
                                        key: const ValueKey('scanner'),
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          SampleCardSelector(controller: app),
                                          const SizedBox(height: AppSpace.xl),
                                          CameraCapture(controller: app),
                                          const SizedBox(height: AppSpace.lg),
                                          CardResultsView(controller: app, onDial: _dial),
                                        ],
                                      )
                                    : BatchProcessingView(key: const ValueKey('batch'), controller: app, onDial: _dial),
                              ),
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(child: _Footer()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: const Alignment(0, 0.3),
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                emissionFrequency: 0.6,
                gravity: 0.25,
                colors: const [AppColors.accent, AppColors.accentPressed, AppColors.accentSoft, AppColors.textPrimary],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: const Column(
        children: [
          Text(
            'iscanna1.0',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA1A1AA)),
          ),
          SizedBox(height: AppSpace.xs + 2),
          Text('*exxstatix', style: TextStyle(fontSize: 12, color: AppColors.accent)),
        ],
      ),
    );
  }
}
