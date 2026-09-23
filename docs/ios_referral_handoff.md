# iOS referral implementation and release checks

## Audit

Source: `final_iOS`. The working tree already contained changes to
`.flutter-plugins-dependencies`, `ios/Flutter/AppFrameworkInfo.plist`, `ios/Podfile`,
`ios/Podfile.lock`, `ios/Runner.xcodeproj/project.pbxproj`,
`ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`,
`lib/presentation/web_landing/screens/web_landing_screen.dart`, and
`lib/presentation/web_landing/widgets/footer_section.dart`. These changes were
preserved, not implemented by this task.

- Runner already associates filmytell.com and www.filmytell.com. Debug uses
  developer mode; release/profile use normal Associated Domains.
- AASA already identifies `2KXZ4D5XSK.com.filmytell.ott` and includes `/register*`
  and `/ott/register*`, alongside existing content routes. No AASA changes.
- Flutter built-in link routing is disabled. The local `uni_links` plugin feeds
  `DeepLinkService` through its initial URI and URI stream. Targets queue until
  navigation is available. Existing movie, series, shorts and custom schemes
  remain in that router.
- Working-tree native startup uses FlutterSceneDelegate and implicit-engine
  registration. The local plugin only implemented AppDelegate events before
  this change; it now also receives scene connection and URL/activity events.
- ReferralService already stores `pendingReferralCode` in SharedPreferences.
  LoginCard displays the pending referral. UserProvider submits it with OTP
  verification (`userNew/VerifyOtpJWT`, query `referralCode`) and registration
  (`user/RegisterUser`, existing `refferedBy` model field). Both clear pending
  state after their existing successful authentication handling.
- No backend source is present. Referral generation, promoter association and
  server validation cannot be audited here. Existing client contracts are reused;
  no assumptions were added about eligibility or referral rewards.
- Firebase core/messaging already exist. No deferred-link provider was found.
  Existing iOS deferred logic attempted an automatic browser clipboard write
  followed immediately by redirect, and accepted arbitrary short clipboard text.
  Firebase configuration and services remain unchanged.

## Changes (existing files)

| File | Reason and change |
| --- | --- |
| `third_party/uni_links/ios/Classes/UniLinksPlugin.h` | Adopt scene lifecycle protocol when available in Flutter headers. |
| `third_party/uni_links/ios/Classes/UniLinksPlugin.m` | Feed cold scene connection, Universal Links and custom URL events into existing initial-link/event channels; retain AppDelegate support. |
| `lib/app/core/services/DeepLinkService.dart` | Use iOS referral extraction within existing register routing; reject unsupported incoming links before persisting referrals on iOS. |
| `lib/app/core/services/referral_service.dart` | Decode canonical iOS query exactly once; accept nonempty transport values for backend validation; restrict clipboard recovery to Filmytell HTTPS register URLs; share recovery across callers; preserve newer direct links and persisted pending values. |
| `lib/app/pages/sign in page/LoginCard.dart` | Wait for iOS recovery before loading the existing referral display. |
| `lib/app/provider/userProvider.dart` | Wait for iOS recovery before building existing registration/OTP requests. |
| `web/index.html` | For iOS register referrals, show explicit copy/install action; await clipboard success before App Store redirect; offer retry and explicit install-without-copy fallback. Android branch unchanged. |

New files: this report, `test/ios_referral_handoff_test.dart`, and
`test/ios_referral_web_handoff_test.cjs`.

Backend changes required: **NO for the existing client referral transport**.
Backend referral validation/association still requires confirmation by its owner.
No API, SDK, package version, Firebase configuration or signing change was made.

## Deferred flow and limitations

The user selected repair of the existing clipboard handoff. Safari shows **Copy
referral & install**. That user action copies a canonical URL containing the
encoded referral, then opens the existing App Store listing. On first launch,
existing startup recovery reads the clipboard; login and request construction
await the same recovery. The code persists until the existing successful
registration/OTP flow clears it. Completed recovery is recorded so consumed
clipboard referrals do not replay on later launches.

This is a user-assisted deferred handoff, not App Store parameter transmission.
It requires successful copy, an unchanged clipboard, and paste permission.
Denied/overwritten clipboard contents cannot be recovered automatically. The
page explains this and allows retry; after installing, the user can reopen the
original referral link. A read exception does not persist a completed check and
can be retried on a later app launch. Empty or unrelated clipboard text creates
no referral. No fingerprinting or backend matching was introduced.

Deploy the updated website and ship an iOS build containing these changes before
performing acceptance testing. The currently published App Store binary cannot
be changed by editing this repository.

## Feature safety

- Existing iOS media player: UNCHANGED.
- Existing iOS payment gateway / Apple IAP: UNCHANGED.
- Existing iOS gifting logic: NOT INTRODUCED (existing iOS gift-route guard retained).
- Existing authentication: PRESERVED, with referral recovery awaited.
- Existing navigation: PRESERVED; no router replacement.
- Existing Universal Links: existing routes/configuration PRESERVED; scene delivery added.
- Existing APIs: PRESERVED.

## Device acceptance matrix

These are release gates, not claims of passing device tests. Run on a signed iOS
build using links tapped from Notes/Messages and verify the actual outgoing
existing auth request and server attribution. Do not use production purchases
for payment regression testing; use the existing StoreKit test/sandbox setup.

| Scenario | Device result |
| --- | --- |
| Installed + cold start | NOT RUN |
| Installed + foreground | NOT RUN |
| Installed + background | NOT RUN |
| Not installed + website + App Store + first launch | NOT RUN |
| Normal launch with empty/unrelated clipboard | NOT RUN |
| Existing Universal Link `/movie/6` | NOT RUN |
| Media playback / controls / content navigation | NOT RUN |
| Existing iOS payment | NOT RUN |

Use `https://filmytell.com/register?referralCode=FILMY-XX-60E7`; expect
`FILMY-XX-60E7`. Also test empty/missing code, encoded `+`, `%`, `&`, denied paste,
failed copy, clipboard overwrite, failed auth retaining code, successful auth
clearing code, and a newer direct referral while paste permission is open.

References:
- [Flutter scene plugin lifecycle](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)
- [Apple Universal Links diagnostics](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links)

## Automated validation results

- `flutter test --no-pub --reporter expanded test/ios_referral_handoff_test.dart`:
  **4 passed** (encoding/backend query transport, clipboard rejection,
  unsupported links, shared recovery/persistence/consumption).
- `node --test test/ios_referral_web_handoff_test.cjs`: **5 passed** (gesture,
  awaited copy, denied copy, empty code, normal content route, Android fallback).
- Existing referral/deep-link suites: **13 passed, 1 failed**. Failure is the
  existing `/register/FILMY-XX-60E7` path-code assertion at
  `test/deep_link_service_test.dart:145`. The original parser returns from its
  first register branch before reaching its duplicate path-code fallback.
  This task leaves that unrelated existing behavior unchanged; the requested
  `?referralCode=` route passes.
- iOS Objective-C plugin: `clang -fsyntax-only` with installed iPhoneOS SDK,
  arm64 iOS 15 target, and Flutter framework headers: **passed**. This is not
  a full signed application build or runtime scene-delivery test.
- Targeted Flutter analysis: no errors; 16 existing-style warnings/info across
  existing router/login/provider code (unused imports, naming, deprecations,
  async context usage and redundant assertions). No diagnostics in the referral
  service or new test file. Unrelated cleanup was not performed.
- `git diff --check`: passed. Final diff/status reviewed; pre-existing changes
  retained separately from this task's seven modified files and three new files.
- Live AASA verification unavailable: web fetch failed and shell DNS lookup
  could not resolve filmytell.com. Repository AASA and entitlement settings were
  inspected only; production association is not certified by this report.
