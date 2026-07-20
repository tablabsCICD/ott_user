# OTT Secure Playback and Anti-Piracy Guide

## 1. Purpose

This document explains how protected OTT playback is intended to work across the Flutter application, Spring Boot backend, CloudFront, and private media storage.

The main security objective is:

> A user must never receive a permanently usable public media URL. Every protected playback attempt must be authorized by the backend and must use short-lived access issued for the authenticated account and registered device.

The Flutter application does not decide whether a user is allowed to watch content. It collects device information and requests access, but the backend remains the authority.

## 2. Main Components

### Flutter application

The Flutter application:

- Authenticates the user and retains the JWT.
- Creates and securely retains a persistent installation device ID.
- Registers the device with the backend.
- Sends device-integrity information.
- Requests a short-lived signed playback URL.
- Gives only the signed URL to the protected video player.
- Tracks the in-memory playback session.
- Sends playback state events.
- Displays the forensic watermark.
- Refreshes access before the signed URL expires.
- Clears playback secrets when the player is closed or the user logs out.

### Spring Boot backend

The backend:

- Validates the JWT and resolves the user from it.
- Confirms that the user exists and is active.
- Confirms that the subscription is active.
- Confirms that the device is registered, authorized, and not blocked.
- Enforces the maximum registered-device limit.
- Evaluates the reported device-integrity status according to server configuration.
- Enforces the concurrent-stream limit.
- Resolves or validates the requested content.
- Creates a short-lived CloudFront authorization response.
- Creates and retains the streaming-session record.
- Accepts analytics events for that session.
- Generates signed forensic-watermark data.
- Records piracy/security alerts where necessary.

### CloudFront and private media storage

CloudFront delivers the protected HLS content. The origin storage, normally S3, should not be publicly accessible.

The private media files should be accessible only through CloudFront using Origin Access Control. CloudFront validates the signed URL or signed cookies before delivering protected resources.

### Video player

The video player receives the authorized URL only after all backend security checks succeed. It is responsible for loading the HLS manifest, child playlists, and media segments.

The player must never silently fall back to the original unsigned URL when protected access fails.

## 3. End-to-End Playback Sequence

The intended sequence is:

1. The user signs in.
2. The backend returns a JWT after successful authentication.
3. Flutter stores the JWT using the application's existing session mechanism.
4. Flutter resolves the persistent installation device ID.
5. Flutter registers or refreshes the device registration.
6. The user selects protected content.
7. Flutter resolves the content ID and original CloudFront HLS master URL.
8. Flutter checks the device-integrity status.
9. Flutter requests a signed playback URL from the backend.
10. The backend validates the account, subscription, device, integrity policy, and stream limits.
11. The backend creates a playback session and returns a signed URL, session ID, and expiry time.
12. Flutter retains those values only in the active player controller.
13. Flutter gives the signed URL to the video player.
14. Playback starts only after player initialization succeeds.
15. Flutter sends the playback-start event.
16. Flutter obtains and displays the forensic watermark.
17. Flutter sends pause and resume events only for real player-state transitions.
18. Flutter refreshes the signed access shortly before expiry.
19. Flutter sends the stop event when playback ends, changes content, exits, or logs out.
20. Flutter disposes the player, timers, signed URL, session ID, and watermark information.

## 4. Authentication

Every anti-piracy API request requires:

- The existing JWT in the Authorization header.
- JSON content type for requests containing a body.

The Flutter application must not send a user ID as proof of identity. The backend extracts the user identity from the validated JWT.

If the backend returns HTTP 401:

- Playback must not continue.
- The current secure playback attempt must stop.
- The existing session-expired or reauthentication workflow should run.
- The signed URL and session information must be discarded.

JWTs must never appear in application logs, analytics, crash reports, URLs, or screenshots.

## 5. Persistent Device Identity

Each installation receives a randomly generated UUID.

The device ID:

- Is generated once.
- Is stored using secure storage.
- Survives normal application restarts and login/logout.
- Is not regenerated for every playback.
- Is removed only when application data is cleared or the application is reinstalled.
- Is not based on an IMEI, MAC address, advertising ID, or another restricted hardware identifier.

The application also supplies:

- Device type, such as ANDROID or IOS.
- A user-readable device name.
- The operating-system version.

The installation UUID identifies the app installation, not the physical person and not necessarily the permanent physical hardware.

## 6. Device Registration and Authorization

After login, Flutter attempts to register the current device. Registration is also checked immediately before protected playback when its status is unknown.

The backend may:

- Create a new device binding.
- Refresh an existing binding.
- Reject a blocked device.
- Reject an unauthorized device.
- Reject registration when the account has reached its device limit.

Only one registration request should be active at a time. Multiple widgets or rebuilds must not create simultaneous duplicate registration calls.

The registered-device screen lets the user inspect and remove devices. Removing a device should require confirmation.

Removing the current device invalidates its known registration state. It must be registered again before protected playback.

## 7. Device Integrity

The client reports:

- Whether the device appears rooted.
- Whether the iOS device appears jailbroken.
- Whether the application appears to be running in an emulator or simulator.

These values are useful signals but are not cryptographic proof. A modified client can potentially falsify them.

If local integrity detection cannot run, the application should retain an internal unknown state. Product policy must then decide whether to:

- Block playback conservatively.
- Allow the backend to evaluate the request with the available values.
- Require stronger platform attestation.

For stronger protection:

- Android should integrate Play Integrity.
- iOS should integrate App Attest or DeviceCheck.

The backend must remain responsible for enforcing integrity policy. Client-side checks alone must never be treated as authoritative.

## 8. Signed Playback URL

Flutter requests playback access immediately before initializing the protected player.

The request contains:

- Content ID.
- Persistent device ID.
- Original CloudFront HLS master URL, while the current backend contract still requires it.
- Country.
- Device-integrity values.

The backend response contains:

- A short-lived HTTPS signed URL.
- A unique streaming-session ID.
- An expiry timestamp.

Flutter validates that:

- The URL uses HTTPS.
- The URL contains a valid host.
- The session ID is present.
- The expiry timestamp is in the future.

The signed URL:

- Is supplied to the video player.
- Is kept only in memory.
- Is never saved to preferences or a database.
- Is never placed in persistent navigation arguments.
- Is never logged.
- Is discarded when the player session ends.

The original URL must not be used as an automatic fallback for protected content.

## 9. Why HLS Requires More Than Signing the Master Manifest

An HLS stream normally contains multiple resource levels:

- Master playlist.
- Video and audio variant playlists.
- Subtitle playlists.
- Encryption-key files, when applicable.
- Media segments such as TS or fragmented MP4 files.

Signing only the master playlist does not automatically authorize every child request. Query parameters on the master URL are normally not inherited by relative child URLs.

Therefore, one of these CloudFront strategies is required:

### Signed cookies

The backend issues CloudFront signed cookies covering the complete protected path. The player then sends those cookies while requesting the master playlist, child playlists, keys, subtitles, and segments.

### Manifest rewriting

The backend or packaging layer rewrites every protected child URL so that each resource has valid authorization.

### Path-wide authorization

The signing policy authorizes an appropriate content path, and the player receives the required cookies or resource-specific URLs.

If the master playlist loads but child resources return HTTP 403, the player will appear to start loading and then fail. This is a CloudFront/HLS authorization problem, not a play-button problem.

## 10. Streaming Session and Concurrent Playback

The backend creates a streaming-session record when it issues access.

The session associates:

- Authenticated user.
- Content.
- Registered device.
- Country.
- Signed-access lifetime.
- Playback state and analytics.

The backend enforces the configured concurrent-stream limit. If a new stream exceeds the limit, the backend may terminate the oldest session and record a piracy alert.

Flutter must keep the session ID only in the active playback controller. It must use that session ID for analytics until the session is stopped or replaced during signed-URL refresh.

## 11. Player Security State

The player controller uses clear states:

- preparingSecurity
- requestingPlaybackAccess
- initializingPlayer
- ready
- playing
- paused
- refreshingUrl
- accessDenied
- playbackError
- disposed

Only one startup request should run for a playback attempt. Flutter rebuilds must not request multiple signed URLs.

While security validation or player initialization is active, the interface shows a loader.

The protected media player becomes visible only after a signed response has been validated and initialization has succeeded.

## 12. Signed-URL Expiration and Refresh

The expiry time is taken from the backend response. Flutter must not assume that every URL lasts exactly ten minutes.

Flutter schedules refresh approximately 60 seconds before the returned expiry time.

During refresh:

1. Capture the playback position.
2. Capture whether the player is playing or paused.
3. Capture volume, playback speed, audio track, and subtitle track.
4. Request a new signed URL using the original source URL.
5. Initialize or replace the player media source with the new signed URL.
6. Restore playback position and player settings.
7. Resume only if the player was previously playing.
8. Stop the old backend session where appropriate.
9. Replace the active session ID.
10. Schedule the next refresh from the new expiry timestamp.

Only one refresh request may be active.

A player HTTP 403 can indicate expired CloudFront authorization. Flutter may perform one controlled refresh, but it must prevent infinite refresh loops.

If renewal fails:

- Retry once only for transient network or server failures.
- Do not repeatedly retry HTTP 401 or 403.
- Pause before secure access expires.
- Show an actionable retry or access-denied state.
- Never fall back to the unsigned URL.

## 13. Playback Analytics

Flutter sends these supported events:

- PLAYBACK_START
- PLAYBACK_PAUSE
- PLAYBACK_RESUME
- PLAYBACK_STOP

START is sent only after playback actually starts.

PAUSE and RESUME are sent only on real state transitions. Repeated player callbacks must be deduplicated.

STOP is sent when:

- Playback completes.
- The user exits.
- The content changes.
- The user logs out.
- The playback controller is disposed.

STOP must be sent no more than once for a session.

Analytics calls use a short timeout and run without blocking the player interface. Analytics failure must not stop or crash playback.

## 14. Forensic Watermark

The backend returns signed watermark identity data for the current authenticated user and device.

Flutter displays:

- A masked email address or user ID.
- A shortened device ID.
- A timestamp.

Flutter does not display the watermark signature.

The watermark:

- Is drawn above the actual video surface.
- Is visible in landscape and fullscreen.
- Uses SafeArea.
- Does not intercept player gestures.
- Moves periodically so simple cropping is less effective.
- Is refreshed periodically.
- Is removed when playback is disposed.

The signature stays in memory and must not be logged or included in normal analytics.

## 15. Application Lifecycle

### Background

When the app enters the background:

- Capture the current playback state.
- Pause according to player policy.
- Send PAUSE only if playback really changed from playing to paused.
- Keep only the minimum in-memory session state required for safe restoration.

### Foreground

When the app returns:

- Check whether the signed URL is expired or near expiry.
- Refresh access before resuming when necessary.
- Resume only after valid access and successful player restoration.
- Send RESUME only after playback actually resumes.

### Logout

On logout:

- Send STOP best-effort.
- Stop active secure sessions.
- Dispose player and refresh timers.
- Remove signed URLs, session IDs, and watermark responses from memory.
- Clear the JWT through the existing logout workflow.
- Keep the installation device ID.

## 16. Error Handling

Errors shown to the user must be safe and understandable.

| Condition | Expected behavior |
| --- | --- |
| HTTP 401 | Stop playback and invoke session-expired handling |
| HTTP 403 | Show access denied, inactive subscription, unauthorized device, integrity rejection, or device-limit guidance |
| HTTP 404 | Show content or playback session not found |
| HTTP 409 | Show device-limit or registration-conflict guidance when used by the backend |
| HTTP 429 | Show a retry-later state and avoid immediate request loops |
| HTTP 500 or other server failure | Show that secure playback could not be prepared |
| Network timeout | Show retry without exposing internal details |
| Invalid signed response | Reject it before player initialization |
| Player HTTP 403 | Attempt one controlled signed-access refresh |

Raw backend bodies and internal exceptions must not be displayed.

## 17. Data That Must Never Be Logged or Persisted

The following information must not be printed, logged, persisted, or sent to general analytics:

- JWT.
- Signed CloudFront URL.
- CloudFront signature and policy parameters.
- Watermark signature.
- Raw sensitive backend error body.
- Private signing keys.

CloudFront private keys and URL-signing logic belong only in trusted backend or infrastructure services. They must never be bundled in Flutter.

## 18. Infrastructure Requirements

Secure frontend behavior is not sufficient by itself.

Production infrastructure must ensure:

- S3 or the media origin is private.
- CloudFront Origin Access Control is enabled.
- Direct S3 access is denied.
- CloudFront signing credentials are configured on the backend.
- Key-pair identifiers match the configured private key.
- Server clocks are synchronized.
- The entire HLS resource tree is authorized.
- CORS permits the required application origins for Web playback.
- Content types for M3U8, TS, MP4, keys, audio, and subtitles are correct.
- Cache behavior does not accidentally expose protected manifests.
- HTTPS is enforced.

## 19. Current Limitations and Important Decisions

The current backend contract defines mobile device types as ANDROID and IOS. Web support requires an explicit backend decision about browser device identity, registration, integrity policy, cookies, and CORS.

Client-reported root, jailbreak, and emulator flags are not strong attestation.

If protected HLS child resources are private, signing only the master M3U8 URL is insufficient.

DRM is separate from signed delivery. Signed URLs control access duration, but they do not provide Widevine, FairPlay, or PlayReady content encryption and license enforcement.

Signed access reduces casual sharing but cannot fully prevent screen recording, compromised clients, or analog capture. DRM, attestation, watermarking, monitoring, and operational response are complementary controls.

## 20. Troubleshooting Playback

The failure stage helps locate the problem:

### Failure before player initialization

Check:

- JWT availability and validity.
- Device registration response.
- Device-limit status.
- Integrity-policy result.
- Subscription and account state.
- Signed-URL endpoint response.
- Response expiry and server clock.

### Master playlist does not load

Check:

- CloudFront signed URL validity.
- Key-pair configuration.
- Private-key configuration.
- URL expiry.
- CloudFront distribution hostname.
- CORS on Web.

### Master loads but playback fails

Check:

- Child playlist authorization.
- Media-segment authorization.
- Encryption-key authorization.
- Signed cookies or manifest rewriting.
- HLS MIME types.
- Codec/platform compatibility.

### Playback stops near expiry

Check:

- Refresh timer calculation.
- Refresh endpoint response.
- Preservation of the original unsigned source URL.
- Refresh single-flight protection.
- Player source replacement and restored position.
- New session ID binding.

### Watermark is missing

Check:

- X-Device-Id header.
- Watermark endpoint authorization.
- Overlay stacking above the video.
- SafeArea/fullscreen layout.
- Watermark refresh timer.

## 21. Security Responsibility Summary

Flutter is responsible for safely requesting and consuming access.

The backend is responsible for deciding whether access is allowed.

CloudFront is responsible for enforcing short-lived delivery authorization.

Private storage is responsible for preventing origin bypass.

The video player is responsible for using the authorized media source and exposing real playback-state changes.

No single layer provides complete anti-piracy protection. Effective protection comes from all layers working together without an unsigned fallback.
