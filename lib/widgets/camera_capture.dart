import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Scanner section: viewfinder (live camera, photo preview or empty state) and capture controls.
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
    unawaited(HapticFeedback.heavyImpact());
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
    final live = _cameraActive;
    return GroupedSection(
      header: 'Scanner',
      headerTrailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: app.isScanning
            ? const Text('Reading…', key: ValueKey('reading'), style: AppText.readout)
            : live
            ? const Text('● LIVE', key: ValueKey('live'), style: AppText.readout)
            : const SizedBox.shrink(),
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _viewfinder(app),
          const SizedBox(height: AppSpace.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(live), child: _controls(app)),
          ),
        ],
      ),
    );
  }

  Widget _viewfinder(AppController app) {
    final preview = app.previewPath;
    final live = _cameraActive;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: ColoredBox(
        color: AppColors.inset,
        // Square viewfinder: tall enough to frame the whole card, with a full-width strip window.
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, box) {
              final strip = stripWindow(box.biggest);
              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: live
                        ? _LiveFeed(key: const ValueKey('live'), camera: _camera!)
                        : preview != null
                        ? _PhotoPreview(key: ValueKey(preview), path: preview)
                        : const SizedBox.expand(key: ValueKey('empty')),
                  ),
                  if (live || preview != null) _StripScrim(strip: strip),
                  _StripFrame(strip: strip, bright: live || preview != null),
                  if (live || app.isScanning) _ScanBeam(strip: strip),
                  if (!live && preview == null) _EmptyViewfinder(strip: strip),
                  Positioned(
                    left: strip.left + 2,
                    top: strip.top - 22,
                    child: Text(
                      live ? '● Live · PIN strip' : 'PIN strip',
                      style: AppText.readout.copyWith(
                        color: live || preview != null ? AppColors.accent : AppColors.textFaint,
                      ),
                    ),
                  ),
                  if (live)
                    Positioned(
                      top: AppSpace.md,
                      right: AppSpace.md,
                      child: IconCircleButton(
                        icon: _torchOn ? LucideIcons.zap : LucideIcons.zapOff,
                        label: _torchOn ? 'Turn torch off' : 'Turn torch on',
                        active: _torchOn,
                        size: 38,
                        background: AppColors.background.withValues(alpha: 0.6),
                        onPressed: _toggleTorch,
                      ),
                    ),
                  if (live || app.isScanning)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: strip.bottom + AppSpace.md,
                      child: Center(child: _HudChip(live ? 'Fit the whole strip in the frame' : 'Reading PIN…')),
                    ),
                  if (_cameraError != null)
                    Positioned(
                      left: AppSpace.md,
                      right: AppSpace.md,
                      bottom: AppSpace.md,
                      child: _ErrorBanner(message: _cameraError!),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _controls(AppController app) {
    if (_cameraActive) {
      // Camera-app layout: Cancel · shutter · (balance)
      return SizedBox(
        height: 84,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppButton(label: 'Cancel', kind: ButtonKind.plain, onPressed: _stopCamera),
              ),
            ),
            _ShutterButton(onPressed: app.isScanning ? null : _capture),
            const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    final hasPhoto = app.previewPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: _starting ? 'Opening Camera…' : 'Open Camera',
          icon: LucideIcons.camera,
          kind: ButtonKind.filled,
          size: ButtonSize.large,
          expand: true,
          onPressed: _starting ? null : _startCamera,
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Choose Photo',
                icon: LucideIcons.images,
                expand: true,
                onPressed: _pickFromGallery,
              ),
            ),
            if (hasPhoto) ...[
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: AppButton(
                  label: 'Scan Again',
                  icon: LucideIcons.refreshCw,
                  kind: ButtonKind.tinted,
                  expand: true,
                  onPressed: app.isScanning ? null : app.rescan,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'Capture card',
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        haptic: false,
        pressedScale: 0.9,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textPrimary, width: 3),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.45), blurRadius: 18)],
            ),
            child: const Icon(LucideIcons.scanLine, color: AppColors.background, size: 24),
          ),
        ),
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

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      semanticLabel: 'Voucher card photo',
      errorBuilder: (_, _, _) => const Center(child: Icon(LucideIcons.imageOff, color: AppColors.textFaint, size: 28)),
    );
  }
}

/// The window a card's PIN strip should sit in: nearly full width, about a third as tall.
@visibleForTesting
Rect stripWindow(Size box) {
  final width = box.width - 2 * AppSpace.lg;
  final height = (width / 3.4).clamp(76.0, box.height * 0.45);
  return Rect.fromCenter(center: box.center(Offset.zero), width: width, height: height);
}

/// Dims everything outside the strip window.
class _StripScrim extends StatelessWidget {
  const _StripScrim({required this.strip});

  final Rect strip;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _ScrimPainter(strip)));
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.strip);

  final Rect strip;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(strip, const Radius.circular(10)));
    canvas.drawPath(path, Paint()..color = AppColors.background.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.strip != strip;
}

/// Hairline outline plus accent corner brackets around the strip window.
class _StripFrame extends StatelessWidget {
  const _StripFrame({required this.strip, required this.bright});

  final Rect strip;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    final color = bright ? AppColors.accent : AppColors.accent.withValues(alpha: 0.45);
    final side = BorderSide(color: color, width: 2.5);
    const r = Radius.circular(10);
    const arm = 28.0;
    Widget corner(Alignment at, Border border, BorderRadius radius) => Align(
      alignment: at,
      child: Container(
        width: arm,
        height: arm,
        decoration: BoxDecoration(border: border, borderRadius: radius),
      ),
    );
    return Positioned.fromRect(
      rect: strip,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
                ),
              ),
            ),
            corner(Alignment.topLeft, Border(top: side, left: side), const BorderRadius.only(topLeft: r)),
            corner(Alignment.topRight, Border(top: side, right: side), const BorderRadius.only(topRight: r)),
            corner(Alignment.bottomLeft, Border(bottom: side, left: side), const BorderRadius.only(bottomLeft: r)),
            corner(Alignment.bottomRight, Border(bottom: side, right: side), const BorderRadius.only(bottomRight: r)),
          ],
        ),
      ),
    );
  }
}

/// Glowing beam sweeping along the strip while the camera is live or a photo is being read.
class _ScanBeam extends StatefulWidget {
  const _ScanBeam({required this.strip});

  final Rect strip;

  @override
  State<_ScanBeam> createState() => _ScanBeamState();
}

class _ScanBeamState extends State<_ScanBeam> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strip = widget.strip.deflate(6);
    return Positioned.fromRect(
      rect: strip,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final t = Curves.easeInOutSine.transform(_sweep.value);
            return Stack(
              children: [
                Positioned(
                  left: t * (strip.width - 2),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent.withValues(alpha: 0),
                          AppColors.accent,
                          AppColors.accent.withValues(alpha: 0),
                        ],
                      ),
                      boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.7), blurRadius: 12)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: AppText.readout),
    );
  }
}

/// Empty state: prompt above the strip window, privacy note below it.
class _EmptyViewfinder extends StatelessWidget {
  const _EmptyViewfinder({required this.strip});

  final Rect strip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Prompt fills the space above the "PIN STRIP" label.
        Positioned(
          left: AppSpace.lg,
          right: AppSpace.lg,
          top: AppSpace.md,
          height: (strip.top - 34 - AppSpace.md).clamp(0.0, double.infinity),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scanLine, size: 26, color: AppColors.accent),
                  SizedBox(height: AppSpace.sm),
                  Text(
                    'Scan a recharge card',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: strip,
          child: Center(
            child: Text(
              '0000  0000  0000  0000',
              style: AppText.code.copyWith(fontSize: 18, color: AppColors.textFaint.withValues(alpha: 0.6)),
            ),
          ),
        ),
        Positioned(
          left: AppSpace.lg,
          right: AppSpace.lg,
          top: strip.bottom + AppSpace.lg,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('NetOne or Econet · read on this device', textAlign: TextAlign.center, style: AppText.footnote),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.control - 4),
          border: Border.all(color: AppColors.borderStrong, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.circleAlert, size: 16, color: AppColors.warning),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(message, style: AppText.footnote.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
