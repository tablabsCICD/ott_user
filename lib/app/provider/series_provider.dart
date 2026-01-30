import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/SeriesDetailsResponse.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:ott/data/models/user.dart';

class SeriesProvider with ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper();

  bool _isLoading = false;
  String? _error;
  SeriesEntity? _series;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SeriesEntity? get series => _series;

  Future<void> fetchSeriesDetails(int seriesId) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConstant.seriesDetails(seriesId, user!.id);
      log('📡 Fetch Series URL: $url');

      final response = await _apiHelper.getApi(url);
      log('📥 Fetch Series Raw Response: ${response.body}');

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      log('🧩 Parsed Series JSON Keys: ${json.keys}');

      final data = SeriesDetailsResponse.fromJson(json);
      _series = data.toEntity();

      log('✅ Series Loaded: ${_series?.title}');
      log('🎬 Seasons Count: ${_series?.seasons.length}');
    } catch (e, st) {
      log('❌ SeriesProvider.fetchSeriesDetails Error: $e', stackTrace: st);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      log('🔄 fetchSeriesDetails completed');
    }
  }

  Future<bool> purchaseEpisode(int episodeId, int seriesId) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();

    try {
      final url = ApiConstant.purchaseEpisode(episodeId, user!.id);
      log('🛒 Purchase Episode URL: $url');

      final response = await _apiHelper.putApi(url);

      log('📥 Status: ${response.statusCode}');
      log('📥 Raw: ${response.body}');

      if (response.statusCode != 200) {
        _error =
            'Server error (${response.statusCode}). Please try again later.';
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true || json['isSuccess'] == true) {
        log('✅ Episode purchased: $episodeId');
        await fetchSeriesDetails(seriesId);
        return true;
      }

      _error = json['message'] ?? 'Purchase failed';
      notifyListeners();
      return false;
    } catch (e, st) {
      log('❌ purchaseEpisode exception: $e', stackTrace: st);
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> purchaseSeason(int seasonId, int seriesId) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();

    try {
      final url = ApiConstant.purchaseSeason(seasonId, user!.id);
      log('🛒 Purchase Episode URL: $url');

      final response = await _apiHelper.putApi(url);

      log('📥 Status: ${response.statusCode}');
      log('📥 Raw: ${response.body}');

      if (response.statusCode != 200) {
        _error =
            'Server error (${response.statusCode}). Please try again later.';
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true || json['isSuccess'] == true) {
        log('✅ Episode purchased: $seasonId');
        await fetchSeriesDetails(seriesId);
        return true;
      }

      _error = json['message'] ?? 'Purchase failed';
      notifyListeners();
      return false;
    } catch (e, st) {
      log('❌ purchaseSeason exception: $e', stackTrace: st);
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    log('🧹 Clearing SeriesProvider state');
    _series = null;
    _error = null;
    notifyListeners();
  }
}
