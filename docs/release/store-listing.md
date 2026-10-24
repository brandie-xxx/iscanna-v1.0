# Store listing copy

Copy-paste text for Google Play Console and App Store Connect. Character limits are noted in
brackets; every field below fits its limit.

## Shared

- **App name:** iscanna
- **Tagline / subtitle:** Scan - Recharge
- **Category:** Tools (Google Play) · Utilities (App Store)
- **Price:** Free · No ads · No in-app purchases
- **Privacy policy URL:** where you host `docs/privacy-policy.md` (see the release checklist)
- **Support / contact:** @exxstatix on X, plus a support email

## Google Play

**Short description** [80 max]

> Scan a NetOne or Econet recharge card and dial the full code in one tap.

**Full description** [4000 max]

> Typing a 16-digit recharge PIN is slow and easy to get wrong. iscanna reads it for you.
>
> Point your camera at the PIN strip on a NetOne or Econet recharge card, or pick a photo, and
> iscanna reads all 16 digits on your phone. It wraps them in the right recharge code, *133*PIN#
> for NetOne or *121*PIN# for Econet, and hands it to your dialer in one tap.
>
> Scan, check, dial
> • Reads the PIN strip with on-device text recognition. No internet needed.
> • Picks the network from the card number, or choose NetOne or Econet yourself.
> • Flags any digit it isn't sure about so you can fix it before dialing.
> • Edit any digit with a simple keypad.
>
> Batches
> • Recharging several cards? Set how many to scan and iscanna queues each verified card.
> • Dial each card in turn, copy the codes, or export the list as CSV, JSON or text.
>
> Private by design
> • No account, no ads, no tracking.
> • Photos and PINs never leave your phone.
>
> Looks right
> • Clean, simple design that follows your phone's light or dark setting.
>
> iscanna is an independent app and is not affiliated with NetOne or Econet.

(Play shows plain text, so the short lines above act as section labels.)

**Graphics**

| Asset | File |
| --- | --- |
| App icon 512×512 | `store/android/icon-512.png` |
| Feature graphic 1024×500 | `store/android/feature-graphic-1024x500.png` |
| Phone screenshots 1080×1920 (5) | `store/android/phone-screenshots/` |

## App Store

**Subtitle** [30 max]

> Scan - Recharge

**Promotional text** [170 max]

> Point your camera at a recharge card's PIN strip and dial the full NetOne or Econet code in one
> tap. Batches, exports and dark mode included.

**Description** [4000 max]

> Typing a 16-digit recharge PIN is slow and easy to get wrong. iscanna reads it for you.
>
> Point your camera at the PIN strip on a NetOne or Econet recharge card, or choose a photo.
> iscanna reads all 16 digits on your phone and builds the full recharge code: *133*PIN# for
> NetOne or *121*PIN# for Econet. Tap Dial and the code is copied, ready to paste into Phone.
>
> • On-device text recognition: fast, and no internet needed
> • Detects the network from the card number
> • Flags uncertain digits and lets you fix them with a keypad
> • Batch mode for several cards: dial each in turn, copy all, or export CSV, JSON or text
> • No account, no ads, no tracking; photos and PINs never leave your phone
> • Follows your light or dark appearance
>
> iscanna is an independent app and is not affiliated with NetOne or Econet.

**Keywords** [100 max, comma separated, no spaces needed]

> recharge,airtime,voucher,scan,PIN,USSD,NetOne,Econet,Zimbabwe,top up,card,dial,prepaid

**Screenshots:** `store/ios/iphone-6.7-screenshots/` (1290×2796, accepted for the 6.9" slot).

**App Review notes** (paste into "Notes" for the reviewer)

> iscanna reads the 16-digit PIN from a Zimbabwean mobile recharge card using on-device text
> recognition and builds the network's USSD recharge code. iOS doesn't let apps open USSD codes,
> so on iPhone the Dial button copies the code and the user pastes it into Phone. To test without
> a card: tap Choose Photo and pick any photo containing a 16-digit number starting 4022 (NetOne)
> or 3630 (Econet), or open the Edit option on a result to type digits. No login is required.

## Privacy answers

- **Google Play Data safety:** "No data collected" and "No data shared". The camera image and
  PIN are processed on the device only and never leave it, which Play doesn't count as collection.
  Data is not encrypted in transit because nothing is transmitted.
- **App Store App Privacy:** "Data Not Collected".
- **Encryption (App Store):** already answered in the app (`ITSAppUsesNonExemptEncryption` = NO).

## Ratings and declarations

- **Content rating (IARC questionnaire):** Utility, no violence, no user-generated content, no
  sharing of location or personal info, no purchases → rated Everyone / 4+.
- **Target audience (Play):** 18 and over is simplest (avoids the Families policy), though the app is
  suitable for everyone.
- **Ads:** No. **App access:** all features available without login.
- **Government / financial features:** none (it doesn't move money; it builds a dial code).
