import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/provider/secure_playback_controller.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

class _ControllerRepository extends SecurePlaybackRepository {
  int createCalls = 0;
  final List<PlaybackAnalyticsEvent> events = [];
  Completer<SignedPlaybackResponse>? pendingRefresh;

  @override
  Future<SignedPlaybackResponse> createSignedPlaybackSession({
    required String contentId,
    required String playbackUrl,
    required String country,
  }) async {
    createCalls++;
    if (createCalls > 1 && pendingRefresh != null) {
      return pendingRefresh!.future;
    }
    return _response('session-$createCalls');
  }

  @override
  Future<WatermarkData> getCurrentWatermark() async => WatermarkData(
        userId: '1',
        userName: 'Viewer',
        email: 'viewer@example.com',
        deviceId: '2f44b286-0ca9-4f9f-8b29-a777e02ea198',
        timestamp: DateTime(2026, 7, 9),
        signature: 'secret',
      );

  @override
  Future<void> sendAnalytics({
    required String contentId,
    required String sessionId,
    required String country,
    required PlaybackAnalyticsEvent event,
  }) async {
    events.add(event);
  }

  SignedPlaybackResponse _response(String sessionId) {
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
    return SignedPlaybackResponse(
      playbackUrl: 'https://cdn.example.com/$sessionId/master.m3u8',
      signedUrl: 'https://cdn.example.com/$sessionId/master.m3u8',
      authorizationType: SignedPlaybackResponse.cloudFrontSignedCookies,
      cookies: {
        'CloudFront-Policy': 'policy-$sessionId',
        'CloudFront-Signature': 'signature-$sessionId',
        'CloudFront-Key-Pair-Id': 'key-pair',
      },
      sessionId: sessionId,
      expiresAt: expiresAt,
      expiresAtEpochSeconds: expiresAt.millisecondsSinceEpoch ~/ 1000,
    );
  }
}

void main() {
  test('loads cookie-authorized URL and never passes original URL', () async {
    final repository = _ControllerRepository();
    final loaded = <SignedPlaybackResponse>[];
    final controller = SecurePlaybackController(
      contentId: 'movie-1',
      originalPlaybackUrl: 'https://origin.example.com/master.m3u8',
      country: 'IN',
      repository: repository,
      mediaLoader: (authorization, {required isRefresh}) async {
        loaded.add(authorization);
        return const SecureMediaRestoreResult(isPlaying: true);
      },
      pausePlayer: () async {},
    );

    await controller.start();

    expect(
      loaded.single.playbackUrl,
      startsWith('https://cdn.example.com/session-1/'),
    );
    expect(loaded.single.playbackUrl, isNot(controller.originalPlaybackUrl));
    expect(
      loaded.single.effectiveCookieHeader,
      'CloudFront-Policy=policy-session-1; '
      'CloudFront-Signature=signature-session-1; '
      'CloudFront-Key-Pair-Id=key-pair',
    );
    expect(controller.state, SecurePlaybackState.playing);
    controller.dispose();
  });

  test('refresh is single-flight and uses refresh loader mode', () async {
    final repository = _ControllerRepository();
    final refreshModes = <bool>[];
    final loadedSessions = <String>[];
    final controller = SecurePlaybackController(
      contentId: 'movie-1',
      originalPlaybackUrl: 'https://origin.example.com/master.m3u8',
      country: 'IN',
      repository: repository,
      mediaLoader: (authorization, {required isRefresh}) async {
        refreshModes.add(isRefresh);
        loadedSessions.add(authorization.sessionId);
        return const SecureMediaRestoreResult(isPlaying: false);
      },
      pausePlayer: () async {},
    );
    await controller.start();
    repository.pendingRefresh = Completer<SignedPlaybackResponse>();

    final first = controller.refreshNow();
    final second = controller.refreshNow();
    await Future<void>.delayed(Duration.zero);
    expect(repository.createCalls, 2);
    repository.pendingRefresh!.complete(repository._response('session-2'));
    await Future.wait([first, second]);

    expect(repository.createCalls, 2);
    expect(refreshModes, [false, true]);
    expect(loadedSessions, ['session-1', 'session-2']);
    controller.dispose();
  });

  test('refresh delay is calculated from expiry', () {
    final now = DateTime.utc(2026, 7, 9, 10);
    expect(
      SecurePlaybackController.refreshDelay(
        expiresAt: now.add(const Duration(minutes: 10)),
        now: now,
      ),
      const Duration(minutes: 9),
    );
  });

  test('does not send playback start when media loading fails', () async {
    final repository = _ControllerRepository();
    final controller = SecurePlaybackController(
      contentId: 'movie-1',
      originalPlaybackUrl: 'https://origin.example.com/master.m3u8',
      country: 'IN',
      repository: repository,
      mediaLoader: (authorization, {required isRefresh}) async {
        throw StateError('player rejected source');
      },
      pausePlayer: () async {},
    );

    await controller.start();

    expect(controller.state, SecurePlaybackState.playbackError);
    expect(repository.events, isNot(contains(PlaybackAnalyticsEvent.start)));
    controller.dispose();
  });
}
