# Android TV Support

This Flutter application supports Android mobile, tablet, Android TV, Google TV,
and Chromecast with Google TV from the same codebase.

## Native Android Configuration

- `android.software.leanback` is declared as optional so mobile installs remain
  supported.
- `android.hardware.touchscreen`, location, GPS, network location, and telephony
  are optional so TV devices without those features can install the app.
- The main Flutter activity exposes both `LAUNCHER` and `LEANBACK_LAUNCHER`
  intent filters.
- The app declares `android:banner="@drawable/tv_banner"` for Android TV launcher
  surfaces.
- TV-qualified resources live under `android/app/src/main/res/values-television`.
- A density-qualified launcher banner is provided at
  `android/app/src/main/res/drawable-xhdpi/tv_banner.png` at 320x180 px, with
  the original higher-resolution artwork retained in `drawable/tv_banner.png`.

## Flutter TV Input

- `OttTvAppShell` wraps non-mobile routes with global keyboard/remote handling.
- Supported remote keys include D-pad arrows, select/enter/space/game button A,
  back/escape/browser back/game button B, menu/start, and media play/pause.
- `OttTvFocus` provides reusable focus, activation, scroll-into-view, semantic
  labels, scale animation, border, and glow behavior.
- Existing mobile touch behavior is preserved because TV wrappers are bypassed
  on mobile breakpoints.

## Player Remote Behavior

- Select/enter/play-pause toggles playback.
- Left/right seeks backward/forward by 10 seconds.
- Back exits playback after saving progress.
- Existing resume, continue-watching, offline playback, watermark, and security
  flows are preserved.

## Play Store TV Review Checklist

Verify on real devices before production upload:

- Android mobile and tablet still launch, login, browse, pay, and play content.
- Android TV launcher shows the TV banner.
- D-pad focus is visible on navigation, content cards, search results, bookmarks,
  dialogs, player overlays, login/OTP, wallet, and profile actions.
- Focus never disappears after page transitions, dialogs, or back navigation.
- Remote back closes dialogs/pages and exits from the home screen as expected.
- Video playback responds to select/play-pause/left/right/back.
- Text input works with the Android TV IME.
- Overscan-safe margins look correct on Android TV emulator, Google TV,
  Chromecast with Google TV, Mi TV, Sony Android TV, and Fire TV where relevant.

## Release Signing

`android/key.properties` is intentionally ignored by Git. For Play Store builds,
fill the local file with the real keystore passwords and rebuild:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../filmytell-keystore.jks
```
