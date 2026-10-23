import 'dart:math';

import '../data/carriers.dart';
import '../models/models.dart';

const int kPinLength = 16;

/// Builds a [ScannedCard] from recognised text. Never invents digits: anything
/// shorter than 16 digits is flagged for review, and missing positions get 0% confidence.
///
/// [confidence] is the OCR engine's 0–100 score, or null when it doesn't report one
/// (ML Kit on iOS); in that case a clean 16-digit match is accepted as-is.
ScannedCard parsePinText(
  String text, {
  required CarrierFormat fallbackFormat,
  int? confidence,
  CardSource? source,
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

  final conf = confidence?.clamp(0, 100);
  var status = CardStatus.success;
  String? error;
  if (found.isEmpty) {
    status = CardStatus.error;
    error = 'No PIN detected. Re-align the card under good lighting, or enter it manually.';
  } else if (found.length < kPinLength) {
    status = CardStatus.warning;
    error = 'Only ${found.length} of $kPinLength digits were read. Fill in the missing digits before dialing.';
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
    source: source,
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
