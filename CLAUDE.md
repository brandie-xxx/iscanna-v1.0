# Project notes for Claude

## Text casing (applies to all exxstatix projects)
- Use standard, professional casing everywhere: sentence case for labels, headers and
  messages; title case only where it's conventional (screen titles, button labels).
- Never force uppercase (no `.toUpperCase()` on UI text, no all-caps literals, no
  `textTransform: uppercase`). Acronyms keep their normal form (PIN, USSD, CSV).
- Only switch to all-caps or all-lowercase when the owner explicitly asks for it.

## Typefaces (iscanna)
- Inter: interface text (headings, labels, body).
- Sofia Sans: buttons and controls (buttons, tab bar, radio labels, sheet actions).
  Exception: the CSV / JSON / TXT export choice uses Inter.
- Chivo: codes, PINs and other figures.
- Inter Tight (extra bold): the digits on the Edit PIN keypad.

## Naming
- The app is called "iscanna". The "1.0" appears only in the header wordmark.
- Tagline: "Scan - Recharge".
- The app is cross-platform: don't mention iPhone (or any one platform) in UI copy.

## Credit
- The `*exxstatix` credit links to https://x.com/exxstatix and stays subtle (small, muted).

## Colours (iscanna)
- The app follows the phone's light/dark setting. Take colours from `AppColors` (backed by
  `AppPalette.light` / `AppPalette.dark`); never hard-code them, and use `onAccent` for content on
  a filled accent background.
