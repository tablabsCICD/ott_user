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
  const SignedPlaybackRequest({
    required this.contentId,
    required this.deviceId,
    required this.playbackUrl,
    required this.country,
    required this.deviceIntegrity,
  });

  final String contentId;
  final String deviceId;
  final String playbackUrl;
  final String country;
  final DeviceIntegrityStatus deviceIntegrity;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'deviceId': deviceId,
        'playbackUrl': playbackUrl,
        'country': country,
        'deviceIntegrity': deviceIntegrity.toJson(),
      };
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
  });

  static const cloudFrontSignedCookies = 'CLOUDFRONT_SIGNED_COOKIES';
  static const requiredCookieNames = <String>{
    'CloudFront-Policy',
    'CloudFront-Signature',
    'CloudFront-Key-Pair-Id',
  };

  final String playbackUrl;
  final String signedUrl;
  final String authorizationType;
  final Map<String, String> cookies;
  final String sessionId;
  final DateTime expiresAt;
  final int expiresAtEpochSeconds;

  String get cookieHeader =>
      requiredCookieNames.map((name) => '$name=${cookies[name]}').join('; ');

  bool get isValid => isValidAt(DateTime.now().toUtc());

  bool isValidAt(DateTime now) {
    final uri = Uri.tryParse(playbackUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        authorizationType == cloudFrontSignedCookies &&
        sessionId.isNotEmpty &&
        expiresAtEpochSeconds > now.toUtc().millisecondsSinceEpoch ~/ 1000 &&
        requiredCookieNames.every((name) {
          final value = cookies[name];
          return value != null &&
              value.isNotEmpty &&
              !value.contains(RegExp(r'[;\r\n]'));
        });
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
    final authorizationType =
        (json['authorizationType'] ?? '').toString().trim();
    if (authorizationType != cloudFrontSignedCookies) {
      throw const FormatException('Unsupported playback authorization.');
    }

    final rawCookies = json['cookies'];
    if (rawCookies is! Map) {
      throw const FormatException('Missing CloudFront playback cookies.');
    }
    final cookies = rawCookies.map(
      (key, value) => MapEntry(key.toString(), value.toString().trim()),
    );
    final cookiesValid = requiredCookieNames.every((name) {
      final value = cookies[name];
      return value != null &&
          value.isNotEmpty &&
          !value.contains(RegExp(r'[;\r\n]'));
    });
    if (!cookiesValid) {
      throw const FormatException('Invalid CloudFront playback cookies.');
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
      sessionId: sessionId,
      expiresAt: expiresAt,
      expiresAtEpochSeconds: expiresAtEpochSeconds,
    );
  }
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
    final normalizedDevice = deviceId.replaceAll('-', '').toUpperCase();
    final shortDevice = normalizedDevice.length <= 6
        ? normalizedDevice
        : normalizedDevice.substring(normalizedDevice.length - 6);
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
