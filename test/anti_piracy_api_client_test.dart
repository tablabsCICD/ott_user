import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

void main() {
  group('AntiPiracyApiClient', () {
    test('adds Authorization and X-Device-Id headers', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'userId': '1',
            'userName': 'Viewer',
            'email': 'viewer@example.com',
            'deviceId': 'device-1',
            'timestamp': '2026-07-09T10:30:00Z',
            'signature': 'secret',
          }),
          200,
        );
      });
      final api = AntiPiracyApiClient(
        client: client,
        tokenProvider: () async => 'test-token',
      );

      await api.getWatermark(deviceId: 'device-1');

      expect(captured.headers['authorization'], 'Bearer test-token');
      expect(captured.headers['x-device-id'], 'device-1');
    });

    test('parses valid signed playback response as UTC', () async {
      final expiry = DateTime.now().toUtc().add(const Duration(minutes: 10));
      final api = AntiPiracyApiClient(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'signedUrl': 'https://cdn.example.com/master.m3u8?token=secret',
                'sessionId': 'session-1',
                'expiresAt': expiry.toIso8601String(),
              }),
              200,
            )),
        tokenProvider: () async => 'token',
      );

      final result = await api.createSignedPlayback(
        const SignedPlaybackRequest(
          contentId: 'movie-1',
          deviceId: 'device-1',
          playbackUrl: 'https://cdn.example.com/master.m3u8',
          country: 'IN',
          deviceIntegrity: DeviceIntegrityStatus(
            rooted: false,
            jailbroken: false,
            emulator: false,
          ),
        ),
      );

      expect(result.sessionId, 'session-1');
      expect(result.expiresAt.isUtc, isTrue);
    });

    test('maps 401 and 403 without exposing backend body', () async {
      for (final status in [401, 403]) {
        final api = AntiPiracyApiClient(
          client: MockClient((_) async => http.Response(
                jsonEncode({'message': 'sensitive backend detail'}),
                status,
              )),
          tokenProvider: () async => 'token',
        );
        try {
          await api.registerDevice(const DeviceIdentity(
            deviceId: 'device-1',
            deviceType: 'ANDROID',
            deviceName: 'Phone',
            osVersion: 'Android 15',
          ));
          fail('Expected secure playback exception');
        } on SecurePlaybackException catch (error) {
          expect(
            error.failure,
            status == 401
                ? SecurePlaybackFailure.unauthenticated
                : SecurePlaybackFailure.accessDenied,
          );
          expect(error.userMessage, isNot(contains('sensitive')));
        }
      }
    });
  });

  group('SignedPlaybackResponse', () {
    test('accepts fractional Unix epoch seconds from the backend', () {
      const epochSeconds = 1784015010.3254907;
      final response = SignedPlaybackResponse.fromJson(
        {
          'signedUrl': 'https://cdn.example.com/master.m3u8?token=secret',
          'sessionId': 'session',
          'expiresAt': epochSeconds,
        },
        now: DateTime.fromMillisecondsSinceEpoch(
          1784014000000,
          isUtc: true,
        ),
      );

      expect(response.expiresAt.isUtc, isTrue);
      expect(
        response.expiresAt.microsecondsSinceEpoch,
        (epochSeconds * 1000000).round(),
      );
    });

    test('rejects non-HTTPS and expired responses', () {
      expect(
        () => SignedPlaybackResponse.fromJson({
          'signedUrl': 'http://cdn.example.com/master.m3u8',
          'sessionId': 'session',
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
        }),
        throwsFormatException,
      );
      expect(
        () => SignedPlaybackResponse.fromJson({
          'signedUrl': 'https://cdn.example.com/master.m3u8',
          'sessionId': 'session',
          'expiresAt': DateTime.now()
              .toUtc()
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
        }),
        throwsFormatException,
      );
    });
  });
}
