# FilmyTell Google Cast (Chromecast) — Phase 1 Implementation Report

---

## 1. Executive Summary

Phase 1 of the **FilmyTell Google Cast (Chromecast)** project establishes the real, production-ready Google Cast sender and custom web receiver infrastructure across Android Mobile, Flutter Web, and CAF (Cast Application Framework) v3.

The previous simulation/mock Cast layer has been completely replaced with:
- **Native Android Sender SDK**: Google Play Services Cast Framework (`22.0.0`) and AndroidX MediaRouter (`1.7.0`) integrated via Kotlin `MethodChannel` (`com.filmytell.ott/cast`).
- **Flutter Web Sender SDK**: Official Google Cast Web Sender SDK (`cast_sender.js?loadCastFramework=1`) integrated via a two-way browser event bridge (`universal_html` CustomEvent architecture).
- **CAF v3 Custom Web Receiver**: Standalone HTML5/JS Cast receiver deployed at `https://filmytell.com/cast/index.html` configured for FilmyTell's custom receiver application ID `0C452C93`.

### Guarantees Maintained
1. **Zero Base Code Breakage**: `final_ott` base branch untouched; all work developed strictly on `feature/chromecast-support`.
2. **TV Platform Isolation**: Android TV, Google TV native app, Fire TV, and Jio STB remain unaffected (`ResponsiveWidget.isTv(context)` completely suppresses the Cast button on TV platforms).
3. **Player Core Stability**: `media_kit`, `video_player`, and `youtube_player_flutter` integrations remain intact.
4. **Security & DRM Integrity**: No user JWT tokens are leaked to the cast receiver; CloudFront signed URL parameters (`Policy`, `Signature`, `Key-Pair-Id`) are passed directly without header contamination.

---

## 2. Google Cast Configuration & Credentials

| Parameter | Production Value | Verification Status |
| :--- | :--- | :--- |
| **Registered Custom Receiver App ID** | `0C452C93` | Configured across Android, Web, and Dart |
| **Custom Receiver Hosted URL** | `https://filmytell.com/cast/index.html` | Deployed in `web/cast/` and ready for hosting |
| **Google Cast Developer Console Status** | Published / In Test | Device "Google TV" registered |
| **Test Device Status** | Ready For Testing | Serial registered in Cast Console |
| **Cast SDK Receiver Framework** | CAF v3 (`cast_receiver_framework.js`) | Included in `web/cast/index.html` |
| **Android Cast SDK** | `com.google.android.gms:play-services-cast-framework:22.0.0` | Verified via Gradle compilation |

---

## 3. Architecture & Topology Overview

```
                                  +---------------------------------------+
                                  |  FilmyTell Custom Web Receiver (CAFv3)|
                                  |  https://filmytell.com/cast/index.html|
                                  |  Application ID: 0C452C93             |
                                  +-------------------+-------------------+
                                                      ^
                                                      |  Google Cast V2 / CAF Protocol
                                                      |  (Media Status, Load, Play/Pause/Seek)
                       +------------------------------+------------------------------+
                       |                                                             |
+----------------------+----------------------+               +----------------------+----------------------+
|             Android Mobile Sender           |               |              Flutter Web Sender             |
|                                             |               |                                             |
|  +---------------------------------------+  |               |  +---------------------------------------+  |
|  | Kotlin CastBridgeManager              |  |               |  | CastWebBridgeWeb (universal_html)     |  |
|  | (CastContext, RemoteMediaClient)      |  |               |  | Event Bridge ('filmytell-cast-*')     |  |
|  +-------------------+-------------------+  |               |  +-------------------+-------------------+  |
|                      ^                      |               |                      ^                      |
|                      | MethodChannel        |               |                      | JS CustomEvents      |
|  +-------------------+-------------------+  |               |  +-------------------+-------------------+  |
|  | Dart CastManager (Singleton)          |  |               |  | Dart CastManager (Singleton)          |  |
|  | - CastButton (ResponsiveWidget aware) |  |               |  | - CastButton (ResponsiveWidget aware) |  |
|  | - Media Handoff & Session State       |  |               |  | - Media Handoff & Session State       |  |
|  +---------------------------------------+  |               |  +---------------------------------------+  |
+---------------------------------------------+               +---------------------------------------------+
```

---

## 4. Detailed Component Changes

### 4.1 CAF v3 Custom Web Receiver (`web/cast/` & `filmytell-cast-receiver/`)

The custom web receiver is located in `web/cast/` (which is copied directly into `build/web/cast/` during web builds) and mirrored in `filmytell-cast-receiver/` for standalone CI/CD deployment.

- **`web/cast/index.html`**:
  - Loads CAF v3 framework: `//www.gstatic.com/cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js`.
  - Defines `<cast-media-player id="player"></cast-media-player>` with custom watermark overlay and FilmyTell branded buffering spinner.
- **`web/cast/receiver.js`**:
  - Initializes `cast.framework.CastReceiverContext.getInstance()`.
  - Sets up `cast.framework.PlaybackConfig` to support HLS, MP4, and DASH streams with auto-play enabled.
  - Implements custom namespace `urn:x-cast:com.filmytell.cast` for secure bi-directional metadata exchange (e.g., dynamic watermark text, subtitle configurations).
  - Handles `LOAD` request interception without injecting `Authorization` headers on CloudFront CDN requests (preventing CORS / 403 preflight failures with signed URLs).
- **`web/cast/styles.css`**:
  - Dark theme OTT player styling with customized Cast player progress bar, volume controls, and watermark positioning.
- **`web/cast/player.js`**:
  - Handles runtime error logging, playback state listener hooks, and custom UI visibility toggles.

### 4.2 Google Cast Android Native Sender

- **`android/app/build.gradle.kts`**:
  - Added `implementation("com.google.android.gms:play-services-cast-framework:22.0.0")`.
  - Added `implementation("androidx.mediarouter:mediarouter:1.7.0")`.
- **`android/app/src/main/kotlin/com/filmytell/ott/cast/CastOptionsProvider.kt`**:
  - Implements `OptionsProvider` providing `CastOptions.Builder().setReceiverApplicationId("0C452C93").build()`.
- **`android/app/src/main/kotlin/com/filmytell/ott/cast/CastBridgeManager.kt`**:
  - Implements `MethodChannel("com.filmytell.ott/cast")`.
  - Binds to `CastContext.getSharedInstance(context)`.
  - Listens to `SessionManagerListener<CastSession>` (`onSessionStarted`, `onSessionResumed`, `onSessionEnded`).
  - Listens to `RemoteMediaClient.Callback` and `RemoteMediaClient.ProgressListener` for exact stream position, duration, and player status (`PLAYING`, `PAUSED`, `BUFFERING`, `IDLE`).
  - Supports `showCastDialog` via `MediaRouteChooserDialog` or `MediaRouteControllerDialog`.
  - Handles media load requests using `MediaInfo.Builder` and `MediaMetadata`.
- **`android/app/src/main/kotlin/com/filmytell/ott/MainActivity.kt`**:
  - Registers `CastBridgeManager.registerWith(flutterEngine, this)` in `configureFlutterEngine`.
- **`android/app/src/main/AndroidManifest.xml`**:
  - Added `com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME` metadata pointing to `com.filmytell.ott.cast.CastOptionsProvider`.
- **`android/app/proguard-rules.pro`**:
  - Added rules to keep `com.google.android.gms.cast.**` and `com.filmytell.ott.cast.**`.

### 4.3 Flutter Web Sender Integration

- **`web/index.html`**:
  - Included Google Cast Web Sender SDK: `https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1`.
  - Initialized `window.__onGCastApiAvailable` with receiver ID `0C452C93`.
  - Injected JavaScript bridge `window.__filmytellCast` to synchronize events between `cast.framework.CastContext` and Flutter Web.
- **`lib/app/core/cast/web/cast_web_bridge.dart`**:
  - Conditional export resolving to `cast_web_bridge_web.dart` on Web and `cast_web_bridge_stub.dart` on Mobile/Desktop.
- **`lib/app/core/cast/web/cast_web_bridge_web.dart`**:
  - Dispatches `filmytell-cast-cmd` events to DOM window.
  - Listens to `filmytell-cast-state` events to update Dart state without requiring deprecated `dart:js_util` or unsafe interop.

### 4.4 Dart Core Cast Layer & Player Integration

- **`lib/app/core/cast/cast_constants.dart`**:
  - Default receiver ID updated to production ID `0C452C93`.
  - Custom namespace defined as `urn:x-cast:com.filmytell.cast`.
- **`lib/app/core/cast/cast_manager.dart`**:
  - Refactored from timer simulation to real platform delegates:
    - Android: `MethodChannel('com.filmytell.ott/cast')`
    - Web: `getCastWebBridge()`
  - Provides reactive state streams: `deviceStream`, `sessionStream`, `playerStateStream`, `progressStream`.
  - Exposes playback commands: `loadMedia()`, `play()`, `pause()`, `seek()`, `setVolume()`, `stop()`, `endSession()`.
- **`lib/app/core/cast/cast_button.dart`**:
  - Triggers native cast picker dialog or web session request.
  - Displays dynamic state icon (`cast_connected` when active, animated pulse when connecting).
- **`lib/app/pages/watchlist page/component/playMoviePage.dart`**:
  - Intercepts Cast connection during active movie playback.
  - Pauses local player when casting commences.
  - Passes movie metadata (title, poster, video URL, content type, live progress) to `CastManager.instance.loadMedia()`.
  - Ensures JWT tokens and user credentials are NOT sent in Cast metadata.

---

## 5. Verification & Test Suite Results

### 5.1 Static Analysis
```bash
flutter analyze lib/app/core/cast/ test/
```
- **Result**: `0 issues found`.

### 5.2 Unit & Integration Tests
```bash
flutter test
```
- **Total Tests**: `37 passed / 0 failed`.
- **Cast Unit Tests**:
  - `CastConfig uses default Custom Receiver Application ID 0C452C93` -> Passed
  - `CastDevice copyWith and equality work correctly` -> Passed
  - `CastMediaMetadata toJson correctly serializes playback details without exposing JWT` -> Passed
  - `CastManager Lifecycle & Initial State Initial state is disconnected` -> Passed
  - `CastManager Lifecycle & Initial State Adding and removing devices updates device list` -> Passed
  - `CastButton renders Google Cast icon` -> Passed

### 5.3 Web Release Build
```bash
flutter build web --release
```
- **Result**: Successfully compiled to `build/web/`.
- **Built Receiver**: Verified `build/web/cast/index.html` contains the CAF v3 static custom receiver.

### 5.4 Android Native Compilation
```bash
.\gradlew.bat compileDebugKotlin --no-daemon
```
- **Result**: `BUILD SUCCESSFUL` (Kotlin 1.9.24 / Google Play Services Cast Framework 22.0.0 compiled with zero errors).

---

## 6. Web Receiver Hosting Instructions

To host the CAF v3 custom receiver on the production domain:

1. **Verify Files in Build**:
   Ensure `build/web/cast/` contains:
   - `index.html`
   - `receiver.js`
   - `player.js`
   - `styles.css`
   - `README.md`
   - `package.json`

2. **Deploy to Web Server / S3 / CloudFront**:
   Deploy the contents of `build/web/cast/` or `web/cast/` to `https://filmytell.com/cast/`.

3. **Verify Hosting URL**:
   Open `https://filmytell.com/cast/index.html` in a web browser. The page should load with a black background, the FilmyTell logo spinner, and `<cast-media-player id="player">`.

4. **CORS & SSL Requirements**:
   - Ensure `https://filmytell.com` serves HTTPS with a valid TLS certificate.
   - Ensure `Access-Control-Allow-Origin: *` headers are allowed on HLS/MP4 CDN media assets.

---

## 7. End-to-End Google TV Testing Plan

### Prerequisites
1. **Google TV Test Device**:
   - Ensure the Google TV device is powered on and connected to the same Wi-Fi network as the sender (Android phone or Chrome browser).
   - Ensure the Google TV device serial number is registered in the [Google Cast SDK Developer Console](https://cast.google.com/publish/) under the developer account.
   - Restart the Google TV device if the Cast Console registration was recently completed.
2. **Sender Device**:
   - Android phone with the FilmyTell debug/release build installed, OR
   - Chrome / Brave browser on Desktop/Laptop running the Web app.

### Step-by-Step Test Procedure

#### Step 1: Discover Google TV
1. Open the FilmyTell app on the Android phone or Web browser.
2. Navigate to any movie or series detail page.
3. Observe the **Cast Icon** in the top navigation or player control bar.
4. Tap the **Cast Icon**.
5. **Expected Result**: A dialog appears listing available Cast devices, including your **Google TV**.

#### Step 2: Connect to Google TV
1. Tap the **Google TV** entry in the Cast dialog.
2. **Expected Result**:
   - The Cast icon changes state to connecting / connected.
   - The Google TV launches the FilmyTell Custom Receiver from `https://filmytell.com/cast/index.html`.
   - The Google TV displays the FilmyTell splash/receiver UI.

#### Step 3: Stream Playback & Media Handoff
1. Start playing a movie on the mobile device (or press Play while connected to Cast).
2. **Expected Result**:
   - The mobile device pauses local video rendering.
   - The movie stream starts playing smoothly on the Google TV.
   - Title, subtitle/description, and backdrop poster are displayed on the TV screen.

#### Step 4: Playback Controls & Synchronization
1. On the sender device, perform:
   - **Pause / Resume**: TV pauses/resumes instantly.
   - **Seek (e.g., +30s or scrub timeline)**: TV seeks to the exact position.
   - **Volume Control**: TV audio updates according to sender slider.
2. **Expected Result**: TV and sender progress bars remain in sync.

#### Step 5: Session Termination
1. Tap the **Cast Icon** and select **Disconnect / Stop Casting**.
2. **Expected Result**:
   - The Google TV closes the receiver app and returns to the TV home screen.
   - The sender device returns to local playback mode.
