import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/carriers.dart';
import '../models/models.dart';
import '../services/ocr_service.dart';
import '../services/pin_parser.dart';

enum AppTab { scanner, batch }

/// All app state and actions (the Flutter port of the web App component).
class AppController extends ChangeNotifier {
  AppController(this._ocr, {this.sampleDelay = const Duration(milliseconds: 350)});

  final OcrService _ocr;
  final Duration sampleDelay;

  CarrierFormat _format = defaultFormat;
  AppTab _tab = AppTab.scanner;
  int _targetScanCount = 1;
  ScannedCard? _card;
  String? _scanError;
  CardSource? _preview;
  final List<ScannedCard> _batch = [];
  bool _isScanning = false;
  String? _activeSampleId;

  // Only the latest scan may update state; older in-flight results are dropped.
  int _scanSeq = 0;

  CarrierFormat get format => _format;
  AppTab get tab => _tab;
  int get targetScanCount => _targetScanCount;
  ScannedCard? get card => _card;
  String? get scanError => _scanError;
  CardSource? get preview => _preview;
  List<ScannedCard> get batch => List.unmodifiable(_batch);
  bool get isScanning => _isScanning;
  String? get activeSampleId => _activeSampleId;

  void selectTab(AppTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void selectFormat(CarrierFormat format) {
    _format = format;
    final card = _card;
    if (card != null) _replaceCard(switchCarrier(card, format));
    notifyListeners();
  }

  void incrementTarget() {
    _targetScanCount++;
    notifyListeners();
  }

  void resetTarget() {
    if (_targetScanCount == 1) return;
    _targetScanCount = 1;
    notifyListeners();
  }

  /// Camera opened: clear the preview so the live feed shows, but keep the last result.
  void clearPreview() {
    _preview = null;
    _activeSampleId = null;
    notifyListeners();
  }

  Future<void> scanSample(SampleScenario sample) => _scan(SampleSource(sample));

  Future<void> scanPhoto(String path) => _scan(PhotoSource(path));

  Future<void> rescan() async {
    final source = _preview;
    if (source != null) await _scan(source);
  }

  Future<void> _scan(CardSource source) async {
    final seq = ++_scanSeq;
    _isScanning = true;
    _scanError = null;
    _preview = source;
    _activeSampleId = source is SampleSource ? source.scenario.id : null;
    notifyListeners();

    try {
      final ScannedCard card;
      switch (source) {
        case SampleSource(:final scenario):
          await Future<void>.delayed(sampleDelay);
          if (seq != _scanSeq) return;
          card = _sampleCard(scenario, source);
        case PhotoSource(:final path):
          final result = await _ocr.readImage(path);
          if (seq != _scanSeq) return;
          card = parsePinText(result.text, fallbackFormat: _format, confidence: result.confidence, source: source);
      }
      _showCard(card);
    } catch (e) {
      if (seq != _scanSeq) return;
      debugPrint('OCR failed: $e');
      _card = null;
      _scanError = 'Could not read this photo. Try again with the card flat and well lit.';
      await HapticFeedback.heavyImpact();
    } finally {
      if (seq == _scanSeq) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  ScannedCard _sampleCard(SampleScenario sample, CardSource source) {
    var card = parsePinText(sample.expectedPin, fallbackFormat: _format, confidence: sample.confidence, source: source);
    final damaged = sample.damagedDigitIndex;
    if (damaged != null) {
      final digits = [...card.digits];
      digits[damaged] = digits[damaged].copyWith(confidence: 55);
      card = card.copyWith(
        digits: digits,
        status: CardStatus.warning,
        errorMessage: () => 'Scratch on digit ${damaged + 1}. Please verify.',
      );
    }
    return card;
  }

  void _showCard(ScannedCard card) {
    _scanError = null;
    _card = card;
    if (card.canDial) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    // Only verified reads are queued automatically; others need review first.
    if (_targetScanCount > 1 && card.canDial) _addToBatch(card);
  }

  /// Opens a batch card in the result view (e.g. before editing it).
  void focusCard(ScannedCard card) {
    _card = card;
    _scanError = null;
    notifyListeners();
  }

  void saveCorrection(ScannedCard card, String newPin) {
    _replaceCard(applyCorrection(card, newPin, _format));
    notifyListeners();
  }

  void addToBatch(ScannedCard card) {
    _addToBatch(card);
    notifyListeners();
  }

  // A re-scan of the same PIN replaces the earlier entry.
  void _addToBatch(ScannedCard card) {
    _batch
      ..removeWhere((c) => c.id == card.id || c.rawPin == card.rawPin)
      ..insert(0, card);
  }

  void removeFromBatch(String id) {
    _batch.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void clearBatch() {
    _batch.clear();
    notifyListeners();
  }

  // Keep the result view and its batch copy in sync.
  void _replaceCard(ScannedCard updated) {
    if (_card?.id == updated.id) _card = updated;
    final i = _batch.indexWhere((c) => c.id == updated.id);
    if (i >= 0) _batch[i] = updated;
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }
}
