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
      final expiryEpoch = expiry.millisecondsSinceEpoch ~/ 1000;
      late http.Request capturedRequest;
      final api = AntiPiracyApiClient(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'signedUrl': 'https://cdn.example.com/master.m3u8',
              'playbackUrl': 'https://cdn.example.com/master.m3u8',
              'authorizationType': 'CLOUDFRONT_SIGNED_COOKIES',
              'cookies': {
                'CloudFront-Policy': 'policy',
                'CloudFront-Signature': 'signature',
                'CloudFront-Key-Pair-Id': 'key-pair',
              },
              'sessionId': 'session-1',
              'expiresAt': expiry.toIso8601String(),
              'expiresAtEpochSeconds': expiryEpoch,
            }),
            200,
          );
        }),
        tokenProvider: () async => 'token',
      );

      final result = await api.createSignedPlayback(
        const SignedPlaybackRequest(
          contentId: 'movie-1',
          deviceId: 'device-1',
          playbackUrl: 'https://cdn.example.com/master.m3u8',
          country: 'IN',
          platform: 'ANDROID',
          deviceIntegrity: DeviceIntegrityStatus(
            rooted: false,
            jailbroken: false,
            emulator: false,
          ),
        ),
      );

      expect(result.sessionId, 'session-1');
      expect(result.expiresAt.isUtc, isTrue);
      expect(result.playbackUrl, 'https://cdn.example.com/master.m3u8');
      final requestBody = jsonDecode(capturedRequest.body) as Map;
      expect(requestBody['contentId'], isA<String>());
      expect(
          requestBody.keys,
          containsAll(<String>[
            'contentId',
            'deviceId',
            'playbackUrl',
            'country',
            'platform',
            'deviceIntegrity',
          ]));
      expect(requestBody['platform'], 'ANDROID');
      expect(
        result.effectiveCookieHeader,
        'CloudFront-Policy=policy; CloudFront-Signature=signature; '
        'CloudFront-Key-Pair-Id=key-pair',
      );
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
    test('accepts signed-cookie response and epoch expiry', () {
      final now = DateTime.now().toUtc();
      final epochSeconds =
          now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final response = SignedPlaybackResponse.fromJson(
        {
          'signedUrl': 'https://cdn.example.com/master.m3u8',
          'playbackUrl': 'https://cdn.example.com/master.m3u8',
          'authorizationType': 'CLOUDFRONT_SIGNED_COOKIES',
          'cookies': {
            'CloudFront-Policy': 'policy',
            'CloudFront-Signature': 'signature',
            'CloudFront-Key-Pair-Id': 'key-pair',
          },
          'sessionId': 'session',
          'expiresAt': DateTime.fromMillisecondsSinceEpoch(
            epochSeconds * 1000,
            isUtc: true,
          ).toIso8601String(),
          'expiresAtEpochSeconds': epochSeconds,
        },
        now: now,
      );

      expect(response.expiresAt.isUtc, isTrue);
      expect(response.expiresAtEpochSeconds, epochSeconds);
      expect(response.isValidAt(now), isTrue);
      expect(response.toPlaybackConfig().httpHeaders['Cookie'], isNotEmpty);
    });

    test('accepts signed-url response without cookies', () {
      final now = DateTime.now().toUtc();
      final epochSeconds =
          now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final response = SignedPlaybackResponse.fromJson(
        {
          'signedUrl':
              'https://cdn.example.com/master.m3u8?Expires=1&Signature=s&Key-Pair-Id=k',
          'playbackUrl':
              'https://cdn.example.com/master.m3u8?Expires=1&Signature=s&Key-Pair-Id=k',
          'authorizationType': 'CLOUDFRONT_SIGNED_URL',
          'cookies': null,
          'cookieHeader': null,
          'sessionId': 'session',
          'expiresAtEpochSeconds': epochSeconds,
          'audioTracks': [],
          'subtitleTracks': [],
        },
        now: now,
      );

      final config = response.toPlaybackConfig();

      expect(response.isValidAt(now), isTrue);
      expect(
          config.authorizationType, SignedPlaybackResponse.cloudFrontSignedUrl);
      expect(config.httpHeaders, isEmpty);
      expect(config.playbackUrl, contains('Signature=s'));
    });

    test('rejects missing cookie authorization and expired responses', () {
      expect(
        () => SignedPlaybackResponse.fromJson({
          'signedUrl': 'https://cdn.example.com/master.m3u8',
          'playbackUrl': 'https://cdn.example.com/master.m3u8',
          'authorizationType': 'CLOUDFRONT_SIGNED_COOKIES',
          'sessionId': 'session',
          'expiresAtEpochSeconds':
              DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
        }),
        throwsFormatException,
      );
      expect(
        () => SignedPlaybackResponse.fromJson({
          'signedUrl': 'https://cdn.example.com/master.m3u8',
          'playbackUrl': 'https://cdn.example.com/master.m3u8',
          'authorizationType': 'CLOUDFRONT_SIGNED_COOKIES',
          'cookies': {
            'CloudFront-Policy': 'policy\r\ninjected-header: value',
            'CloudFront-Signature': 'signature',
            'CloudFront-Key-Pair-Id': 'key-pair',
          },
          'sessionId': 'session',
          'expiresAtEpochSeconds':
              DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
        }),
        throwsFormatException,
      );
      expect(
        () => SignedPlaybackResponse.fromJson({
          'signedUrl': 'https://cdn.example.com/master.m3u8',
          'playbackUrl': 'https://cdn.example.com/master.m3u8',
          'authorizationType': 'CLOUDFRONT_SIGNED_COOKIES',
          'cookies': {
            'CloudFront-Policy': 'policy',
            'CloudFront-Signature': 'signature',
            'CloudFront-Key-Pair-Id': 'key-pair',
          },
          'sessionId': 'session',
          'expiresAtEpochSeconds':
              DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1,
        }),
        throwsFormatException,
      );
    });
  });
}
