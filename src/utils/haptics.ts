// Haptic feedback utility using web vibration API
export const triggerHaptic = (type: 'light' | 'medium' | 'heavy' | 'success' | 'warning' | 'error' = 'light') => {
  if (typeof window === 'undefined' || !('vibrate' in navigator)) return;
  try {
    switch (type) {
      case 'light':
        navigator.vibrate(12);
        break;
      case 'medium':
        navigator.vibrate(28);
        break;
      case 'heavy':
        navigator.vibrate(50);
        break;
      case 'success':
        navigator.vibrate([15, 40, 20]);
        break;
      case 'warning':
        navigator.vibrate([30, 60, 30]);
        break;
      case 'error':
        navigator.vibrate([60, 90, 60, 90, 50]);
        break;
    }
  } catch {
    // Ignore if vibration fails or blocked by user agent
  }
};
