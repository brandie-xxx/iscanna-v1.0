import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'sample_card_art.dart';

/// "Camera & Scanner" panel: live viewfinder, capture, gallery upload, re-scan, target count.
class CameraCapture extends StatefulWidget {
  const CameraCapture({super.key, required this.controller});

  final AppController controller;

  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> with WidgetsBindingObserver {
  CameraController? _camera;
  bool _starting = false;
  bool _torchOn = false;
  String? _cameraError;

  AppController get _app => widget.controller;
  bool get _cameraActive => _camera?.value.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  // Release the camera when the app is backgrounded, as the OS requires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) _stopCamera();
  }

  Future<void> _startCamera() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _cameraError = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('NoCamera', 'No camera found');
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final camera = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await camera.initialize();
      await camera.setFlashMode(FlashMode.off);
      if (!mounted) {
        await camera.dispose();
        return;
      }
      _app.clearPreview();
      setState(() {
        _camera = camera;
        _torchOn = false;
      });
    } on CameraException catch (e) {
      setState(() {
        _cameraError = e.code.contains('AccessDenied')
            ? 'Camera access denied. Allow it in Settings, or upload a photo.'
            : 'Camera unavailable. Upload a photo.';
      });
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stopCamera() async {
    final camera = _camera;
    if (camera == null) return;
    setState(() {
      _camera = null;
      _torchOn = false;
    });
    await camera.dispose();
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      setState(() => _torchOn = !_torchOn);
    } on CameraException {
      if (mounted) showToast(context, 'Torch not available on this camera');
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || camera.value.isTakingPicture) return;
    await HapticFeedback.heavyImpact();
    try {
      if (_torchOn) await camera.setFlashMode(FlashMode.off);
      final shot = await camera.takePicture();
      await _stopCamera();
      unawaited(_app.scanPhoto(shot.path));
    } on CameraException {
      if (mounted) setState(() => _cameraError = "Couldn't capture the frame. Try again or upload a photo.");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Downscaled on pick: plenty of resolution for 16 digits, faster OCR.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;
      await _stopCamera();
      setState(() => _cameraError = null);
      unawaited(_app.scanPhoto(picked.path));
    } on PlatformException {
      if (mounted) setState(() => _cameraError = 'Photo access denied. Allow it in Settings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Scanner',
            leadingBadge: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: app.isScanning ? const _ScanningTag() : const SizedBox.shrink(),
            ),
            trailing: _TargetCounter(controller: app),
          ),
          if (app.targetScanCount > 1) ...[
            _TargetProgress(current: app.batch.length, target: app.targetScanCount),
            const SizedBox(height: AppSpace.md),
          ],
          _viewport(app),
          const SizedBox(height: AppSpace.lg),
          _controls(app),
        ],
      ),
    );
  }

  Widget _viewport(AppController app) {
    final preview = app.preview;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _cameraActive
                    ? _LiveFeed(key: const ValueKey('live'), camera: _camera!)
                    : preview != null
                    ? _PreviewImage(key: ValueKey(preview), source: preview, processing: app.isScanning)
                    : const _EmptyViewport(key: ValueKey('empty')),
              ),
              if (_cameraActive) const _FrameGuides(),
              if (_cameraActive)
                Positioned(
                  top: AppSpace.md,
                  right: AppSpace.md,
                  child: _RoundIconButton(
                    icon: _torchOn ? LucideIcons.zap : LucideIcons.zapOff,
                    label: _torchOn ? 'Turn torch off' : 'Turn torch on',
                    active: _torchOn,
                    onTap: _toggleTorch,
                  ),
                ),
              if (_cameraError != null)
                Positioned(
                  left: AppSpace.md,
                  right: AppSpace.md,
                  bottom: AppSpace.md,
                  child: _ErrorStrip(message: _cameraError!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(AppController app) {
    if (_cameraActive) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Capture Card',
              icon: LucideIcons.scanLine,
              variant: ButtonVariant.primary,
              expand: true,
              height: 48,
              haptic: false,
              onPressed: app.isScanning ? null : _capture,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          AppButton(label: 'Cancel', height: 48, onPressed: _stopCamera),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app.preview != null) ...[
          AppButton(
            label: app.isScanning ? 'Reading…' : 'Re-Scan',
            icon: LucideIcons.refreshCw,
            variant: ButtonVariant.primary,
            expand: true,
            height: 48,
            onPressed: app.isScanning ? null : app.rescan,
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: _starting ? 'Opening…' : 'Camera',
                icon: LucideIcons.camera,
                variant: app.preview == null ? ButtonVariant.primary : ButtonVariant.secondary,
                expand: true,
                semanticLabel: 'Open camera',
                onPressed: _starting ? null : _startCamera,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: AppButton(
                label: 'Upload',
                icon: LucideIcons.upload,
                semanticLabel: 'Upload photo',
                expand: true,
                onPressed: _pickFromGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanningTag extends StatelessWidget {
  const _ScanningTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Spinner(size: 11),
          SizedBox(width: 5),
          Text(
            'Scanning',
            style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner({this.size = 14, this.color = AppColors.accent});

  final double size;
  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Icon(LucideIcons.refreshCw, size: widget.size, color: widget.color),
    );
  }
}

/// Radio-style target count: tap the count to reset to 1, tap + to increase.
class _TargetCounter extends StatelessWidget {
  const _TargetCounter({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.targetScanCount;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: count > 1 ? 'Target $count cards. Tap to reset to 1' : 'Target 1 card',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: count > 1
                  ? () {
                      HapticFeedback.selectionClick();
                      controller.resetTarget();
                    }
                  : null,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  children: [
                    const RadioDot(selected: true, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'Increase target count',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                controller.incrementTarget();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(LucideIcons.plus, size: 14, color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetProgress extends StatelessWidget {
  const _TargetProgress({required this.current, required this.target});

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final fraction = (current / target).clamp(0.0, 1.0);
    return Inset(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target: $current of $target cards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(fraction * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: AppColors.surface,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveFeed extends StatelessWidget {
  const _LiveFeed({super.key, required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    // Cover the viewport: previewSize is reported in landscape, the UI is portrait.
    final size = camera.value.previewSize;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size?.height ?? 3, height: size?.width ?? 4, child: CameraPreview(camera)),
      ),
    );
  }
}

class _FrameGuides extends StatelessWidget {
  const _FrameGuides();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.accent, width: 2);
    Widget corner(Border border) => Container(width: 18, height: 18, decoration: BoxDecoration(border: border));
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                corner(const Border(top: side, left: side)),
                corner(const Border(top: side, right: side)),
              ],
            ),
            const Text(
              'Fit the PIN strip inside the frame',
              style: TextStyle(fontSize: 11, color: AppColors.accentSoft, shadows: [Shadow(blurRadius: 6)]),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                corner(const Border(bottom: side, left: side)),
                corner(const Border(bottom: side, right: side)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({super.key, required this.source, required this.processing});

  final CardSource source;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final image = switch (source) {
      PhotoSource(:final path) => Image.file(
        File(path),
        fit: BoxFit.contain,
        semanticLabel: 'Voucher card photo',
        errorBuilder: (_, _, _) => const Center(child: Icon(LucideIcons.imageOff, color: AppColors.textMuted)),
      ),
      SampleSource(:final scenario) => SampleCardArt(scenario: scenario),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Center(child: image),
        ),
        // Only built while processing, so the spinner doesn't animate unseen.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !processing
              ? const SizedBox.shrink()
              : Container(
                  color: AppColors.background.withValues(alpha: 0.8),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(7)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Spinner(size: 13, color: AppColors.background),
                        SizedBox(width: 6),
                        Text(
                          'Reading PIN...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.background),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyViewport extends StatelessWidget {
  const _EmptyViewport({super.key});

  @override
  Widget build(BuildContext context) {
    // Scrolls instead of overflowing when large text doesn't fit the 4:3 viewport.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(LucideIcons.scanLine, size: 22, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpace.lg),
            const Text(
              'Open the camera or upload a photo of a NetOne or Econet card',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.sm),
            const Text(
              'Photos are read on this device. Nothing is uploaded.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textFaint, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inset,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.circleAlert, size: 14, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.label, required this.onTap, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.background.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: active ? AppColors.accent : AppColors.borderStrong),
          ),
          child: Icon(icon, size: 18, color: active ? AppColors.background : AppColors.textPrimary),
        ),
      ),
    );
  }
}
