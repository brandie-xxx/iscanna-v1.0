import { FormatConfig, SampleCardScenario } from '../types';

export const DEFAULT_FORMATS: FormatConfig[] = [
  {
    id: 'netone',
    name: 'NetOne',
    prefix: '*133*',
    suffix: '#',
    isDefault: true,
    carrierPrefixes: ['4022', '133', '40'],
    description: 'NetOne Zimbabwe (*133*PIN#)'
  },
  {
    id: 'econet',
    name: 'Econet',
    prefix: '*150*',
    suffix: '#',
    carrierPrefixes: ['3630', '150', '36'],
    description: 'Econet Wireless (*150*PIN#)'
  }
];

export function detectCarrierByPin(pin: string, formats: FormatConfig[] = DEFAULT_FORMATS): FormatConfig {
  const cleanPin = pin.replace(/\D/g, '');
  
  for (const fmt of formats) {
    if (fmt.carrierPrefixes && fmt.carrierPrefixes.length > 0) {
      for (const prefix of fmt.carrierPrefixes) {
        if (cleanPin.startsWith(prefix)) {
          return fmt;
        }
      }
    }
  }

  // Default to NetOne or first available
  return formats.find(f => f.isDefault) || formats[0];
}

export function wrapPinString(pin: string, format: FormatConfig): string {
  const cleanPin = pin.replace(/\D/g, '');
  return `${format.prefix}${cleanPin}${format.suffix}`;
}

// Generate minimalist baby blue + darker grey SVG data URLs for sample recharge cards
export function createSampleCardDataUrl(pin: string, carrierName: string, subtext: string, isDamaged: boolean = false): string {
  const pinGrouped = pin.match(/.{1,4}/g)?.join(' ') || pin;
  
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360">
    <!-- Dark grey container -->
    <rect x="8" y="8" width="624" height="344" rx="16" fill="#181920" stroke="#2b2c37" stroke-width="1.5" />
    
    <!-- Top Header Bar with carrier -->
    <rect x="24" y="24" width="592" height="56" rx="10" fill="#111216" />
    <text x="44" y="58" fill="#7dd3fc" font-family="'Geist Pixel', monospace" font-weight="700" font-size="18" letter-spacing="0">${carrierName.toUpperCase()} RECHARGE</text>
    <text x="596" y="58" fill="#71717a" font-family="'Geist Pixel', monospace" font-size="13" text-anchor="end">iscanna1.0</text>
    
    <!-- Instructions -->
    <text x="28" y="118" fill="#9ca3af" font-family="'Geist Pixel', monospace" font-size="13">Scratch strip to reveal 16-digit voucher PIN</text>
    
    <!-- Scratch Strip Background -->
    <rect x="24" y="136" width="592" height="104" rx="12" fill="#111216" stroke="#2b2c37" stroke-width="1" />
    <rect x="36" y="148" width="568" height="80" rx="8" fill="#1e1f27" />
    
    <!-- Exposed 16-Digit PIN in tabular typography -->
    <text x="320" y="196" fill="#7dd3fc" font-family="'Geist Pixel', monospace" font-weight="700" font-size="24" letter-spacing="4" text-anchor="middle">${pinGrouped}</text>
    
    ${isDamaged ? `
      <!-- Scratch damage mask simulation -->
      <rect x="350" y="156" width="28" height="64" rx="4" fill="#111216" />
      <text x="364" y="194" fill="#71717a" font-family="'Geist Pixel', monospace" font-weight="bold" font-size="16" text-anchor="middle">?</text>
    ` : ''}

    <!-- Bottom Indicator -->
    <text x="320" y="294" fill="#7dd3fc" font-family="'Geist Pixel', monospace" font-size="13" text-anchor="middle">${subtext}</text>
  </svg>`;

  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

export const SAMPLE_SCENARIOS: SampleCardScenario[] = [
  {
    id: 'sample-netone',
    title: 'NetOne (*133*)',
    subtitle: 'Clear 16-digit voucher PIN',
    expectedPin: '4022622405821561',
    carrier: 'NetOne',
    confidence: 99,
    imageSvgUrl: createSampleCardDataUrl('4022622405821561', 'NetOne', 'Dial *133*PIN# to recharge', false)
  },
  {
    id: 'sample-econet',
    title: 'Econet (*150*)',
    subtitle: 'High accuracy 16-digit voucher',
    expectedPin: '3630146682113274',
    carrier: 'Econet',
    confidence: 96,
    imageSvgUrl: createSampleCardDataUrl('3630146682113274', 'Econet', 'Dial *150*PIN# to recharge', false)
  },
  {
    id: 'sample-netone-damaged',
    title: 'NetOne (Damaged Digit)',
    subtitle: 'Simulated scratch on 1 digit (4022 6224 05?2 1561)',
    expectedPin: '4022622405821561',
    carrier: 'NetOne',
    confidence: 76,
    hasDamage: true,
    damagedDigitIndex: 10,
    imageSvgUrl: createSampleCardDataUrl('4022622405821561', 'NetOne', 'Tap Edit to correct blurred digit', true)
  }
];
