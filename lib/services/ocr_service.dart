import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'pin_parser.dart';

class OcrResult {
  const OcrResult(this.text, this.confidence);

  /// The text most likely to hold the PIN (a full or partial digit run), or '' if none.
  final String text;

  /// 0–100, or null when the platform doesn't report confidence (iOS).
  final int? confidence;
}

/// Reads card photos on-device with ML Kit. Nothing leaves the phone.
abstract class OcrService {
  Future<OcrResult> readImage(String path);
  Future<void> dispose();
}

class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrResult> readImage(String path) async {
    final recognized = await _recognizer.processImage(InputImage.fromFilePath(path));

    // Every line, top to bottom, scored by its least-confident word that holds a digit.
    final lines = [
      for (final block in recognized.blocks)
        for (final line in block.lines) OcrLine(line.text, _weakestDigitScore(line)),
    ];
    final pin = pickPinText(lines);
    // Never log the PIN itself: only how much was found.
    debugPrint('OCR read ${lines.length} lines; PIN candidate has ${pin.text.length} digits');
    return OcrResult(pin.text, pin.confidence);
  }

  static int? _weakestDigitScore(TextLine line) {
    final scores = [
      for (final el in line.elements)
        if (el.confidence != null && RegExp(r'\d').hasMatch(el.text)) el.confidence!,
    ];
    return scores.isEmpty ? null : (scores.reduce((a, b) => a < b ? a : b) * 100).round();
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
