import 'package:flutter/services.dart';

/// Native screen-capture protection used while the secure player is visible.
/// Network authorization, signing, analytics, and watermarking live in the
/// contract-specific secure playback components.
class AntiPiracyService {
  AntiPiracyService._();

  static final AntiPiracyService instance = AntiPiracyService._();
  static const MethodChannel _channel =
      MethodChannel('com.filmytell.ott/anti_piracy');

  Future<void> enableScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('enableSecureScreen');
    } catch (_) {
      // Screen protection is defense in depth. Playback authorization remains
      // fail-closed in SecurePlaybackRepository.
    }
  }

  Future<void> disableScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('disableSecureScreen');
    } catch (_) {}
  }
}
