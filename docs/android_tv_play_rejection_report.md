# Android TV Play Rejection Correction

## Confirmed source-level root cause

Version code 31 combined two competing TV login input paths. Merely focusing
the mobile field automatically invoked `TextInput.show`, while the same screen
also rendered a separate D-pad number pad and a page-level Center handler. The
reviewer was placed into the platform keyboard before choosing an input mode,
and Center could be consumed by the page handler. This matches the rejection at
the login keyboard and was confirmed by inspecting commit `b6c9788` (the TV
flavor with version code 31).

## Correction

- TV login now uses one deterministic in-app numeric keypad for the mobile and
  OTP flow; the mobile build continues using `IntlPhoneField` and its native
  Android IME.
- TV fields are read-only editing surfaces. Center moves focus to keypad key 1;
  the app no longer invokes `SystemChannels.textInput` from login focus changes.
- The persistent field, keypad, resend, Back, and submit FocusNodes are disposed
  by the screen state. Invalid mobile and OTP input restore focus to the
  corresponding field.
- Keypad digits, backspace, and Done are ordinary focusable `OttTvFocus`
  controls with visible border/scale/glow state and ordered traversal. Done
  moves focus to Send OTP or Verify OTP.
- The screen key handler handles only Center while a credential field has focus
  and ignores arrows, Back, and all other events so normal Flutter traversal and
  system Back behavior remain authoritative.

## Login focus order

1. Mobile-number field.
2. Keypad 1 through 9, Backspace, 0, Done after Center activation.
3. Send OTP.
4. After a successful send: OTP field.
5. The same keypad after Center activation.
6. Resend OTP when enabled.
7. Verify OTP.

The production authentication flow is mobile number plus OTP; there is no
password field or password-visibility control in this application.

## Verification completed on 20 July 2026

- The full Flutter suite passed (46 tests), including manifest, remote-key,
  10-second seek, secure playback, and update-version regression coverage.
- Signed TV release AAB and APK builds completed at version `1.0.16+33`.
- The final merged TV manifest retains both launcher categories and marks
  touchscreen, location/GPS, telephony, camera, microphone, NFC, Bluetooth,
  USB host, multitouch, portrait, and Leanback hardware declarations optional.
- Fresh installs and Leanback cold launches passed on separate Android 16
  Google TV and Android TV x86_64 emulators at 1920x1080. Google TV also passed
  a 1280x720 layout run.
- D-pad-only language selection, login-field activation, keypad digit entry,
  backspace, Done-to-submit focus, empty/short validation focus recovery,
  rapid directional input, Home/background, foreground relaunch, and root Back
  behavior were exercised without touch, mouse, external keyboard, crash, or
  ANR. `adb input text` was not used.
- A mobile release APK installed and launched on a separate phone emulator,
  preserving the standard mobile launcher.

The authenticated OTP, Home/content/search, and real signed-playback journey
still requires a reviewer test mobile number with live OTP access. Physical TV
hardware remains required for final device-specific IME, decoder, HDMI/audio,
and remote compatibility verification. Do not represent those steps as passed
until both inputs are available and the journey is executed end to end.
