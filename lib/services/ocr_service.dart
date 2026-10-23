import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult(this.text, this.confidence);

  /// The text most likely to hold the PIN (best matching line, else all text).
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

  static final _pinLine = RegExp(r'(?<!\d)\d{4}(?:[ \t-]?\d{4}){3}(?!\d)');

  @override
  Future<OcrResult> readImage(String path) async {
    final recognized = await _recognizer.processImage(InputImage.fromFilePath(path));

    // Prefer the single line that looks like a full PIN, so serial numbers elsewhere
    // on the card can't be mixed in; score it by its least-confident word.
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        if (!_pinLine.hasMatch(line.text)) continue;
        final scores = [
          for (final el in line.elements)
            if (el.confidence != null && RegExp(r'\d').hasMatch(el.text)) el.confidence!,
        ];
        final confidence = scores.isEmpty ? null : (scores.reduce((a, b) => a < b ? a : b) * 100).round();
        return OcrResult(line.text, confidence);
      }
    }
    return OcrResult(recognized.text, null);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
