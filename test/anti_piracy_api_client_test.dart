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
      expect(requestBody.keys, containsAll(<String>[
        'contentId',
        'deviceId',
        'playbackUrl',
        'country',
        'platform',
        'deviceIntegrity',
      ]));
      expect(requestBody['platform'], 'ANDROID');
      expect(
        result.cookieHeader,
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
    });

    test('accepts signed URL with nullable cookies and track arrays', () {
      final now = DateTime.now().toUtc();
      final epochSeconds =
          now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final response = SignedPlaybackResponse.fromJson(
        {
          'signedUrl': 'https://cdn.example.com/master.m3u8?Expires=1',
          'playbackUrl': 'https://cdn.example.com/master.m3u8?Expires=1',
          'authorizationType': 'CLOUDFRONT_SIGNED_URL',
          'cookies': null,
          'cookieHeader': null,
          'sessionId': 'session',
          'expiresAtEpochSeconds': epochSeconds,
          'audioTracks': null,
          'subtitleTracks': null,
        },
        platform: 'IOS',
        now: now,
      );

      expect(response.authorizationType,
          SignedPlaybackResponse.cloudFrontSignedUrl);
      expect(response.httpHeaders, isEmpty);
      expect(response.audioTracks, isEmpty);
      expect(response.subtitleTracks, isEmpty);
      expect(response.isValidAt(now), isTrue);
    });

    test('uses cautious platform fallback when authorization type is absent',
        () {
      final now = DateTime.now().toUtc();
      final epochSeconds =
          now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
      final android = SignedPlaybackResponse.fromJson(
        {
          'playbackUrl': 'https://cdn.example.com/master.m3u8',
          'cookieHeader': 'CloudFront-Policy=p; CloudFront-Signature=s; '
              'CloudFront-Key-Pair-Id=k',
          'sessionId': 'session',
          'expiresAtEpochSeconds': epochSeconds,
        },
        platform: 'ANDROID',
        now: now,
      );
      final web = SignedPlaybackResponse.fromJson(
        {
          'playbackUrl': 'https://cdn.example.com/master.m3u8?Expires=1',
          'sessionId': 'session',
          'expiresAtEpochSeconds': epochSeconds,
        },
        platform: 'WEB',
        now: now,
      );

      expect(android.httpHeaders['Cookie'], isNotEmpty);
      expect(web.authorizationType, SignedPlaybackResponse.cloudFrontSignedUrl);
      expect(web.httpHeaders, isEmpty);
    });

    test('automatic tracks select one default supported track only', () {
      const audioTracks = <SecureAudioTrack>[
        SecureAudioTrack(
          id: 'english-record-audio',
          label: 'English',
          language: 'en',
          url: 'https://cdn.example.com/audio/en.mp3',
          type: 'audio',
          format: 'mp3',
        ),
        SecureAudioTrack(
          id: 'hindi-record-audio',
          label: 'Hindi',
          language: 'hi',
          url: 'https://cdn.example.com/audio/hi.m3u8',
          type: 'hls',
          format: 'm3u8',
          isDefault: true,
        ),
        SecureAudioTrack(
          id: 'unexpected-second-audio',
          label: 'Marathi',
          language: 'mr',
          url: 'https://cdn.example.com/audio/mr.m3u8',
          type: 'hls',
          format: 'm3u8',
        ),
      ];
      const subtitleTracks = <SecureSubtitleTrack>[
        SecureSubtitleTrack(
          id: 'unsupported-srt',
          label: 'SRT',
          language: 'en',
          url: 'https://cdn.example.com/subtitle/en.srt',
          type: 'subtitle',
          format: 'srt',
        ),
        SecureSubtitleTrack(
          id: 'assigned-vtt',
          label: 'English',
          language: 'en',
          url: 'https://cdn.example.com/subtitle/en.vtt',
          type: 'subtitle',
          format: 'vtt',
        ),
      ];

      expect(getAutomaticAudioTrack(audioTracks)?.id, 'hindi-record-audio');
      expect(getAutomaticSubtitleTrack(subtitleTracks)?.id, 'assigned-vtt');
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
