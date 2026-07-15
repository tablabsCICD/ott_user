import 'dart:async';

import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

class PlaybackAnalyticsCoordinator {
  PlaybackAnalyticsCoordinator({
    required SecurePlaybackRepository repository,
    required this.contentId,
    required this.country,
  }) : _repository = repository;

  final SecurePlaybackRepository _repository;
  final String contentId;
  final String country;
  String? _sessionId;
  bool _started = false;
  bool _lastPlaying = false;
  bool _stopped = false;
  bool _disposed = false;

  void bindSession(String sessionId) {
    _sessionId = sessionId;
    _started = false;
    _lastPlaying = false;
    _stopped = false;
    SecurityDebugLog.event(
      'ANALYTICS',
      'Playback session bound in memory; session ID remains redacted.',
    );
  }

  void onPlayingChanged(bool isPlaying) {
    if (_disposed || _stopped || _sessionId == null) return;
    if (isPlaying && !_started) {
      _started = true;
      _lastPlaying = true;
      unawaited(_send(PlaybackAnalyticsEvent.start));
      return;
    }
    if (!_started || isPlaying == _lastPlaying) return;
    _lastPlaying = isPlaying;
    unawaited(_send(
      isPlaying ? PlaybackAnalyticsEvent.resume : PlaybackAnalyticsEvent.pause,
    ));
  }

  Future<void> stopCurrentSession() async {
    if (_stopped || _sessionId == null) return;
    _stopped = true;
    await _send(PlaybackAnalyticsEvent.stop);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stopCurrentSession();
    _disposed = true;
    _sessionId = null;
  }

  Future<void> _send(PlaybackAnalyticsEvent event) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    try {
      SecurityDebugLog.event(
        'ANALYTICS',
        'Sending ${event.apiValue}.',
      );
      await _repository.sendAnalytics(
        contentId: contentId,
        sessionId: sessionId,
        country: country,
        event: event,
      );
      SecurityDebugLog.event(
        'ANALYTICS',
        '${event.apiValue} accepted.',
      );
    } catch (_) {
      SecurityDebugLog.event(
        'ANALYTICS',
        '${event.apiValue} failed; playback is not interrupted.',
      );
      // Analytics is best-effort and must never interrupt playback.
    }
  }
}
