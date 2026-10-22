import { ScannedCard, DigitConfidence, FormatConfig } from '../types';
import { detectCarrierByPin, wrapPinString } from '../data/carriers';

export const PIN_LENGTH = 16;

interface OcrDetails {
  confidence?: number;
  qualityCheck?: ScannedCard['qualityCheck'];
}

/**
 * Builds a ScannedCard from OCR text. Never invents digits: anything shorter than
 * 16 digits is flagged for review, and missing positions are marked 0% confidence.
 */
export function processPinText(
  text: string,
  fallbackFormat: FormatConfig,
  imageUrl?: string,
  details: OcrDetails = {}
): ScannedCard {
  const rawDigitsOnly = text.replace(/\D/g, '');

  // Prefer a standalone 16-digit run, then 4 groups of 4, then the first 16 digits
  const match16 = text.match(/\b\d{16}\b/);
  const matchGrouped = text.match(/\d{4}(?:[\s-]?\d{4}){3}/);
  let foundDigits: string;
  if (match16) {
    foundDigits = match16[0];
  } else if (matchGrouped) {
    foundDigits = matchGrouped[0].replace(/[\s-]/g, '');
  } else {
    foundDigits = rawDigitsOnly.slice(0, PIN_LENGTH);
  }

  const confidence = Math.round(Math.min(100, Math.max(0, details.confidence ?? 0)));
  let status: ScannedCard['status'] = 'success';
  let errorMessage: string | undefined;

  if (foundDigits.length === 0) {
    status = 'error';
    errorMessage = 'No PIN detected. Re-align the card under good lighting, or enter it manually.';
  } else if (foundDigits.length < PIN_LENGTH) {
    status = 'warning';
    errorMessage = `Only ${foundDigits.length} of ${PIN_LENGTH} digits were read. Fill in the missing digits before dialing.`;
  } else if (confidence < 80) {
    status = 'warning';
    errorMessage = 'Low read confidence. Check every digit before dialing.';
  }

  // Missing positions are placeholders for the editor, never presented as read digits
  const pin16 = foundDigits.padEnd(PIN_LENGTH, '0');
  const activeFmt = detectCarrierByPin(foundDigits) ?? fallbackFormat;

  const digits: DigitConfidence[] = pin16.split('').map((char, index) => {
    const digitConf = index < foundDigits.length ? confidence : 0;
    return { index, char, confidence: digitConf, isLowConfidence: digitConf < 80 };
  });

  return {
    id: 'card-' + Date.now() + '-' + Math.random().toString(36).slice(2, 7),
    rawPin: pin16,
    formattedPin: pin16.replace(/(\d{4})(?=\d)/g, '$1 '),
    wrappedPin: wrapPinString(pin16, activeFmt),
    carrier: activeFmt.name,
    carrierId: activeFmt.id,
    confidence,
    digits,
    status,
    errorMessage,
    timestamp: Date.now(),
    imageUrl,
    manualEditsCount: 0,
    qualityCheck: details.qualityCheck
  };
}
