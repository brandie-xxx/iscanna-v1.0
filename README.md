# iscanna

Mobile app (Flutter, Android + iOS) that scans NetOne / Econet recharge cards, reads the
16-digit PIN **on-device** with Google ML Kit, wraps it in the carrier's USSD code
(`*133*PIN#`, `*121*PIN#`) and hands it to the phone dialer. Includes digit-by-digit
correction and a batch queue with CSV / JSON / TXT export.

See [PLAN.md](PLAN.md) for the roadmap and what still needs a real device.

## Run it

Requires Flutter 3.47+ (stable), plus Android Studio (Android) or Xcode 16+ (iOS).

```sh
flutter pub get
flutter run              # on a connected phone or emulator
```

The camera needs a real device; on an emulator use **Choose Photo**.

## Checks

```sh
flutter analyze
flutter test
dart format -l 120 lib test
```

CI (`.github/workflows/flutter.yml`) runs these checks on every push. APKs are only built
on request: Actions tab → *Flutter* → *Run workflow*. That uploads `iscanna-apk-arm64`
(almost all phones) and `iscanna-apk-older-phones` (32-bit devices); tick *Also build iOS*
for an unsigned iOS build, or *Build the Google Play bundle* for a signed `.aab`
(needs the upload-key secrets).

## Releasing and marketing

| Doc | What |
|---|---|
| [`docs/release/checklist.md`](docs/release/checklist.md) | Step-by-step Google Play and App Store release |
| [`docs/release/store-listing.md`](docs/release/store-listing.md) | Listing copy, keywords, privacy and rating answers |
| [`docs/privacy-policy.md`](docs/privacy-policy.md) | Privacy policy to host at a public URL |
| [`docs/marketing/launch-plan.md`](docs/marketing/launch-plan.md) | Audience, channels, demo script, launch week, post copy |
| `store/` | Store icon, feature graphic and framed screenshots for both stores |

## Layout

| Path | What |
|---|---|
| `lib/data/carriers.dart` | Carrier dial formats and card prefixes — **edit here to change codes** |
| `lib/services/pin_parser.dart` | OCR text → card (never invents digits) |
| `lib/services/ocr_service.dart` | ML Kit text recognition |
| `lib/services/dialer.dart` | `tel:` launch, clipboard |
| `lib/services/batch_export.dart` | CSV / JSON / TXT export |
| `lib/state/app_controller.dart` | App state and actions |
| `lib/screens/` | App shell with tab bar, Scan tab, Batch tab, About sheet |
| `lib/widgets/` | Scanner, result card, PIN editor, shared HIG components |
| `lib/theme/app_theme.dart` | Colour tokens and theme |

## Notes

- Photos never leave the phone; the app has no network permission requirements for scanning.
- iOS does not allow apps to open USSD codes, so on iOS **Dial** copies the code instead.
- Fonts: Inter for interface text, Sofia Sans for buttons and controls, Chivo for codes, Inter
  Tight for the keypad (SIL Open Font License: `assets/fonts/OFL-*.txt`).
- iscanna is not affiliated with NetOne or Econet.
