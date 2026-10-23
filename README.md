# iscanna1.0

Mobile app (Flutter, Android + iOS) that scans NetOne / Econet recharge cards, reads the
16-digit PIN **on-device** with Google ML Kit, wraps it in the carrier's USSD code
(`*133*PIN#`, `*150*PIN#`) and hands it to the phone dialer. Includes digit-by-digit
correction and a batch queue with CSV / JSON / TXT export.

See [PLAN.md](PLAN.md) for the roadmap and what still needs a real device.

## Run it

Requires Flutter 3.47+ (stable), plus Android Studio (Android) or Xcode 16+ (iOS).

```sh
flutter pub get
flutter run              # on a connected phone or emulator
```

The camera needs a real device; on an emulator use **Select Card Photo** or the sample presets.

## Checks

```sh
flutter analyze
flutter test
dart format -l 120 lib test
```

CI (`.github/workflows/flutter.yml`) runs these on every push and uploads a debug APK
as the `iscanna-debug-apk` artifact. An unsigned iOS build can be started manually
from the Actions tab (*Run workflow* → *Also build iOS*).

## Layout

| Path | What |
|---|---|
| `lib/data/carriers.dart` | Carrier dial formats, card prefixes, sample cards — **edit here to change codes** |
| `lib/services/pin_parser.dart` | OCR text → card (never invents digits) |
| `lib/services/ocr_service.dart` | ML Kit text recognition |
| `lib/services/dialer.dart` | `tel:` launch, clipboard |
| `lib/services/batch_export.dart` | CSV / JSON / TXT export |
| `lib/state/app_controller.dart` | App state and actions |
| `lib/widgets/`, `lib/screens/` | UI |
| `lib/theme/app_theme.dart` | Colour tokens and theme |

## Notes

- Photos never leave the phone; the app has no network permission requirements for scanning.
- iOS does not allow apps to open USSD codes, so on iPhone **Dial** copies the code instead.
- Font: Geist Pixel (SIL Open Font License, `assets/fonts/OFL.txt`).
