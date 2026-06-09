import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/services/device_type_helper.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/user.dart';

enum PlaybackSecurityEvent {
  started('PLAYBACK_STARTED'),
  paused('PLAYBACK_PAUSED'),
  resumed('PLAYBACK_RESUMED'),
  completed('PLAYBACK_COMPLETED');

  const PlaybackSecurityEvent(this.apiValue);

  final String apiValue;
}

class PlaybackSecurityResult {
  const PlaybackSecurityResult({
    required this.allowed,
    required this.message,
  });

  final bool allowed;
  final String message;
}

class WatermarkIdentity {
  const WatermarkIdentity({
    required this.email,
  });

  final String email;
}

class AntiPiracyService {
  AntiPiracyService._();

  static final AntiPiracyService instance = AntiPiracyService._();

  static const MethodChannel _channel =
      MethodChannel('com.filmytell.ott/anti_piracy');

  Future<void> enableScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('enableSecureScreen');
    } catch (_) {}
  }

  Future<void> disableScreenProtection() async {
    try {
      await _channel.invokeMethod<void>('disableSecureScreen');
    } catch (_) {}
  }

  Future<WatermarkIdentity> watermarkIdentity() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    return WatermarkIdentity(
      email: _safeValue(user?.emailId, fallback: 'Unknown Email'),
    );
  }

  Future<PlaybackSecurityResult> validateBeforePlayback({
    required Content? content,
    required String playbackUrl,
    required bool isOfflinePlayback,
  }) async {
    final url = playbackUrl.trim();
    final sessionMessage = await _validateLocalSession();
    if (sessionMessage != null) {
      return PlaybackSecurityResult(allowed: false, message: sessionMessage);
    }

    if (!isOfflinePlayback) {
      final urlMessage = validatePlaybackUrl(url);
      if (urlMessage != null) {
        return PlaybackSecurityResult(allowed: false, message: urlMessage);
      }
    }

    final user = await LocalSharePreferences.localSharePreferences.getUser();
    final deviceInfo = await DeviceTypeHelper.buildSessionInfo();
    final integrity = await _readDeviceIntegrity();
    final backendDecision = await _validateWithBackend(
      content: content,
      playbackUrl: isOfflinePlayback ? null : url,
      user: user,
      deviceInfo: deviceInfo,
      integrity: integrity,
    );

    return backendDecision ??
        const PlaybackSecurityResult(
          allowed: true,
          message: '',
        );
  }

  String? validatePlaybackUrl(String playbackUrl) {
    final value = playbackUrl.trim();
    if (value.isEmpty) return 'Video unavailable';

    final youtubeIdPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (youtubeIdPattern.hasMatch(value)) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return 'Invalid playback link';

    final isHttpVideo = uri.scheme == 'https' || uri.scheme == 'http';
    final isFile = uri.scheme == 'file' || value.startsWith('/');
    if (!isHttpVideo && !isFile) return 'Invalid playback link';

    if (isHttpVideo && uri.scheme != 'https' && !kDebugMode) {
      return 'Secure playback link required';
    }

    final expiry = _expiryFromUri(uri);
    if (expiry != null && DateTime.now().toUtc().isAfter(expiry)) {
      return 'Playback link has expired. Please try again.';
    }

    return null;
  }

  Future<void> reportEvent({
    required PlaybackSecurityEvent event,
    required Content? content,
    required Duration? position,
    required Duration? duration,
    required bool isOfflinePlayback,
  }) async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      final deviceInfo = await DeviceTypeHelper.buildSessionInfo();
      final integrity = await _readDeviceIntegrity();
      final token = await SessionManager.instance.token;

      final body = {
        'event': event.apiValue,
        'contentId': content?.id,
        'contentType': content?.type,
        'positionSeconds': position?.inSeconds,
        'durationSeconds': duration?.inSeconds,
        'isOfflinePlayback': isOfflinePlayback,
        'debugBuild': kDebugMode,
        'userId': user?.id,
        'email': user?.emailId,
        'deviceId': deviceInfo.deviceId,
        'deviceName': deviceInfo.deviceName,
        'deviceType': deviceInfo.deviceType.apiValue,
        'appVersion': deviceInfo.appVersion,
        'deviceMetadata': deviceInfo.deviceMetadata,
        'rootedOrJailbroken': integrity.rootedOrJailbroken,
        'screenCaptured': integrity.screenCaptured,
      };

      await http
          .post(
            Uri.parse(ApiConstant.playbackPiracyEvent),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<String?> _validateLocalSession() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user?.id == null) return 'Please sign in again to continue watching.';

    final token = await SessionManager.instance.token;
    if (token == null) return 'Please sign in again to continue watching.';

    return null;
  }

  Future<PlaybackSecurityResult?> _validateWithBackend({
    required Content? content,
    required String? playbackUrl,
    required User? user,
    required DeviceSessionInfo deviceInfo,
    required _DeviceIntegrity integrity,
  }) async {
    try {
      final token = await SessionManager.instance.token;
      final response = await http
          .post(
            Uri.parse(ApiConstant.validatePlaybackSecurity),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'contentId': content?.id,
              'contentType': content?.type,
              'userId': user?.id,
              'email': user?.emailId,
              'playbackUrl': playbackUrl,
              'debugBuild': kDebugMode,
              'deviceId': deviceInfo.deviceId,
              'deviceName': deviceInfo.deviceName,
              'deviceType': deviceInfo.deviceType.apiValue,
              'appVersion': deviceInfo.appVersion,
              'deviceMetadata': deviceInfo.deviceMetadata,
              'rootedOrJailbroken': integrity.rootedOrJailbroken,
              'screenCaptured': integrity.screenCaptured,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (SessionManager.instance.isReplacementSessionResponse(response)) {
        final message = SessionManager.extractMessage(response.body) ??
            SessionManager.replacementSessionMessage;
        await SessionManager.instance.handleSessionExpired(message);
        return PlaybackSecurityResult(allowed: false, message: message);
      }

      if (response.statusCode == 404 || response.statusCode == 405) {
        return null;
      }

      if (response.statusCode == 409 || response.statusCode == 429) {
        return PlaybackSecurityResult(
          allowed: false,
          message: _messageFromBody(
            response.body,
            fallback:
                'Stream limit reached. Please stop playback on another device.',
          ),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return PlaybackSecurityResult(
          allowed: false,
          message: _messageFromBody(
            response.body,
            fallback: 'This device is not authorized for playback.',
          ),
        );
      }

      final decoded = _decodeMap(response.body);
      if (decoded == null) return null;

      final allowed = decoded['allowed'] ?? decoded['success'];
      if (allowed == false) {
        return PlaybackSecurityResult(
          allowed: false,
          message: _messageFromDecoded(
            decoded,
            fallback: 'Playback is not allowed on this device.',
          ),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<_DeviceIntegrity> _readDeviceIntegrity() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'deviceIntegrity',
      );
      return _DeviceIntegrity(
        rootedOrJailbroken: result?['rootedOrJailbroken'] == true,
        screenCaptured: result?['screenCaptured'] == true,
      );
    } catch (_) {
      return const _DeviceIntegrity(
        rootedOrJailbroken: false,
        screenCaptured: false,
      );
    }
  }

  static DateTime? _expiryFromUri(Uri uri) {
    final raw = uri.queryParameters['expires'] ??
        uri.queryParameters['expiry'] ??
        uri.queryParameters['expiresAt'] ??
        uri.queryParameters['exp'] ??
        uri.queryParameters['X-Amz-Expires'];
    if (raw == null || raw.trim().isEmpty) return null;

    final numeric = int.tryParse(raw);
    if (numeric != null) {
      if (numeric > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true);
      }
      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true);
      }
    }

    return DateTime.tryParse(raw)?.toUtc();
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _messageFromBody(String body, {required String fallback}) {
    final decoded = _decodeMap(body);
    if (decoded == null) return fallback;
    return _messageFromDecoded(decoded, fallback: fallback);
  }

  static String _messageFromDecoded(
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    final message = decoded['message'] ?? decoded['error'];
    final value = message?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static String _safeValue(String? value, {required String fallback}) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? fallback : normalized;
  }
}

class _DeviceIntegrity {
  const _DeviceIntegrity({
    required this.rootedOrJailbroken,
    required this.screenCaptured,
  });

  final bool rootedOrJailbroken;
  final bool screenCaptured;
}
