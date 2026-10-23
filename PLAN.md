# iscanna1.0 — Flutter mobile app plan

Port iscanna1.0 from a React web app + Node/Gemini server to a **Flutter mobile app
(Android + iOS)**. Keep the existing design (dark grey `#111215`, baby blue `#7dd3fc`,
Geist Pixel type, card panels with hairline borders), polished for native mobile.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Platforms | Android + iOS, phone-first | Product is mobile only |
| OCR | On-device, Google ML Kit text recognition | Offline, free, PINs never leave the phone, no server or API key |
| Backend | None — the Node/Express/Gemini server is removed | Nothing left for it to do |
| Web app | Removed (recoverable from git history) | Mobile only |
| State | `ChangeNotifier` + `ListenableBuilder` (no state library) | App is one screen with two tabs; keep dependencies small |
| Dialing | `tel:` link with `#` encoded → opens the dialer pre-filled; user presses call | Safe (no silent calls, no CALL_PHONE permission). iOS blocks USSD links, so iOS falls back to Copy |
| Font | Geist Pixel bundled as an asset (OFL) | Works offline; no runtime font download |

## Architecture

```
lib/
  main.dart                    App entry, theme, portrait lock
  theme/app_theme.dart         Colour tokens + ThemeData (single source for the design)
  models/                      CarrierFormat, ScannedCard, DigitConfidence, SampleScenario
  data/carriers.dart           NetOne/Econet formats, prefix detection, PIN wrapping, samples
  services/
    pin_parser.dart            Text → ScannedCard (pure Dart, ported from ocrFallback.ts)
    ocr_service.dart           ML Kit wrapper: image file → text (+ confidence when available)
    dialer.dart                tel: launch, clipboard
    batch_export.dart          CSV / JSON / TXT builders (pure Dart) + share sheet
  state/app_controller.dart    All app state and actions (port of App.tsx logic)
  widgets/                     One widget per web component:
    app_header, navigation_control_bar, sample_card_selector, sample_card_art,
    camera_capture, card_results_view, batch_processing_view, digit_correction_sheet,
    panel (shared card container), pressable (shared tap/haptic button)
test/                          Unit tests for parser, carriers, export, controller + widget smoke test
```

Behaviour carried over from the audited web app (all fixes kept):
never fabricate a PIN; partial or low-confidence reads are "Review Needed" and cannot be dialed
until fixed; carrier label and wrapped code always agree; editor Cancel discards edits;
batch dedupes by PIN and only auto-queues verified cards; stale scans are ignored.

## Phases

### Phase 1 — Foundation ✅ done
- Remove web/server code; scaffold Flutter project (`android/`, `ios/`).
- Theme tokens, models, carrier data, PIN parser, export builders.
- Unit tests for all pure logic.
- **Exit:** `flutter analyze` clean, `flutter test` green.

### Phase 2 — Screens ✅ done
- Header, mode/carrier control bar, sample presets (sample cards drawn natively).
- Scanner panel: live camera preview with corner guides, capture, gallery upload,
  re-scan, target-count stepper and progress.
- Result panel: status badge, wrapped USSD code, PIN, Edit / Dial / Copy / Batch.
- Digit editor as a bottom sheet with the 4×4 digit grid and keypad.
- Batch tab: list, dial/edit/remove, CSV/JSON/TXT export via share sheet, copy all.
- Polish: haptics, confetti on dial, animated transitions, safe areas, 44pt touch targets,
  accessibility labels, large-text tolerance.
- **Exit:** widget smoke test passes; debug APK builds in CI.

### Phase 3 — Platform wiring ✅ done (APK build verified in CI)
- Android: camera permission, `tel:` query intent, minSdk for ML Kit, app label.
- iOS: camera/photo usage strings, min iOS version for ML Kit, `tel` scheme query.
- GitHub Actions: analyze + test + debug APK artifact on every push.

### Phase 4 — Device validation *(needs a real phone — you)*
- Scan 20+ real NetOne/Econet cards in different light; record read accuracy.
- Confirm dial codes (**Econet may be `*121*PIN#`, not `*150*`**) and the
  `4022`/`3630` card prefixes; update `lib/data/carriers.dart`.
- Tune: crop to the frame guide before OCR if background text causes misreads.
- **Exit:** ≥95% of clean cards read correctly with no manual edits.

### Phase 5 — Release *(you, with accounts)*
- App icon and splash; final bundle ID (currently `com.exxstatix.iscanna`).
- Android: upload keystore + signed release build → Play Console internal testing.
- iOS: Apple developer account, signing, TestFlight.
- Store listing, privacy policy (camera used on-device only; no data collected).

## Risks

| Risk | Mitigation |
|---|---|
| ML Kit misreads scratched digits | Per-digit review flow; Dial blocked until PIN verified |
| iOS refuses USSD `tel:` links | Detect iOS, show "Copy code" as the primary action with a hint |
| Unverified dial codes / prefixes | Called out in Phase 4; single place to change |
| No device in CI | Pure logic unit-tested; widget test for UI; on-device testing in Phase 4 |
