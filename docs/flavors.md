# Filmytell Flavor Setup

This project keeps one shared Flutter application implementation and separates
only platform/flavor configuration.

## Flutter Entry Points

- `lib/main.dart` - backward-compatible default mobile entry point.
- `lib/main_mobile.dart` - Android mobile entry point.
- `lib/main_tv.dart` - Android TV entry point.
- `lib/main_ios.dart` - iOS entry point.
- `lib/main_web.dart` - web entry point.
- `lib/app/flavor/app_flavor.dart` - runtime flavor helper.
- `lib/app/flavor/app_bootstrap.dart` - shared app initialization.

The entry files only choose a fallback flavor and call shared bootstrap logic.
No navigation, UI, API, Firebase, payment, deep-link, wallet, login, OTP, media,
or business logic is duplicated.

## Android Structure

- `android/app/build.gradle.kts`
  - `mobile` flavor: `applicationId = "com.filmytell.ott"`
  - `mobile` version: inherited from `pubspec.yaml`
  - `mobile` app name resource: `Filmytell`
  - `tv` flavor: `applicationId = "com.filmytell.ott"`
  - `tv` version: inherited from `pubspec.yaml`
  - `tv` app name resource: `Filmytell`
- `android/app/src/main/AndroidManifest.xml`
  - Shared permissions, activities, payment activity, deep links, and app links.
- `android/app/src/tv/AndroidManifest.xml`
  - TV-only optional `android.software.leanback`, optional touchscreen,
    `LEANBACK_LAUNCHER`, TV banner, and Android TV app metadata.
- `android/app/src/mobile/google-services.json`
  - Mobile-flavor Firebase configuration for package `com.filmytell.ott`.
- `android/app/src/tv/google-services.json`
  - TV-flavor Firebase configuration for package `com.filmytell.ott`.
- `android/app/src/tv/res/drawable-xhdpi/tv_banner.png`
  - Android TV launcher banner resource.

## Firebase

Current Firebase behavior is preserved for:

- Android mobile
- Android TV
- iOS
- Web

Mobile and TV intentionally use the existing `com.filmytell.ott` Firebase app
and Play Store identity. Do not register a second package unless product
requirements explicitly change to a separate store listing.

## iOS

iOS keeps bundle identifier `com.filmytell.ott`.

Added files:

- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-iOS.xcscheme`
- `ios/Flutter/Flavor-ios.xcconfig`

The existing `Runner` scheme remains unchanged. Use `-t lib/main_ios.dart` for
iOS flavor builds.

## Web

The existing web assets, routing, Razorpay bridge, and hosting behavior remain
unchanged. Use `lib/main_web.dart` for web flavor builds.

## Build Commands

```bash
flutter run --flavor mobile -t lib/main.dart
flutter run --flavor tv -t lib/main.dart

flutter run --flavor mobile -t lib/main_mobile.dart --dart-define=FLAVOR=mobile
flutter run --flavor tv -t lib/main_tv.dart --dart-define=FLAVOR=tv
flutter run -t lib/main_ios.dart --dart-define=FLAVOR=ios
flutter run -d chrome -t lib/main_web.dart --dart-define=FLAVOR=web

flutter build appbundle --flavor mobile -t lib/main.dart
flutter build appbundle --flavor tv -t lib/main.dart

flutter build appbundle --flavor mobile -t lib/main_mobile.dart --dart-define=FLAVOR=mobile
flutter build appbundle --flavor tv -t lib/main_tv.dart --dart-define=FLAVOR=tv
flutter build ios -t lib/main_ios.dart --dart-define=FLAVOR=ios
flutter build web -t lib/main_web.dart --dart-define=FLAVOR=web
```

Because both Android flavors share a package name, use the explicit `main_*`
entrypoints shown above. The entrypoint is the authoritative runtime platform
signal; `--dart-define=FLAVOR=...` remains supported for CI and release builds.

## Deep Links And App Links

The shared Android manifest still preserves:

- `myapp://movie`
- `myapp://series`
- `myapp://short`
- `myapp://gift`
- `https://filmytell.in`
- `https://www.filmytell.in`

The existing `com.filmytell.ott` App Links registration and release certificate
remain authoritative for both form factors.

## Verification Checklist

- Mobile app installs as `com.filmytell.ott`.
- Android TV app installs as `com.filmytell.ott`.
- Android TV launcher shows the TV banner and Leanback launcher entry.
- Mobile launcher does not expose a Leanback launcher entry.
- Firebase initializes on mobile, TV, iOS, and web.
- Push notifications still initialize on non-web builds.
- Login and OTP work on mobile and TV.
- Search, wallet, profile, home rows, details pages, player, subscriptions,
  podcasts, live streaming, menus, dialogs, and back navigation remain usable.
- Deep links route to movie, series, short, and gift flows.
- Razorpay checkout still works on mobile and web.
- Existing web deployment still serves `index.html`, `manifest.json`, account
  deletion page, and asset links.
