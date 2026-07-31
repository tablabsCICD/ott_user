enum DeviceIntegrityState { verified, unknown }

class DeviceIntegrityStatus {
  const DeviceIntegrityStatus({
    required this.rooted,
    required this.jailbroken,
    required this.emulator,
    this.state = DeviceIntegrityState.verified,
  });

  const DeviceIntegrityStatus.unknown()
      : rooted = false,
        jailbroken = false,
        emulator = false,
        state = DeviceIntegrityState.unknown;

  final bool rooted;
  final bool jailbroken;
  final bool emulator;
  final DeviceIntegrityState state;

  Map<String, dynamic> toJson() => {
        'rooted': rooted,
        'jailbroken': jailbroken,
        'emulator': emulator,
      };
}

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.osVersion,
  });

  final String deviceId;
  final String deviceType;
  final String deviceName;
  final String osVersion;

  Map<String, dynamic> toRegistrationJson() => {
        'deviceId': deviceId,
        'deviceType': deviceType,
        'deviceName': deviceName,
        'osVersion': osVersion,
      };
}

class DeviceBinding {
  const DeviceBinding({
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.osVersion,
    required this.authorized,
    required this.blocked,
    required this.current,
  });

  final String deviceId;
  final String deviceType;
  final String deviceName;
  final String osVersion;
  final bool authorized;
  final bool blocked;
  final bool current;

  factory DeviceBinding.fromJson(
    Map<String, dynamic> json, {
    String? currentDeviceId,
  }) {
    final id = (json['deviceId'] ?? json['id'] ?? '').toString();
    final rawStatus = (json['authorizationState'] ?? json['status'] ?? '')
        .toString()
        .toUpperCase();
    final blocked = json['blocked'] == true || rawStatus == 'BLOCKED';
    final authorized = json['authorized'] == true ||
        rawStatus == 'AUTHORIZED' ||
        rawStatus == 'ACTIVE';
    return DeviceBinding(
      deviceId: id,
      deviceType: (json['deviceType'] ?? 'UNKNOWN').toString(),
      deviceName: (json['deviceName'] ?? 'Unknown device').toString(),
      osVersion: (json['osVersion'] ?? '-').toString(),
      authorized: authorized && !blocked,
      blocked: blocked,
      current: id.isNotEmpty && id == currentDeviceId,
    );
  }
}

class SignedPlaybackRequest {
  SignedPlaybackRequest({
    required this.contentId,
    required this.deviceId,
    required this.playbackUrl,
    required this.type,
    required this.country,
    required this.platform,
    required this.deviceIntegrity,
  });

  final String contentId;
  final String deviceId;
  final String playbackUrl;
  final String type;
  final String country;
  final String platform;
  final DeviceIntegrityStatus deviceIntegrity;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'deviceId': deviceId,
        'playbackUrl': playbackUrl,
        'type': type,
        'country': country,
        'platform': platform,
        'deviceIntegrity': deviceIntegrity.toJson(),
      };
}

class PlaybackTrackInfo {
  const PlaybackTrackInfo({
    required this.id,
    required this.label,
    required this.language,
    required this.url,
    required this.type,
    required this.format,
  });

  final String id;
  final String label;
  final String language;
  final String url;
  final String type;
  final String format;

  bool get isHls =>
      type.toLowerCase() == 'hls' || format.toLowerCase() == 'm3u8';

  bool get isVtt => format.toLowerCase() == 'vtt';

  factory PlaybackTrackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackTrackInfo(
      id: (json['id'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
      language: (json['language'] ?? '').toString().trim(),
      url: (json['url'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim(),
      format: (json['format'] ?? '').toString().trim(),
    );
  }
}

class SecurePlaybackConfig {
  const SecurePlaybackConfig({
    required this.playbackUrl,
    required this.httpHeaders,
    required this.authorizationType,
    required this.sessionId,
    required this.expiresAt,
    required this.audioTracks,
    required this.subtitleTracks,
  });

  final String playbackUrl;
  final Map<String, String> httpHeaders;
  final String authorizationType;
  final String sessionId;
  final DateTime expiresAt;
  final List<PlaybackTrackInfo> audioTracks;
  final List<PlaybackTrackInfo> subtitleTracks;

  bool get usesSignedCookies =>
      authorizationType == SignedPlaybackResponse.cloudFrontSignedCookies;

  bool get usesSignedUrl =>
      authorizationType == SignedPlaybackResponse.cloudFrontSignedUrl;
}

class SignedPlaybackResponse {
  const SignedPlaybackResponse({
    required this.playbackUrl,
    required this.signedUrl,
    required this.authorizationType,
    required this.cookies,
    required this.sessionId,
    required this.expiresAt,
    required this.expiresAtEpochSeconds,
    this.cookieHeader,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
  });

  static const cloudFrontSignedCookies = 'CLOUDFRONT_SIGNED_COOKIES';
  static const cloudFrontSignedUrl = 'CLOUDFRONT_SIGNED_URL';
  static const requiredCookieNames = <String>{
    'CloudFront-Policy',
    'CloudFront-Signature',
    'CloudFront-Key-Pair-Id',
  };

  final String playbackUrl;
  final String signedUrl;
  final String authorizationType;
  final Map<String, String> cookies;
  final String? cookieHeader;
  final String sessionId;
  final DateTime expiresAt;
  final int expiresAtEpochSeconds;
  final List<PlaybackTrackInfo> audioTracks;
  final List<PlaybackTrackInfo> subtitleTracks;

  String get effectiveCookieHeader {
    final rawHeader = cookieHeader?.trim();
    if (rawHeader != null &&
        rawHeader.isNotEmpty &&
        !rawHeader.contains(RegExp(r'[\r\n]'))) {
      return rawHeader;
    }
    return requiredCookieNames
        .map((name) => '$name=${cookies[name]}')
        .join('; ');
  }

  bool get isValid => isValidAt(DateTime.now().toUtc());

  bool isValidAt(DateTime now) {
    final uri = Uri.tryParse(playbackUrl);
    final baseValid = uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        sessionId.isNotEmpty &&
        expiresAtEpochSeconds > now.toUtc().millisecondsSinceEpoch ~/ 1000;
    if (!baseValid) return false;
    if (authorizationType == cloudFrontSignedUrl) return true;
    if (authorizationType != cloudFrontSignedCookies) return false;
    if (effectiveCookieHeader.isEmpty ||
        effectiveCookieHeader.contains(RegExp(r'[\r\n]'))) {
      return false;
    }
    return requiredCookieNames.every((name) {
      final value = cookies[name];
      return value != null &&
          value.isNotEmpty &&
          !value.contains(RegExp(r'[;\r\n]'));
    });
  }

  SecurePlaybackConfig toPlaybackConfig() {
    if (!isValid) {
      throw StateError('Secure playback authorization is invalid or expired.');
    }
    if (authorizationType == cloudFrontSignedCookies) {
      return SecurePlaybackConfig(
        playbackUrl: playbackUrl,
        httpHeaders: {'Cookie': effectiveCookieHeader},
        authorizationType: authorizationType,
        sessionId: sessionId,
        expiresAt: expiresAt,
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
      );
    }
    if (authorizationType == cloudFrontSignedUrl) {
      return SecurePlaybackConfig(
        playbackUrl: playbackUrl,
        httpHeaders: const {},
        authorizationType: authorizationType,
        sessionId: sessionId,
        expiresAt: expiresAt,
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
      );
    }
    throw StateError('Unsupported playback authorization type.');
  }

  factory SignedPlaybackResponse.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final playbackUrl = (json['playbackUrl'] ?? '').toString().trim();
    final uri = Uri.tryParse(playbackUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Invalid secure playback URL.');
    }

    final signedUrl = (json['signedUrl'] ?? '').toString().trim();
    var authorizationType = (json['authorizationType'] ?? '').toString().trim();
    final rawCookieHeader = json['cookieHeader']?.toString().trim();
    if (authorizationType.isEmpty) {
      authorizationType = rawCookieHeader != null && rawCookieHeader.isNotEmpty
          ? cloudFrontSignedCookies
          : cloudFrontSignedUrl;
    }
    if (authorizationType != cloudFrontSignedCookies &&
        authorizationType != cloudFrontSignedUrl) {
      throw const FormatException('Unsupported playback authorization.');
    }

    var cookies = const <String, String>{};
    final rawCookies = json['cookies'];
    if (rawCookies is Map) {
      cookies = rawCookies.map(
        (key, value) => MapEntry(key.toString(), value.toString().trim()),
      );
    }
    if (authorizationType == cloudFrontSignedCookies) {
      if (rawCookieHeader != null &&
          rawCookieHeader.isNotEmpty &&
          rawCookieHeader.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException('Invalid CloudFront playback cookies.');
      }
      final cookieHeaderValid = rawCookieHeader != null &&
          rawCookieHeader.isNotEmpty &&
          !rawCookieHeader.contains(RegExp(r'[\r\n]'));
      final cookiesValid = requiredCookieNames.every((name) {
        final value = cookies[name];
        return value != null &&
            value.isNotEmpty &&
            !value.contains(RegExp(r'[;\r\n]'));
      });
      if (!cookieHeaderValid && !cookiesValid) {
        throw const FormatException('Missing CloudFront playback cookies.');
      }
      if (!cookiesValid && cookieHeaderValid) {
        cookies = _cookiesFromHeader(rawCookieHeader);
      }
      if (!requiredCookieNames
          .every((name) => cookies[name]?.isNotEmpty == true)) {
        throw const FormatException('Invalid CloudFront playback cookies.');
      }
    }

    final sessionId = (json['sessionId'] ?? '').toString().trim();
    if (sessionId.isEmpty) {
      throw const FormatException('Missing secure playback session.');
    }

    final rawEpoch = json['expiresAtEpochSeconds'];
    final epochNumber =
        rawEpoch is num ? rawEpoch : num.tryParse(rawEpoch?.toString() ?? '');
    final expiresAtEpochSeconds = epochNumber?.toInt() ?? 0;
    DateTime? expiresAt;
    if (expiresAtEpochSeconds > 0) {
      try {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(
          expiresAtEpochSeconds * 1000,
          isUtc: true,
        );
      } on ArgumentError {
        expiresAt = null;
      }
    }
    if (expiresAt == null ||
        !expiresAt.isAfter((now ?? DateTime.now()).toUtc())) {
      throw const FormatException('Secure playback authorization has expired.');
    }

    return SignedPlaybackResponse(
      playbackUrl: playbackUrl,
      signedUrl: signedUrl,
      authorizationType: authorizationType,
      cookies: Map<String, String>.unmodifiable(cookies),
      cookieHeader: rawCookieHeader,
      sessionId: sessionId,
      expiresAt: expiresAt,
      expiresAtEpochSeconds: expiresAtEpochSeconds,
      audioTracks: _tracksFromJson(json['audioTracks']),
      subtitleTracks: _tracksFromJson(json['subtitleTracks']),
    );
  }
}

Map<String, String> _cookiesFromHeader(String header) {
  final values = <String, String>{};
  for (final part in header.split(';')) {
    final separator = part.indexOf('=');
    if (separator <= 0) continue;
    final name = part.substring(0, separator).trim();
    final value = part.substring(separator + 1).trim();
    if (SignedPlaybackResponse.requiredCookieNames.contains(name) &&
        value.isNotEmpty &&
        !value.contains(RegExp(r'[;\r\n]'))) {
      values[name] = value;
    }
  }
  return values;
}

List<PlaybackTrackInfo> _tracksFromJson(dynamic rawTracks) {
  if (rawTracks is! List) return const [];
  return rawTracks
      .whereType<Map>()
      .map((item) => PlaybackTrackInfo.fromJson(item.cast<String, dynamic>()))
      .where((track) {
    final uri = Uri.tryParse(track.url);
    return track.url.isNotEmpty &&
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }).toList(growable: false);
}

enum PlaybackAnalyticsEvent {
  start('PLAYBACK_START'),
  pause('PLAYBACK_PAUSE'),
  resume('PLAYBACK_RESUME'),
  stop('PLAYBACK_STOP');

  const PlaybackAnalyticsEvent(this.apiValue);
  final String apiValue;
}

class PlaybackAnalyticsRequest {
  const PlaybackAnalyticsRequest({
    required this.contentId,
    required this.deviceId,
    required this.sessionId,
    required this.country,
    required this.eventType,
  });

  final String contentId;
  final String deviceId;
  final String sessionId;
  final String country;
  final PlaybackAnalyticsEvent eventType;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'country': country,
        'eventType': eventType.apiValue,
      };
}

class WatermarkData {
  const WatermarkData({
    required this.userId,
    required this.userName,
    required this.email,
    required this.deviceId,
    required this.timestamp,
    required this.signature,
  });

  final String userId;
  final String userName;
  final String email;
  final String deviceId;
  final DateTime timestamp;
  final String signature;

  factory WatermarkData.fromJson(Map<String, dynamic> json) {
    return WatermarkData(
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      timestamp:
          DateTime.tryParse((json['timestamp'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      signature: (json['signature'] ?? '').toString(),
    );
  }

  String get displayText {
    final identity = maskEmail(email).isNotEmpty
        ? maskEmail(email)
        : (userId.isEmpty ? 'Viewer' : userId);
    final local = timestamp.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$identity • $date';
  }

  static String maskEmail(String value) {
    final email = value.trim();
    final at = email.indexOf('@');
    if (at <= 0 || at == email.length - 1) return '';
    final local = email.substring(0, at);
    final visible =
        local.length <= 2 ? local.substring(0, 1) : local.substring(0, 2);
    return '$visible***${email.substring(at)}';
  }
}
