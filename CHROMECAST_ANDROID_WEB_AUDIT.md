# FilmyTell Chromecast Android/Web Audit

## 1. Executive Summary
This document presents the complete technical audit of the Google Cast (Chromecast) implementation across the FilmyTell Android mobile application, Web application, and Custom Web Receiver.

* **Target Registered Custom Receiver Application ID:** `0C452C93` (Google Cast Developer Console registered, target device Google TV "Ready For Testing").
* **Configured Receiver URL:** `https://filmytell.com/cast/index.html`
* **Base Branch:** `final_ott` | **Working Branch:** `feature/chromecast-support`

### High-Level Summary:
1. **Android Sender (`[NOT IMPLEMENTED / MOCK ONLY]`):**
   No native Google Cast Android Sender SDK (`com.google.android.gms:play-services-cast-framework`), MediaRouter, or native platform channels exist in the Android module. The Flutter `CastManager` is a pure Dart simulation using `Future.delayed` and local in-memory timers. Real Chromecast discovery and hardware connection cannot occur.
2. **Web Sender (`[NOT IMPLEMENTED / MOCK ONLY]`):**
   `web/index.html` does not load the official Google Cast Web Sender SDK (`cast_sender.js?loadCastFramework=1`). Web casting is purely simulated in Dart state.
3. **Web Receiver CAF v3 (`[PASS (Code Architecture) / FAIL (Deployment)]`):**
   A genuine Google Cast Application Framework (CAF) v3 Custom Web Receiver is implemented inside the `filmytell-cast-receiver/` directory, featuring `<cast-media-player>`, `CastReceiverContext`, message interceptors, and dynamic watermarking. However, this directory resides outside the web build path and is **not deployed**.
4. **`/cast/index.html` Live Routing (`[FAIL]`):**
   Visiting `https://filmytell.com/cast/index.html` returns the regular FilmyTell Flutter Web Single Page Application (SPA) instead of the CAF v3 Web Receiver because the server falls back to the main `/index.html`.
5. **Production Readiness:** **`NOT READY FOR DEVICE TESTING`** (Requires native Android SDK integration, Web Sender SDK integration, and static deployment of the CAF v3 receiver).

---

## 2. Git / Branch State
* **Current Branch:** `feature/chromecast-support` `[PASS]`
* **Current Commit:** `04da1d7ad9e57206b840d0d8dcd728cf3e9d8943` `[PASS]`
* **Origin / `final_ott` Commit:** `04da1d7ad9e57206b840d0d8dcd728cf3e9d8943` `[PASS]`
* **Branch Comparison:** `feature/chromecast-support` and `final_ott` point to the exact same commit. `final_ott` has **not** been modified. `[PASS]`
* **Working Tree State:** Working tree contains Cast-related modifications and untracked files.

### Added / Modified Files for Chromecast:
* **Modified Files:**
  - `pubspec.yaml`
  - `.flutter-plugins-dependencies`
  - `ios/Runner/Info.plist` (Added `NSLocalNetworkUsageDescription` & `_googlecast._tcp` Bonjour services)
  - `lib/app/core/constant/app_constant.dart`
  - `lib/app/pages/wallet page/WalletPage.dart`
  - `lib/app/pages/watchlist page/component/playMoviePage.dart` (Cast button hook & remote playback overlay)
  - `test/widget_test.dart`
  - `web/index.html` (Fast shell loader & Razorpay lazy load)
* **Untracked / Added Files:**
  - `filmytell-cast-receiver/` (`index.html`, `receiver.js`, `player.js`, `styles.css`, `package.json`, `README.md`)
  - `lib/app/core/cast/` (`cast_button.dart`, `cast_constants.dart`, `cast_device_dialog.dart`, `cast_manager.dart`, `cast_models.dart`)
  - `test/cast_manager_test.dart`
  - `Filmytell-JioSTB-v1.0.18-release.apk`

---

## 3. Cast Files Inventory

| Keyword / Identifier | Occurrences / File Locations | Analysis |
| :--- | :--- | :--- |
| `0C452C93` | **0 occurrences in codebase** | Registered Production Application ID is **not** yet present in codebase. `[WARNING]` |
| `CC1AD845` | `lib/app/core/cast/cast_constants.dart` (L8, L12), `ios/Runner/Info.plist` (L80) | Google Default Media Receiver ID used as dev fallback. |
| `B6CCC3E2` | **0 occurrences in codebase** | Sample Cast ID not found. |
| `urn:x-cast:com.filmytell.ott.cast` | `cast_constants.dart` (L20), `filmytell-cast-receiver/receiver.js` (L9), `README.md` | Custom namespace declared identically on sender and receiver. `[PASS]` |
| `CastManager` | `lib/app/core/cast/cast_manager.dart` | Mock/simulation state controller. `[NOT IMPLEMENTED]` |
| `CastButton` | `lib/app/core/cast/cast_button.dart` | Flutter UI action button. `[PASS]` |
| `CastDeviceDialog` | `lib/app/core/cast/cast_device_dialog.dart` | Modal bottom sheet device picker. `[PASS]` |
| `cast_receiver_framework.js` | `filmytell-cast-receiver/index.html` (L9) | Official Google Cast CAF v3 script reference. `[PASS]` |
| `cast-media-player` | `filmytell-cast-receiver/index.html` (L13) | CAF v3 standard media player element. `[PASS]` |
| `CastReceiverContext` | `filmytell-cast-receiver/receiver.js` (L5) | CAF v3 receiver context initialization. `[PASS]` |
| `cast_sender.js` | **0 occurrences in `web/`** | Missing from Web Sender. `[NOT IMPLEMENTED]` |
| `com.google.android.gms.cast` | **0 occurrences in `android/`** | Missing from Android build/manifest. `[NOT IMPLEMENTED]` |

---

## 4. Android Sender
* **Implementation Type:** Mock / In-Memory Simulation in Dart (`lib/app/core/cast/cast_manager.dart`).
* **Technical Evidence:**
  - `CastManager.startDiscovery()` sets `_isDiscovering = true` and runs a local Dart timeout timer. No network scan is performed.
  - `CastManager.connect(device)` delays `600ms` via `Future.delayed` and flips `isConnected = true`.
  - `CastManager.loadMedia(metadata)` delays `800ms` and starts `_startPositionTicker()` to increment playback seconds locally.
* **Status:** `[NOT IMPLEMENTED]`

---

## 5. Android Cast SDK
* **Official Google Cast Android Sender SDK:** `OFFICIAL GOOGLE CAST ANDROID SENDER SDK NOT FOUND`
* **Inspected Files:**
  - `android/app/build.gradle.kts`: No `com.google.android.gms:play-services-cast-framework` or `androidx.mediarouter:mediarouter`.
  - `android/app/src/main/AndroidManifest.xml`: No `OptionsProvider` metadata declaration.
  - `android/app/src/main/kotlin/com/filmytell/ott/MainActivity.kt`: No Cast platform channels (only `antiPiracyChannel`).
  - `pubspec.yaml`: No Flutter Cast plugin wrapping native SDKs.
* **Status:** `[NOT IMPLEMENTED]`

---

## 6. Android Application ID
* **Declared Configuration:**
  ```dart
  class CastConfig {
    static const String appId = String.fromEnvironment(
      'CAST_APP_ID',
      defaultValue: 'CC1AD845',
    );
  }
  ```
* **Runtime Trace:**
  1. If `--dart-define=CAST_APP_ID=0C452C93` is provided during compilation, `CastConfig.appId` resolves to `0C452C93`.
  2. If omitted, it falls back to `CC1AD845`.
  3. **Break in Flow:** Because no native Android Cast SDK / Platform Channel exists, `CastConfig.appId` stops at `CastManager` in Dart and is **never passed to a native `CastOptions` or `receiverApplicationId`**.
* **Status:** `[WARNING (Configuration Present, Native Bridge Missing)]`

---

## 7. Android Device Discovery
* **Discovery Mechanism:** In `CastManager.dart`, discovery is simulated via a `Timer`.
* **Network Socket / mDNS / SSDP:** No native network discovery sockets are open.
* **Result:** No real Chromecast or Google TV devices can be discovered by the mobile app on the local Wi-Fi network.
* **Status:** `[NOT IMPLEMENTED]`

---

## 8. Android Cast Session
* **Session Lifecycle Verification:**
  - Discovery: `[NOT IMPLEMENTED]`
  - Device Selection Dialog: `[PASS (UI)] / [FAIL (Hardware Devices)]`
  - Session Connection: `[NOT IMPLEMENTED (Mock only)]`
  - Custom Receiver Launch: `[NOT IMPLEMENTED]`
  - Remote Media Command Transmission: `[NOT IMPLEMENTED]`
  - Playback Controls (`play`, `pause`, `seek`, `stop`, `volume`): `[NOT IMPLEMENTED (Updates local Dart variables only)]`
* **Status:** `[NOT IMPLEMENTED]`

---

## 9. Android Media Loading
* **Payload Structure (`CastMediaMetadata.toJson()`):**
  ```json
  {
    "contentId": 42,
    "title": "Movie Title",
    "subtitle": "Episode 1 / Description",
    "posterUrl": "https://...",
    "mediaUrl": "https://cdn.filmytell.com/hls/master.m3u8?...",
    "contentType": "application/x-mpegurl",
    "initialPositionSeconds": 120,
    "durationSeconds": 7200,
    "isSeries": false,
    "seasonId": 1,
    "episodeId": 1,
    "authToken": "<JWT>",
    "watermarkText": "USER#123"
  }
  ```
* **Status:** `[PASS (Data Model Prepared)] / [NOT IMPLEMENTED (Network Transport)]`

---

## 10. Local → Cast Handoff
* **Inspected File:** `lib/app/pages/watchlist page/component/playMoviePage.dart`
* **Execution Flow:**
  1. User initiates cast: `_startCastingToConnectedDevice()` captures current position `_currentPlaybackPosition`.
  2. Local player is paused: `unawaited(_pauseActivePlayer())`.
  3. `CastMediaMetadata` is built and passed to `castManager.loadMedia(metadata)`.
  4. UI renders `_buildCastRemoteOverlay` with full-screen playback controls and scrubber.
  5. User taps "Play on Phone": `castManager.disconnect()` is called, local player seeks to `castManager.position` and resumes via `_resumeAndPlay()`.
* **Status:** `[PASS (UI & State Flow Correct)]`

---

## 11. Android Disconnect / Reconnect
* **Manual Disconnect:** User tapping "Disconnect" or "Play on Phone" resets local state and resumes phone playback. `[PASS]`
* **Automatic Recovery (Wi-Fi drop, TV power off, background/foreground):** Not implemented. `[NOT IMPLEMENTED]`
* **Status:** `[NOT IMPLEMENTED]`

---

## 12. Web Sender
* **Web Sender SDK Script:** Missing from `web/index.html`.
* **Chrome Cast Extension Integration (`chrome.cast`):** Missing.
* **Status:** `[NOT IMPLEMENTED]`

---

## 13. Web Cast SDK
* **`cast.framework.CastContext` in Web:** Not loaded or initialized in web scripts.
* **Status:** `[NOT IMPLEMENTED]`

---

## 14. Web Application ID
* **`receiverApplicationId` in Web:** Not configured in JavaScript.
* **Status:** `[FAIL] WEB SENDER APPLICATION ID NOT CONFIGURED`

---

## 15. Web Cast Session
* **Session Lifecycle in Web:** No `SESSION_STARTED`, `SESSION_RESUMED`, or `SESSION_ENDED` listeners.
* **Status:** `[NOT IMPLEMENTED]`

---

## 16. Web Cast Button
* **UI Implementation:** `CastButton` in `lib/app/core/cast/cast_button.dart` renders a Flutter `IconButton` with `Icons.cast` / `Icons.cast_connected`.
* **Platform Visibility:**
  - Visible on Mobile and Web (`kIsWeb || !ResponsiveWidget.isTv(context)`).
  - Automatically hidden on Android TV and Fire TV (`ResponsiveWidget.isTv(context)`). `[PASS]`
* **Connection to Native Web Cast:** Not connected to `google-cast-launcher`.
* **Status:** `[PASS (UI)] / [NOT IMPLEMENTED (Web Cast API)]`

---

## 17. `/cast/index.html` (Live URL Audit)
* **Target URL:** `https://filmytell.com/cast/index.html`
* **Current Live Response:** Renders the standard FilmyTell Flutter Web application.
* **Root Cause:**
  1. The receiver code is located in `filmytell-cast-receiver/` in the repository root.
  2. Flutter Web builds only package files from `web/` into `build/web/`.
  3. The web server / CDN uses SPA fallback rewrites (`try_files $uri $uri/ /index.html`), causing `/cast/index.html` to return the main Flutter SPA.
* **Status:** `[FAIL]`

---

## 18. CAF V3 Receiver Verification
* **Local Source Path:** `filmytell-cast-receiver/index.html`, `receiver.js`, `player.js`, `styles.css`
* **Framework Elements Verified:**
  - `cast.framework.CastReceiverContext.getInstance()`: `[PASS]`
  - `<cast-media-player id="player">`: `[PASS]`
  - `playerManager.setMessageInterceptor(MessageType.LOAD)`: `[PASS]`
  - `playerManager.addEventListener(EventType.PLAYER_STATE_CHANGED)`: `[PASS]`
  - `playerManager.addEventListener(EventType.ERROR)`: `[PASS]`
  - `context.addCustomMessageListener('urn:x-cast:com.filmytell.ott.cast')`: `[PASS]`
  - Dynamic rotating watermark and brand loading overlay: `[PASS]`
* **Status:** `[PASS (Code Architecture Valid CAF v3)]`

---

## 19. Receiver Initialization Flow
* **Conceptual & Code Trace in `receiver.js`:**
  ```text
  CastReceiverContext.getInstance()
      ↓
  CastReceiverOptions (inactivity: 3600s)
      ↓
  setMessageInterceptor(MessageType.LOAD)
      ↓
  Custom Watermark & PlaybackConfig Setup
      ↓
  context.start(options)
  ```
* **Status:** `[PASS]`

---

## 20. Receiver Deployment
* **Deployment Destination:** Not deployed to `https://filmytell.com/cast/index.html`.
* **Status:** `[FAIL]`

---

## 21. Receiver Routing
* **Server Routing Analysis:** Static file routing for `/cast/*` is missing in hosting configuration.
* **Status:** `[FAIL]`

---

## 22. HLS Playback
* **Media Stream Format:** HLS (`.m3u8`) master playlists and variant streams.
* **MIME Types Handled:** `application/x-mpegurl`, `video/mp4`.
* **Status:** `[PASS]`

---

## 23. Signed Playback
* **Endpoint:** `POST ${baseUrl}/anti-piracy/playback/signed-url`
* **CloudFront CDN Compatibility Issue:**
  In `receiver.js`:
  ```javascript
  playbackConfig.manifestRequestHandler = (requestInfo) => {
    if (authToken) {
      requestInfo.headers['Authorization'] = `Bearer ${authToken}`;
    }
  };
  ```
  > [!WARNING]
  > AWS CloudFront HLS signed URLs authenticate via query parameters (`Policy`, `Signature`, `Key-Pair-Id`). Injecting `Authorization: Bearer <JWT>` into HLS manifest/segment fetches can trigger CORS preflight failures or HTTP 403 Forbidden errors if CloudFront origin policies do not allow the `Authorization` header.
* **Status:** `[WARNING (Remove Bearer from CDN requests in receiver)]`

---

## 24. DRM
* **FilmyTell DRM Implementation:** No Widevine, FairPlay, or PlayReady license server is configured in the application. Content security relies on CloudFront Signed URLs, JWT anti-piracy middleware, dynamic watermarking, and token-based entitlements.
* **Status:** `[PASS (Clear HLS with Signed URLs — No DRM required for Cast)]`

---

## 25. Continue Watching
* **API Endpoint:** `POST ${baseUrl}/continue-watching/save`
* **Cast Behavior:**
  - Local playback captures position before handoff.
  - Remote playback position is tracked in sender UI during cast.
  - Tapping "Play on Phone" resumes local playback at remote position.
  - Continue-watching API is not periodically synced directly from the Cast receiver.
* **Status:** `[PASS (Handoff Flow)] / [WARNING (No background periodic sync during Cast)]`

---

## 26. Analytics
* **API Endpoint:** `${baseUrl}/anti-piracy/playback/analytics`
* **Cast Analytics:** Local playback triggers events (`PLAY`, `PAUSE`, `HEARTBEAT`). Cast-specific analytics events are not yet emitted to the backend.
* **Status:** `[NEEDS BACKEND VERIFICATION]`

---

## 27. Custom Namespace
* **Namespace:** `urn:x-cast:com.filmytell.ott.cast`
* **Sender:** Defined in `CastConstants.castNamespace`.
* **Receiver:** Implemented in `receiver.js` via `context.addCustomMessageListener()`.
* **Handled Actions:** `UPDATE_WATERMARK`, `REFRESH_AUTH_TOKEN`.
* **Status:** `[PASS (Schema & Logic Match)]`

---

## 28. Security
* **Secret Leakage:** No AWS secrets, CloudFront private keys, database passwords, or signing credentials exist in the client repository. `[PASS]`
* **JWT Exposure:** User JWT `authToken` is passed in `CastMediaMetadata` / `customData`. Should be removed since CloudFront Signed URLs do not require it. `[WARNING]`
* **Signed URL Expiration:** Signed URLs have a finite lifespan; very long films (3+ hours) may require a token/URL refresh if the URL expires mid-playback. `[WARNING]`
* **Watermark Overlay:** Rotating watermark is rendered on the receiver overlay every 45 seconds. `[PASS]`
* **Status:** `[PASS WITH WARNING]`

---

## 29. Dependencies

| Package / Library | Version | Location | Purpose | Official Google Cast SDK? | Actually Used? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `caf_receiver_framework.js` | v3 | `filmytell-cast-receiver/index.html` | Web Receiver CAF v3 SDK | **Yes** | **Yes (in receiver)** |
| `play-services-cast-framework` | None | `android/app/build.gradle.kts` | Android Sender SDK | **No** (Missing) | **No** |
| `cast_sender.js` | None | `web/index.html` | Web Sender SDK | **No** (Missing) | **No** |

---

## 30. TV / Fire TV / Jio STB Impact
* **Android TV, Google TV native app, Fire TV, Jio STB:**
  - `CastButton` explicitly checks `!kIsWeb && ResponsiveWidget.isTv(context)` and renders `const SizedBox.shrink()`.
  - Android TV Leanback manifest intents, DPAD focus, and TV player instances (`media_kit` / `video_player`) remain 100% untouched.
* **Status:** `[PASS]`

---

## 31. Automated Testing
* **Existing Tests:**
  - `test/widget_test.dart`: Verifies `CastButton` renders `Icons.cast`.
  - `test/cast_manager_test.dart`: Verifies in-memory `CastManager` state transitions and `CastMediaMetadata.toJson()` serialization.
* **Note:** Passing unit/widget tests validate Dart data models and UI rendering, but **do not prove hardware Cast functionality**.
* **Status:** `[PASS (Unit/Widget Tests)]`

---

## 32. Real Device Testing Readiness
* **Android Mobile → Google TV:** `[NOT READY]` (No native Android Cast SDK integration).
* **Web Browser → Google TV:** `[NOT READY]` (No Web Sender SDK and receiver is not deployed).
* **Status:** `[NOT READY]`

---

## 33. Problems Found
1. **Missing Android Native Cast SDK:** The Android application cannot scan, discover, or connect to Chromecast devices over local Wi-Fi.
2. **Undeployed Web Receiver:** The receiver code in `filmytell-cast-receiver/` is not part of `web/` or the production build.
3. **Web SPA Fallback:** Requests to `https://filmytell.com/cast/index.html` load the Flutter Web app.
4. **CloudFront Header Incompatibility in Receiver:** `receiver.js` attempts to send `Authorization: Bearer` on CDN segment requests.
5. **Missing Web Sender SDK:** `web/index.html` lacks `cast_sender.js`.

---

## 34. Missing Components
1. `com.google.android.gms:play-services-cast-framework` dependency in Android Gradle or a verified Flutter Cast wrapper plugin.
2. `CastOptionsProvider` implementation in Android native code and `AndroidManifest.xml`.
3. Copy of `filmytell-cast-receiver/` files into `web/cast/` for inclusion in `build/web/`.
4. Web server routing rule to serve `/cast/index.html` as static content.
5. Google Cast Web Sender SDK script tag in `web/index.html`.

---

## 35. Recommended Changes (For Next Implementation Phase)
1. **Deploy Web Receiver:**
   - Copy `filmytell-cast-receiver/*` into `web/cast/`.
   - Verify that `https://filmytell.com/cast/index.html` loads the black receiver screen with the FilmyTell loader and `<cast-media-player>`.
2. **Sanitize Receiver Request Headers:**
   - In `receiver.js`, remove `requestInfo.headers['Authorization'] = ...` from `manifestRequestHandler` and `segmentRequestHandler`.
3. **Integrate Android Cast Sender:**
   - Add native Cast SDK or a production-tested Flutter Cast plugin with `CastOptionsProvider` configured to use Application ID `0C452C93`.
4. **Integrate Web Cast Sender:**
   - Add `cast_sender.js` to `web/index.html` and bridge with Flutter Web.
5. **Update Default Application ID:**
   - Set default `CAST_APP_ID` to `0C452C93` in `cast_constants.dart`.

---

## 36. Production Readiness
* **Overall Status:** `NOT READY FOR PRODUCTION`

---

## 39. FINAL CONCLUSION

* **ANDROID SENDER:** `NOT IMPLEMENTED` (Dart simulation only; missing Google Cast Android Sender SDK)
* **WEB SENDER:** `NOT IMPLEMENTED` (Missing Google Cast Web Sender SDK in `web/index.html`)
* **WEB RECEIVER:** `PASS (Code) / FAIL (Deployment)` (Valid CAF v3 code exists locally, but not deployed)
* **CAF V3:** `IMPLEMENTED IN CODE` (Genuine CAF v3 architecture in `filmytell-cast-receiver/`)
* **`/cast/index.html`:** `FAIL` (Currently serves Flutter Web SPA due to SPA fallback)
* **CAST APPLICATION ID:** `WARNING` (`0C452C93` registered in Google Console, but not yet wired to native sender)
* **SIGNED PLAYBACK:** `PASS (URLs generated) / WARNING (Remove Bearer headers from receiver CDN requests)`
* **HLS:** `PASS` (HLS master playlists and standard MIME types supported)
* **CUSTOM NAMESPACE:** `PASS (Schema matched) / NOT IMPLEMENTED (Native transport missing)`
* **SECURITY:** `PASS WITH WARNING` (No hardcoded secrets; remove JWT from `customData`)
* **TV / FIRE TV / JIO STB:** `PASS` (100% safe; TV platforms suppress Cast button and maintain existing player)
* **REAL DEVICE TEST:** `NOT READY`
* **PRODUCTION READINESS:** `NOT READY FOR PRODUCTION`

---

## 40. FINAL DECISION

# **NOT READY FOR DEVICE TESTING**

### Blockers:
1. **Android Sender:** Native Google Cast SDK (`play-services-cast-framework`) is missing from the Android project.
2. **Web Receiver:** `https://filmytell.com/cast/index.html` serves the Flutter Web SPA because `filmytell-cast-receiver/` is not deployed to the web hosting server.
3. **Web Sender:** Web Sender SDK is missing from `web/index.html`.
4. **CDN Request Interceptors:** `Authorization: Bearer` must be removed from `receiver.js` to avoid breaking CloudFront HLS playback.
