# Android TV Release and Navigation Checklist

## Release identity

- Package/application ID: `com.filmytell.ott` for both `mobile` and `tv`.
- Version source: `pubspec.yaml` (`1.0.16+33` for this update).
- Signing source: the existing `android/key.properties` and existing keystore.
- Store strategy: upload to the existing Play listing. The TV artifact retains
  the phone launcher and uses optional Leanback/touchscreen declarations, so it
  supports both Android phone and Android TV. Use a separate listing only if the
  product intentionally needs separate identity, reviews, rollout, and data.

## Screen navigation map

| Screen or overlay | Initial focus | D-pad behavior | Back behavior |
| --- | --- | --- | --- |
| Splash/onboarding/language | First enabled action or language | Traverse visible actions; focused item scrolls into view | Previous step or system route |
| Login/OTP | Mobile-number field, then OTP field | Center opens the in-app D-pad keypad; ordered digits, backspace, Done, resend, submit | Standard page Back; keypad is non-modal |
| Home/movies/series/mini-series | Side rail or first content action | Up/down between rows; left/right within rows | Root exit confirmation |
| Details | Hero play action | Actions then content rails/episodes | Return and preserve route state |
| Search/results | Search field | Field, clear/submit, then result cards | Keyboard first, then home/page |
| Categories/languages/settings | First enabled option | Ordered vertical traversal | Close selection/page |
| Watchlist/favourites/continue watching/downloads | First card or recovery action | Grid/row traversal with ensure-visible | Return/home |
| Profile/subscription/wallet/help/notifications | First enabled tile/action | Ordered actions and form fields | Close dialog/page |
| Dialogs/dropdowns/errors | First safe action (normally Cancel/Retry) | Traverse actions inside overlay | Close overlay |
| Player | Player surface or visible control | Left/right seek 10 s; up/down traverse visible controls; media keys play/pause/seek | Hide controls first, then exit and save progress |

## Build commands and outputs

```powershell
flutter test
flutter analyze
flutter build appbundle --release --flavor mobile -t lib/main_mobile.dart --dart-define=FLAVOR=mobile
flutter build appbundle --release --flavor tv -t lib/main_tv.dart --dart-define=FLAVOR=tv
```

Expected outputs:

- Mobile: `build/app/outputs/bundle/mobileRelease/app-mobile-release.aab`
- TV: `build/app/outputs/bundle/tvRelease/app-tv-release.aab`

## Remote-only manual test matrix

- Run cold/warm starts at 1280x720, 1920x1080, and a 4K display profile.
- Navigate every side-rail item, row, grid, tab, dialog, dropdown, and error
  recovery action using only D-pad, OK, and Back.
- Repeat with rapid D-pad input; verify no double activation or focus loss.
- Confirm focus is visible, remains inside the active overlay, automatically
  scrolls into view, and restores after returning from details/player/dialogs.
- Test login, OTP, validation, TV keypad open/backspace/Done, search IME clear/submit,
  empty queries, and no-results recovery.
- Test signed playback, resume, expiry/retry, buffering, network loss/recovery,
  Play/Pause, 10-second seek, dedicated rewind/fast-forward, controls auto-hide,
  audio/subtitle/episode choices, Back, background/foreground, and wakelock.
- Test loading, empty, offline, image-error, API-error, and low-memory restore.
- Regression-test phone touch navigation, authentication, payments, deep links,
  notifications, downloads, mini-series, and playback.
- Test at least one physical Android TV/Google TV device before production.

## Play Console checklist

- Confirm the package, upload certificate, and application signing certificate
  match the existing listing; never replace the signing key for this update.
- Confirm version code 33 is greater than the highest active artifact in every
  track. Increase it before building if Play Console already contains 33+.
- Upload the generated release AAB manually; do not upload a debug-signed build.
- Verify target API 35, device catalog TV availability, pre-launch report,
  release integrity, and that no required hardware feature filters TVs out.
- Supply a readable 320x180 TV banner and TV screenshots without transparent
  padding; verify the launcher presentation on a physical television.
- Review data safety, content rating, ads, privacy policy, account deletion,
  tester access, and regional/content licensing declarations.
- Use staged rollout and monitor Android vitals, playback failures, login/OTP,
  ANRs, crashes, and device-specific layout/focus reports.

## Known verification limits

- Emulator and physical-device behavior cannot be proven by source analysis.
- Play Console's highest version code and device catalog require Console access.
- Release success requires valid local signing credentials and network/cache
  availability for all Gradle dependencies.
- The repository currently has legacy analyzer warnings; release acceptance
  should require no new errors or TV-related warnings, tracked separately from
  that baseline.
