# Project notes for Claude

## Text casing (applies to all exxstatix projects)
- Use standard, professional casing everywhere: sentence case for labels, headers and
  messages; title case only where it's conventional (screen titles, button labels).
- Never force uppercase (no `.toUpperCase()` on UI text, no all-caps literals, no
  `textTransform: uppercase`). Acronyms keep their normal form (PIN, USSD, CSV).
- Only switch to all-caps or all-lowercase when the owner explicitly asks for it.

## Typefaces (iscanna)
- Inter: interface text (headings, labels, body).
- Sofia Sans: buttons and controls (buttons, tab bar, segmented controls, keypad, sheet actions).
  Exception: the CSV / JSON / TXT export choice uses Inter.
- Chivo: codes, PINs and other figures.

## Credit
- The `*exxstatix` credit links to https://x.com/exxstatix and stays subtle (small, muted).
