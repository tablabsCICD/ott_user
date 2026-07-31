import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/sharepreferences.dart';
import 'baseProvider.dart';

class PlayMediaProvider extends BaseProvider {
  /// ================= LOCAL RESUME CACHE =================

  /// key examples:
  /// movie_3
  /// series_1_2_5  (contentId_seasonId_episodeId)
  final Map<String, int> _resumeSecondsMap = {};

  final Map<String, int> _lastSavedSecondsMap = {};

  final Map<String, int> _resumeCache = {};
  String _movieKey(int contentId) => "movie_$contentId";

  String _episodeKey({
    required int contentId,
    required int seasonId,
    required int episodeId,
  }) =>
      "series_${contentId}_${seasonId}_$episodeId";

  // ================= ADD VIEW =================

  Future<void> addView({
    required int mediaId,
    required bool isSeries,
  }) async {
    try {
      final prefs = LocalSharePreferences();
      final user = await prefs.getUser();
      if (user?.id == null) return;

      final url = isSeries
          ? ApiConstant.addViewForEpisode(mediaId, user!.id!)
          : ApiConstant.addViewForMovie(mediaId, user!.id!);

      // This endpoint is protected. Going through ApiHelper keeps the view
      // request consistent with the rest of the authenticated API calls by
      // attaching the stored bearer token and handling an expired session.
      final response = await ApiHelper().postApi(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {}
    } catch (e) {
      log("Add view error: $e");
    }
  }

  // ================= SAVE RESUME (LOCAL + BACKEND) =================

  Future<void> saveContinueWatching({
    required int contentId,
    int? seasonId,
    int? episodeId,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      if (duration.inSeconds == 0) {
        return;
      }

      final key = episodeId != null && seasonId != null
          ? _episodeKey(
              contentId: contentId,
              seasonId: seasonId,
              episodeId: episodeId,
            )
          : _movieKey(contentId);

      final currentSeconds = position.inSeconds;
      final lastSaved = _lastSavedSecondsMap[key] ?? 0;

      /// ❌ DO NOT SPAM API
      if ((currentSeconds - lastSaved) < 5) return;

      // 🔥 SAVE LOCALLY (THIS FIXES YOUR BUG)
      _resumeSecondsMap[key] = currentSeconds;
      _lastSavedSecondsMap[key] = currentSeconds;

      final prefs = LocalSharePreferences();
      final user = await prefs.getUser();
      if (user?.id == null) {
        return;
      }

      final watchedPercentage =
          ((currentSeconds / duration.inSeconds) * 100).clamp(0, 100).toInt();

      final uri = Uri.parse(
        "${ApiConstant.baseUrl}continue-watching/save",
      ).replace(queryParameters: {
        "userId": user!.id.toString(),
        "contentId": contentId.toString(),
        "watchedSeconds": currentSeconds.toString(),
        "watchedPercentage": watchedPercentage.toString(),
        if (seasonId != null) "seasonId": seasonId.toString(),
        if (episodeId != null) "episodeId": episodeId.toString(),
      });

      final response = await ApiHelper().postApi(uri.toString());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
    } catch (e, stackTrace) {
      log('Continue watching save error: $e', stackTrace: stackTrace);
    }
  }

  // ================= GET RESUME TIME =================

  int getResumeSeconds({
    required int contentId,
    int? seasonId,
    int? episodeId,
  }) {
    final key = episodeId != null && seasonId != null
        ? _episodeKey(
            contentId: contentId,
            seasonId: seasonId,
            episodeId: episodeId,
          )
        : _movieKey(contentId);

    return _resumeSecondsMap[key] ?? 0;
  }

  // ================= AUTO NEXT EPISODE (FIXED) =================

  EpisodeEntity? getNextEpisode({
    required int seasonId,
    required int episodeId,
    required List<SeasonEntity> seasons,
  }) {
    for (int s = 0; s < seasons.length; s++) {
      final season = seasons[s];

      if (season.seasonId != seasonId) continue;

      for (int e = 0; e < season.episodes.length; e++) {
        if (season.episodes[e].episodeId == episodeId) {
          // next episode in same season
          if (e + 1 < season.episodes.length) {
            return season.episodes[e + 1];
          }

          // first episode of next season
          if (s + 1 < seasons.length && seasons[s + 1].episodes.isNotEmpty) {
            return seasons[s + 1].episodes.first;
          }

          return null;
        }
      }
    }
    return null;
  }

  Future<void> saveLocalResume({
    required int contentId,
    int? seasonId,
    int? episodeId,
    required int seconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final key = _resumeKey(
      contentId: contentId,
      seasonId: seasonId,
      episodeId: episodeId,
    );

    _resumeCache[key] = seconds;
    await prefs.setInt(key, seconds);

    notifyListeners(); // 🔥 IMMEDIATE UI UPDATE
  }

  int getLocalResume({
    required int contentId,
    int? seasonId,
    int? episodeId,
  }) {
    final key = _resumeKey(
      contentId: contentId,
      seasonId: seasonId,
      episodeId: episodeId,
    );

    return _resumeCache[key] ?? 0;
  }

  String _resumeKey({
    required int contentId,
    int? seasonId,
    int? episodeId,
  }) {
    return "resume_${contentId}_${seasonId ?? 0}_${episodeId ?? 0}";
  }

  Future<void> loadLocalResumes() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in prefs.getKeys()) {
      if (key.startsWith("resume_")) {
        _resumeCache[key] = prefs.getInt(key) ?? 0;
      }
    }

    notifyListeners();
  }
}
