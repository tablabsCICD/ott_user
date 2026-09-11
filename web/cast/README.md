# FilmyTell Google Cast Custom Web Receiver

This folder contains the deployed **FilmyTell Custom Web Receiver** for Google Chromecast and Google TV devices.

## Architecture
- **Framework:** Google Cast Application Framework (CAF) Web Receiver SDK v3 (`cast_receiver_framework.js`).
- **Application ID:** `0C452C93` (registered in Google Cast Developer Console).
- **Receiver URL:** `https://filmytell.com/cast/index.html`.
- **Namespace:** `urn:x-cast:com.filmytell.ott.cast`.
- **Features:**
  - HLS adaptive streaming with `<cast-media-player>`
  - Dynamic anti-burn-in watermark corner rotation every 45 seconds
  - Brand loading indicator and error recovery
