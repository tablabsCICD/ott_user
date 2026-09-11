# FilmyTell Google Cast Custom Web Receiver

This folder contains the **FilmyTell Custom Web Receiver** for Google Chromecast and Google TV devices.

---

## 1. Architecture Overview
- **SDK**: Google Cast Application Framework (CAF) Web Receiver SDK v3 (`cast_receiver_framework.js`).
- **Features**:
  - HLS (`.m3u8`) & MP4 adaptive video streaming.
  - Manifest & Segment request interceptors attaching FilmyTell JWT Bearer authentication headers.
  - Dynamic anti-piracy watermark overlay rotation.
  - Custom brand loading spinner and error recovery.
  - Custom messaging namespace `urn:x-cast:com.filmytell.ott.cast`.

---

## 2. Local Testing & Verification
1. Run local development server:
   ```bash
   npx serve -l 8080
   ```
2. For testing over HTTPS with a real Chromecast device, tunnel or deploy to a public HTTPS URL (e.g. Firebase Hosting, Cloudflare Pages, AWS S3/CloudFront).

---

## 3. Google Cast Developer Console Registration
1. Go to [Google Cast Developer Console](https://cast.google.com/publish/).
2. Click **Add New Application** -> Select **Custom Receiver**.
3. **Application Name**: `FilmyTell`
4. **Receiver Application URL**: `https://<YOUR_DEPLOYED_DOMAIN>/index.html` (Must be HTTPS).
5. **Guest Mode**: Enabled.
6. Save and note the generated **Application ID** (e.g., `XXXXXXXX`).
7. Update `AppConstant.castAppId` or provide `--dart-define=CAST_APP_ID=XXXXXXXX` during build.

---

## 4. Production Deployment
Deploy `index.html`, `receiver.js`, `player.js`, and `styles.css` to the FilmyTell CDN/Web root.
Ensure the following HTTP response headers are set:
```http
Access-Control-Allow-Origin: *
Cache-Control: no-cache, no-store, must-revalidate
```
