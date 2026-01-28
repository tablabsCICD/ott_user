import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/response/series_details.dart';

class SeriesProvider extends ChangeNotifier {
  SeriesDetailsResponse? _data;
  bool _loading = false;
  String? _error;

  final Set<int> _purchasedEpisodes = {};
  final Set<int> _purchasedSeasons = {};

  bool get loading => _loading;
  String? get error => _error;
  SeriesDetailsResponse? get data => _data;

  bool isEpisodeUnlocked(Episode ep) =>
      ep.free || _purchasedEpisodes.contains(ep.id);

  bool isSeasonUnlocked(int seasonId) => _purchasedSeasons.contains(seasonId);

  Future<void> loadSeries(int seriesId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstant.seriesDetails(seriesId));
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final jsonMap = jsonDecode(utf8.decode(res.bodyBytes));
        _data = SeriesDetailsResponse.fromJson(jsonMap);
      } else {
        _error = "Failed to load series (${res.statusCode})";
      }
    } catch (e) {
      _error = "Unable to load series";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> purchaseEpisode({
    required int episodeId,
    required int userId,
  }) async {
    final url = Uri.parse(
      "${ApiConstant.baseUrl}/ott/series/purchase/episode?episodeId=$episodeId&userId=$userId",
    );

    final res = await http.put(url);
    final json = jsonDecode(res.body);

    if (json['success'] == true) {
      _purchasedEpisodes.add(episodeId);
      notifyListeners();
      return json['data']['message'];
    } else {
      return json['message'];
    }
  }

  Future<String> purchaseSeason({
    required int seasonId,
    required int userId,
    required List<Episode> episodes,
  }) async {
    final url = Uri.parse(
      "${ApiConstant.baseUrl}/ott/series/purchase/season?seasonId=$seasonId&userId=$userId",
    );

    final res = await http.put(url);
    final json = jsonDecode(res.body);

    if (json['success'] == true) {
      _purchasedSeasons.add(seasonId);
      for (final ep in episodes) {
        _purchasedEpisodes.add(ep.id);
      }
      notifyListeners();
      return json['data']['message'];
    } else {
      return json['message'];
    }
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    _purchasedEpisodes.clear();
    _purchasedSeasons.clear();
    notifyListeners();
  }
}
