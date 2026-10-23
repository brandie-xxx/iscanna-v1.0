import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/carriers.dart';
import '../models/models.dart';
import '../services/ocr_service.dart';
import '../services/pin_parser.dart';

enum AppTab { scanner, batch }

/// All app state and actions.
class AppController extends ChangeNotifier {
  AppController(this._ocr);

  final OcrService _ocr;

  CarrierFormat _format = defaultFormat;
  AppTab _tab = AppTab.scanner;
  int _targetScanCount = 1;
  ScannedCard? _card;
  String? _scanError;
  String? _previewPath;
  final List<ScannedCard> _batch = [];
  bool _isScanning = false;

  // Only the latest scan may update state; older in-flight results are dropped.
  int _scanSeq = 0;

  CarrierFormat get format => _format;
  AppTab get tab => _tab;
  int get targetScanCount => _targetScanCount;
  ScannedCard? get card => _card;
  String? get scanError => _scanError;

  /// The photo shown in the viewfinder when the camera is off.
  String? get previewPath => _previewPath;
  List<ScannedCard> get batch => List.unmodifiable(_batch);
  bool get isScanning => _isScanning;

  void selectTab(AppTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void selectFormat(CarrierFormat format) {
    if (_format.id == format.id) return;
    _format = format;
    final card = _card;
    if (card != null) _replaceCard(switchCarrier(card, format));
    notifyListeners();
  }

  void incrementTarget() {
    if (_targetScanCount >= 99) return;
    _targetScanCount++;
    notifyListeners();
  }

  void decrementTarget() {
    if (_targetScanCount <= 1) return;
    _targetScanCount--;
    notifyListeners();
  }

  /// Camera opened: clear the preview so the live feed shows, but keep the last result.
  void clearPreview() {
    _previewPath = null;
    notifyListeners();
  }

  Future<void> scanPhoto(String path) async {
    final seq = ++_scanSeq;
    _isScanning = true;
    _scanError = null;
    _previewPath = path;
    notifyListeners();

    try {
      final result = await _ocr.readImage(path);
      if (seq != _scanSeq) return;
      _showCard(parsePinText(result.text, fallbackFormat: _format, confidence: result.confidence, photoPath: path));
    } catch (e) {
      if (seq != _scanSeq) return;
      debugPrint('OCR failed: $e');
      _card = null;
      _scanError = 'Could not read this photo. Try again with the card flat and well lit.';
      unawaited(HapticFeedback.heavyImpact());
    } finally {
      if (seq == _scanSeq) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  /// Reads the current preview photo again.
  Future<void> rescan() async {
    final path = _previewPath;
    if (path != null) await scanPhoto(path);
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

  // Keep the result view and the batch copy of a card in sync.
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
