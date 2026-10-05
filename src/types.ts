export interface DigitConfidence {
  index: number;
  char: string;
  confidence: number; // 0 - 100
  isLowConfidence?: boolean;
}

export interface FormatConfig {
  id: string;
  name: string;
  prefix: string;
  suffix: string;
  isDefault?: boolean;
  carrierPrefixes?: string[]; // e.g. ['4022'] for NetOne
  description?: string;
}

export interface ScannedCard {
  id: string;
  rawPin: string; // 16 digits without formatting
  formattedPin: string; // e.g., "4022 6224 0582 1561"
  wrappedPin: string; // e.g., "*133*4022622405821561#"
  carrier: string; // e.g., "NetOne", "Econet", "Telecel", "Custom"
  carrierId: string;
  confidence: number; // 0 - 100
  digits: DigitConfidence[];
  status: 'success' | 'warning' | 'error';
  errorMessage?: string;
  timestamp: number;
  imageUrl?: string;
  batchId?: string;
  manualEditsCount?: number;
  qualityCheck?: {
    resolutionOk: boolean;
    lightingOk: boolean;
    blurDetected: boolean;
  };
}

export interface BatchSession {
  id: string;
  name: string;
  createdAt: number;
  cards: ScannedCard[];
  formatId: string;
}

export interface SampleCardScenario {
  id: string;
  title: string;
  subtitle: string;
  expectedPin: string;
  carrier: string;
  confidence: number;
  imageSvgUrl: string;
  hasDamage?: boolean;
  blurLevel?: 'none' | 'slight' | 'heavy';
  damagedDigitIndex?: number;
}
