import confetti from 'canvas-confetti';
import { triggerHaptic } from './haptics';

// Hands the USSD code to the phone dialer. Note: iOS refuses tel: links containing * or #.
export function dialUssd(wrappedPin: string) {
  triggerHaptic('success');
  confetti({
    particleCount: 50,
    spread: 70,
    origin: { y: 0.65 },
    colors: ['#7dd3fc', '#38bdf8', '#bae6fd', '#f4f4f5']
  });
  window.location.href = `tel:${encodeURIComponent(wrappedPin)}`;
}

export async function copyText(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}
