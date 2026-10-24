# Release checklist

What's already done in the code, and the steps only you can do (accounts, keys, uploads).

## Already done

- App ID `com.exxstatix.iscanna` on Android and iOS (permanent once published).
- Version `1.0.0+1` in `pubspec.yaml`. Raise the `+N` build number for every store upload.
- Release builds are shrunk (R8) and split per CPU; target SDK 36.
- Android release signing reads your upload key from `android/key.properties` (local) or GitHub
  secrets (CI), and falls back to the debug key when neither is set.
- The Flutter workflow can build the Play bundle (`.aab`): Actions → Flutter → Run workflow →
  tick "Build the Google Play bundle".
- App icon, launch screens, store icon, feature graphic and screenshots are in `store/`.
- iOS: iPhone-only, portrait, camera and photo permission messages, encryption question
  pre-answered.
- Privacy policy (`docs/privacy-policy.md`) and listing copy (`docs/release/store-listing.md`).

## Before either store

1. **Publish the privacy policy at a public URL.** Easiest options:
   - GitHub Pages: repository Settings → Pages → deploy from `main`, folder `/docs`. The policy
     is then at `https://<user>.github.io/iscanna-v1.0/privacy-policy`. (Pages on a private
     repository needs a paid GitHub plan.)
   - Or paste it into a free Google Sites or Notion page.
2. Replace the placeholder support email at the bottom of the policy.
3. Test the release build on two or three real phones with real cards from both networks.

## Google Play

1. **Developer account.** Sign up at play.google.com/console ($25 one-off, identity check).
2. **Create the upload key** once, on your own computer (needs Java's `keytool`):
   ```sh
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias upload
   ```
   Keep the `.jks` file and both passwords somewhere safe (a password manager). If you lose them,
   Google can reset the upload key, but it takes a support request.
3. **Add the key to GitHub** (repository Settings → Secrets and variables → Actions):
   - `ANDROID_KEYSTORE_BASE64`: output of `base64 -w0 upload-keystore.jks`
     (macOS: `base64 -i upload-keystore.jks`)
   - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`: the passwords you chose
   - `ANDROID_KEY_ALIAS`: `upload`
4. **Build the bundle:** Actions → Flutter → Run workflow, tick "Build the Google Play bundle".
   Download `iscanna-play-bundle` (it contains `app-release.aab`).
5. **Create the app** in Play Console: name iscanna, app (not game), free.
6. **Fill in the app content pages** using `store-listing.md`: privacy policy URL, ads (none),
   app access (no login), content rating, target audience, data safety, and the store listing
   with the graphics in `store/android/`.
7. **Turn on Play App Signing** (default for new apps) and upload the `.aab`.
8. **Testing first.** New personal developer accounts must run a closed test with at least 12
   testers opted in for 14 days in a row before production. Recruit them early (friends, family,
   a WhatsApp group) and add their Gmail addresses to a closed testing track. Check Play
   Console's dashboard for the current numbers; Google has changed them before.
9. **Apply for production** from the dashboard once the test period is met, then roll out.

## App Store

1. **Developer account.** Apple Developer Program ($99 a year), enrolled as an individual or
   organisation.
2. **A Mac with Xcode** is the usual route. Without one, a cloud build service (Codemagic,
   Bitrise, or GitHub Actions on macOS with signing set up) can build and upload for you.
3. **App Store Connect:** create the app with bundle ID `com.exxstatix.iscanna`, name iscanna,
   primary language English, SKU `iscanna`.
4. **Build and upload** (on a Mac):
   ```sh
   flutter build ipa --release
   ```
   then open `build/ios/archive/Runner.xcarchive` in Xcode → Distribute App → App Store Connect,
   or upload the `.ipa` with Apple's Transporter app. Xcode handles signing if you sign in with
   your Apple ID and pick your team in Runner → Signing & Capabilities.
5. **Listing:** subtitle, promotional text, description, keywords and review notes from
   `store-listing.md`; screenshots from `store/ios/iphone-6.7-screenshots/`; privacy policy URL;
   App Privacy → "Data Not Collected"; age rating 4+.
6. **TestFlight** (optional, recommended): install the build on your own iPhone before review.
7. **Submit for review.** The review notes explain that iOS can't open USSD codes, so Dial copies
   the code; that saves a round of questions.

## Each new version

1. Bump `version` in `pubspec.yaml` (for example `1.0.1+2`) and `kAppVersion` in
   `lib/screens/about_sheet.dart`.
2. Run the workflow with the Play bundle option; upload to Play. Build and upload the iOS archive.
3. Write short release notes ("What's new").
