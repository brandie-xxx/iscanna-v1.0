import { ScannedCard, DigitConfidence } from '../types';
import { DEFAULT_FORMATS, detectCarrierByPin, wrapPinString } from '../data/carriers';

/**
 * Robust PIN extraction from text or OCR output
 */
export function processPinText(text: string, imageUrl?: string, customFormatId?: string): ScannedCard {
  // Clean non-digit characters except space and hyphens
  const rawDigitsOnly = text.replace(/[^\d]/g, '');

  let pin16 = '';
  let confidence = 85;
  let status: 'success' | 'warning' | 'error' = 'success';
  let errorMessage: string | undefined = undefined;

  // Search for any 16-digit continuous sequence
  const match16 = text.match(/\b\d{16}\b/);
  const matchGrouped = text.match(/(\d{4}[\s-]?){4}/);

  if (match16) {
    pin16 = match16[0];
    confidence = 98;
  } else if (matchGrouped) {
    pin16 = matchGrouped[0].replace(/[\s-]/g, '');
    confidence = 95;
  } else if (rawDigitsOnly.length >= 16) {
    // Take first 16 digits sequence
    pin16 = rawDigitsOnly.slice(0, 16);
    confidence = 88;
  } else if (rawDigitsOnly.length > 0) {
    // Incomplete PIN sequence
    pin16 = rawDigitsOnly.padEnd(16, '0');
    confidence = 65;
    status = 'warning';
    errorMessage = 'Incomplete PIN detected (less than 16 digits). Please inspect and edit manually.';
  } else {
    // No digits found
    pin16 = '0000000000000000';
    confidence = 30;
    status = 'error';
    errorMessage = 'No 16-digit PIN detected in image. Try re-aligning card under good lighting.';
  }

  // Detect Carrier
  const carrierFmt = detectCarrierByPin(pin16, DEFAULT_FORMATS);
  const activeFmt = customFormatId 
    ? (DEFAULT_FORMATS.find(f => f.id === customFormatId) || carrierFmt)
    : carrierFmt;

  // Format PIN into 4x4 blocks
  const formattedPin = pin16.replace(/(\d{4})(?=\d)/g, '$1 ');
  const wrappedPin = wrapPinString(pin16, activeFmt);

  // Generate digit-by-digit confidence array
  const digits: DigitConfidence[] = pin16.split('').map((char, index) => {
    // Add artificial variation for realistic testing display if needed
    let digitConf = confidence;
    if (confidence < 90 && (index === 10 || index === 11)) {
      digitConf = Math.min(confidence - 15, 60);
    } else {
      digitConf = Math.min(100, Math.max(70, confidence + Math.floor((index % 3) * 2)));
    }
    return {
      index,
      char,
      confidence: Math.round(digitConf),
      isLowConfidence: digitConf < 80
    };
  });

  return {
    id: 'card-' + Date.now() + '-' + Math.random().toString(36).substr(2, 5),
    rawPin: pin16,
    formattedPin,
    wrappedPin,
    carrier: activeFmt.name.replace(' Recharge', '').replace(' Direct', '').replace(' Airtime', '').replace(' Mobile', ''),
    carrierId: activeFmt.id,
    confidence: Math.round(confidence),
    digits,
    status,
    errorMessage,
    timestamp: Date.now(),
    imageUrl,
    manualEditsCount: 0,
    qualityCheck: {
      resolutionOk: true,
      lightingOk: true,
      blurDetected: confidence < 80
    }
  };
}
