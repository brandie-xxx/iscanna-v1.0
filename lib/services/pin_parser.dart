import 'dart:math';

import '../data/carriers.dart';
import '../models/models.dart';

const int kPinLength = 16;

/// One line of text from the OCR engine, with its weakest digit confidence (0–100) when reported.
class OcrLine {
  const OcrLine(this.text, [this.confidence]);

  final String text;
  final int? confidence;
}

// Letters OCR often reads in place of digits on printed cards.
const Map<String, String> _lookalikes = {
  'O': '0', 'o': '0', 'D': '0', 'Q': '0', 'U': '0', //
  'I': '1', 'l': '1', 'i': '1', '|': '1', '!': '1', //
  'Z': '2', 'z': '2', 'S': '5', 's': '5', r'$': '5', //
  'B': '8', 'G': '6', 'b': '6', 'T': '7', 'g': '9', 'q': '9',
};

/// Swaps lookalike letters for digits, but only inside number-like tokens (at least half digits),
/// so ordinary words on the card stay as they are.
String normalizeDigits(String text) => text.splitMapJoin(
  RegExp(r'\S+'),
  onMatch: (m) {
    final token = m[0]!;
    final digits = RegExp(r'\d').allMatches(token).length;
    final significant = token.replaceAll(RegExp(r'[.\-–:]'), '').length;
    if (digits == 0 || digits * 2 < significant) return token;
    return token.split('').map((c) => _lookalikes[c] ?? c).join();
  },
  onNonMatch: (s) => s,
);

// 16 digits with at most short separators between them, not part of a longer number.
final RegExp _fullPin = RegExp(r'(?<!\d[ \t.\-–]{0,2})(?:\d[ \t.\-–]{0,2}){15}\d(?![ \t.\-–]{0,2}\d)');
// A shorter run (6–15 digits) for partial reads the user can complete.
final RegExp _partialPin = RegExp(r'(?<!\d[ \t.\-–]{0,2})(?:\d[ \t.\-–]{0,2}){5,14}\d(?![ \t.\-–]{0,2}\d)');

/// Picks the text most likely to be the card's PIN from OCR lines.
///
/// Prefers a full 16-digit number, scoring a known carrier prefix and a single-line read above
/// others; also tries neighbouring lines joined, in case the strip wrapped. Falls back to the
/// longest partial number so the user can fill in the rest, or '' when nothing looks like a PIN.
OcrLine pickPinText(List<OcrLine> lines) {
  final norm = [for (final l in lines) OcrLine(normalizeDigits(l.text), l.confidence)];
  int? weakest(int? a, int? b) => a == null ? b : (b == null ? a : (a < b ? a : b));
  final sources = [
    for (final l in norm) (line: l, single: true),
    for (var i = 0; i + 1 < norm.length; i++)
      (
        line: OcrLine('${norm[i].text} ${norm[i + 1].text}', weakest(norm[i].confidence, norm[i + 1].confidence)),
        single: false,
      ),
  ];

  OcrLine? best;
  var bestScore = -1;
  for (final (:line, :single) in sources) {
    for (final m in _fullPin.allMatches(line.text)) {
      final digits = m[0]!.replaceAll(RegExp(r'\D'), '');
      final score = (detectCarrierByPin(digits) != null ? 2 : 0) + (single ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = OcrLine(digits, line.confidence);
      }
    }
  }
  if (best != null) return best;

  OcrLine partial = const OcrLine('');
  var most = 0;
  for (final l in norm) {
    for (final m in _partialPin.allMatches(l.text)) {
      final digits = m[0]!.replaceAll(RegExp(r'\D'), '');
      if (digits.length > most) {
        most = digits.length;
        partial = OcrLine(digits, l.confidence);
      }
    }
  }
  return partial;
}

/// Builds a [ScannedCard] from recognised text. Never invents digits: anything
/// shorter than 16 digits is flagged for review, and missing positions get 0% confidence.
///
/// [confidence] is the OCR engine's 0–100 score, or null when it doesn't report one
/// (ML Kit on iOS); in that case a clean 16-digit match is accepted as-is.
ScannedCard parsePinText(
  String text, {
  required CarrierFormat fallbackFormat,
  int? confidence,
  String? photoPath,
  DateTime? now,
  Random? random,
}) {
  final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

  // Prefer a standalone 16-digit run, then 4 groups of 4, then the first 16 digits.
  final match16 = RegExp(r'(?<!\d)\d{16}(?!\d)').firstMatch(text);
  final matchGrouped = RegExp(r'(?<!\d)\d{4}(?:[ \t-]?\d{4}){3}(?!\d)').firstMatch(text);
  final String found;
  if (match16 != null) {
    found = match16[0]!;
  } else if (matchGrouped != null) {
    found = matchGrouped[0]!.replaceAll(RegExp(r'[ \t-]'), '');
  } else {
    found = digitsOnly.length > kPinLength ? digitsOnly.substring(0, kPinLength) : digitsOnly;
  }
  // Digits gathered from scattered numbers are only a guess: never verified without a check.
  final clearMatch = match16 != null || matchGrouped != null;

  final conf = confidence?.clamp(0, 100);
  var status = CardStatus.success;
  String? error;
  if (found.isEmpty) {
    status = CardStatus.error;
    error = 'No PIN detected. Re-align the card under good lighting, or enter it manually.';
  } else if (found.length < kPinLength) {
    status = CardStatus.warning;
    error = 'Only ${found.length} of $kPinLength digits were read. Fill in the missing digits before dialing.';
  } else if (!clearMatch) {
    status = CardStatus.warning;
    error = "Couldn't find a clear 16-digit PIN. Check every digit before dialing.";
  } else if (conf != null && conf < 80) {
    status = CardStatus.warning;
    error = 'Low read confidence. Check every digit before dialing.';
  }

  // Missing positions are placeholders for the editor, never presented as read digits.
  final pin16 = found.padRight(kPinLength, '0');
  final format = detectCarrierByPin(found) ?? fallbackFormat;
  final readConfidence = conf ?? 100;

  final digits = [
    for (var i = 0; i < kPinLength; i++)
      DigitConfidence(index: i, char: pin16[i], confidence: i < found.length ? readConfidence : 0),
  ];

  final at = now ?? DateTime.now();
  final rand = (random ?? Random()).nextInt(1 << 32).toRadixString(36);
  return ScannedCard(
    id: 'card-${at.microsecondsSinceEpoch}-$rand',
    rawPin: pin16,
    wrappedPin: wrapPin(pin16, format),
    carrierId: format.id,
    carrierName: format.name,
    confidence: found.isEmpty ? 0 : readConfidence,
    digits: digits,
    status: status,
    errorMessage: error,
    timestamp: at,
    photoPath: photoPath,
  );
}

/// Applies a manual correction: the user has checked every digit.
ScannedCard applyCorrection(ScannedCard card, String newPin, CarrierFormat fallbackFormat) {
  final format = findFormatById(card.carrierId) ?? fallbackFormat;
  return card.copyWith(
    rawPin: newPin,
    wrappedPin: wrapPin(newPin, format),
    carrierId: format.id,
    carrierName: format.name,
    confidence: 100,
    status: CardStatus.success,
    errorMessage: () => null,
    manualEditsCount: card.manualEditsCount + 1,
    digits: [for (var i = 0; i < newPin.length; i++) DigitConfidence(index: i, char: newPin[i], confidence: 100)],
  );
}

/// Re-wraps a card for a different carrier (user switched NetOne/Econet).
ScannedCard switchCarrier(ScannedCard card, CarrierFormat format) =>
    card.copyWith(wrappedPin: wrapPin(card.rawPin, format), carrierId: format.id, carrierName: format.name);
