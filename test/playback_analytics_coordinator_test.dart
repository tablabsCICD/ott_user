import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/core/services/playback_analytics_coordinator.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

class _AnalyticsRepository extends SecurePlaybackRepository {
  final List<PlaybackAnalyticsEvent> events = [];

  @override
  Future<void> sendAnalytics({
    required String contentId,
    required String sessionId,
    required String country,
    required PlaybackAnalyticsEvent event,
  }) async {
    events.add(event);
  }
}

void main() {
  test('deduplicates transitions and sends STOP once', () async {
    final repository = _AnalyticsRepository();
    final coordinator = PlaybackAnalyticsCoordinator(
      repository: repository,
      contentId: 'movie-1',
      country: 'IN',
    )..bindSession('session-1');

    coordinator.onPlayingChanged(true);
    coordinator.onPlayingChanged(true);
    coordinator.onPlayingChanged(false);
    coordinator.onPlayingChanged(false);
    coordinator.onPlayingChanged(true);
    await coordinator.stopCurrentSession();
    await coordinator.stopCurrentSession();
    await Future<void>.delayed(Duration.zero);

    expect(repository.events, [
      PlaybackAnalyticsEvent.start,
      PlaybackAnalyticsEvent.pause,
      PlaybackAnalyticsEvent.resume,
      PlaybackAnalyticsEvent.stop,
    ]);
  });
}
