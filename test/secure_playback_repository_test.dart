import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/core/services/device_identity_service.dart';
import 'package:ott/app/core/services/device_integrity_service.dart';
import 'package:ott/data/models/anti_piracy_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store implements DeviceIdStore {
  String? value = '2f44b286-0ca9-4f9f-8b29-a777e02ea198';
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

class _Integrity implements DeviceIntegrityChecker {
  @override
  Future<DeviceIntegrityStatus> checkIntegrity() async =>
      const DeviceIntegrityStatus(
        rooted: false,
        jailbroken: false,
        emulator: false,
      );
}

class _UnknownIntegrity implements DeviceIntegrityChecker {
  @override
  Future<DeviceIntegrityStatus> checkIntegrity() async =>
      const DeviceIntegrityStatus.unknown();
}

class _RegistrationApi extends AntiPiracyApiClient {
  int calls = 0;
  final Completer<void> pending = Completer<void>();

  @override
  Future<void> registerDevice(DeviceIdentity identity) async {
    calls++;
    await pending.future;
  }
}

class _PlaybackApi extends AntiPiracyApiClient {
  SignedPlaybackRequest? request;
  String? registeredDeviceId;

  @override
  Future<void> registerDevice(DeviceIdentity identity) async {
    registeredDeviceId = identity.deviceId;
  }

  @override
  Future<SignedPlaybackResponse> createSignedPlayback(
    SignedPlaybackRequest request,
  ) async {
    this.request = request;
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
    return SignedPlaybackResponse(
      playbackUrl: 'https://cdn.example.com/master.m3u8',
      signedUrl: 'https://cdn.example.com/master.m3u8',
      authorizationType: SignedPlaybackResponse.cloudFrontSignedCookies,
      cookies: const {
        'CloudFront-Policy': 'policy',
        'CloudFront-Signature': 'signature',
        'CloudFront-Key-Pair-Id': 'key-pair',
      },
      sessionId: 'session-id',
      expiresAt: expiresAt,
      expiresAtEpochSeconds: expiresAt.millisecondsSinceEpoch ~/ 1000,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('device registration is single-flight', () async {
    final api = _RegistrationApi();
    final repository = SecurePlaybackRepository(
      apiClient: api,
      identityService: DeviceIdentityService(
        store: _Store(),
        platformInfoLoader: () async => {
          'deviceName': 'Phone',
          'osVersion': 'Android 15',
        },
      ),
      integrityService: _Integrity(),
    );

    final first = repository.registerCurrentDevice();
    final second = repository.registerCurrentDevice();
    await Future<void>.delayed(Duration.zero);
    expect(api.calls, 1);
    api.pending.complete();
    await Future.wait([first, second]);
    expect(api.calls, 1);
  });

  test('unknown local integrity is forwarded to backend policy', () async {
    final api = _PlaybackApi();
    final repository = SecurePlaybackRepository(
      apiClient: api,
      identityService: DeviceIdentityService(
        store: _Store(),
        platformInfoLoader: () async => {
          'deviceName': 'Phone',
          'osVersion': 'Android 15',
        },
      ),
      integrityService: _UnknownIntegrity(),
    );

    final response = await repository.createSignedPlaybackSession(
      contentId: 'movie-123',
      playbackUrl: 'https://cdn.example.com/master.m3u8',
      country: 'IN',
    );

    expect(response.sessionId, 'session-id');
    expect(api.request, isNotNull);
    expect(api.request!.deviceId, api.registeredDeviceId);
    expect(api.request!.platform, 'ANDROID');
    expect(
      api.request!.deviceIntegrity.state,
      DeviceIntegrityState.unknown,
    );
  });
}
