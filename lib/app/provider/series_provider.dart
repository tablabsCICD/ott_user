import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/response/SeriesDetailsResponse.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:ott/data/models/user.dart';
import 'baseProvider.dart';

class SeriesPurchaseResult {
  const SeriesPurchaseResult({
    required this.success,
    required this.message,
    this.coinsDeducted,
    this.newBalance,
    this.seriesId,
    this.seasonId,
    this.episodeId,
    this.invoiceUrl,
  });

  final bool success;
  final String message;
  final int? coinsDeducted;
  final int? newBalance;
  final int? seriesId;
  final int? seasonId;
  final int? episodeId;
  final String? invoiceUrl;

  factory SeriesPurchaseResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : <String, dynamic>{};

    return SeriesPurchaseResult(
      success: json['success'] == true || json['isSuccess'] == true,
      message: (data['message'] ?? json['message'] ?? 'Purchase failed')
          .toString(),
      coinsDeducted: _asInt(data['coinsDeducted']),
      newBalance: _asInt(data['newBalance']),
      seriesId: _asInt(data['seriesId']),
      seasonId: _asInt(data['seasonId']),
      episodeId: _asInt(data['episodeId']),
      invoiceUrl: data['invoiceUrl']?.toString(),
    );
  }

  factory SeriesPurchaseResult.failure(String message) {
    return SeriesPurchaseResult(
      success: false,
      message: message,
    );
  }
}

class SeriesProvider extends BaseProvider {
  final ApiHelper _apiHelper = ApiHelper();

  bool _isLoading = false;
  String? _error;
  SeriesEntity? _series;
  bool _isPurchasing = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SeriesEntity? get series => _series;
  bool get isPurchasing => _isPurchasing;

  Future<void> fetchSeriesDetails(int seriesId) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConstant.seriesDetails(seriesId, user?.id ?? 1);
      log('Fetch Series URL: $url');

      final response = await _apiHelper.getApi(url);
      log('Fetch Series Raw Response: ${response.body}');

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      final data = SeriesDetailsResponse.fromJson(json);
      _series = data.toEntity();
    } catch (e, st) {
      log('SeriesProvider.fetchSeriesDetails error: $e', stackTrace: st);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SeriesPurchaseResult> purchaseEpisode(
    int episodeId,
    int seriesId,
  ) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();

    if (_isPurchasing) {
      _error = 'Purchase already in progress. Please wait.';
      notifyListeners();
      return SeriesPurchaseResult.failure(_error!);
    }

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConstant.purchaseEpisode(episodeId, user!.id);
      log('Purchase Episode URL: $url');

      final response = await _apiHelper.putApi(url);
      log('Purchase Episode Status: ${response.statusCode}');
      log('Purchase Episode Raw: ${response.body}');

      if (response.statusCode != 200) {
        _error =
            'Server error (${response.statusCode}). Please try again later.';
        notifyListeners();
        return SeriesPurchaseResult.failure(_error!);
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final result = SeriesPurchaseResult.fromJson(json);

      if (result.success) {
        await fetchSeriesDetails(seriesId);
        return result;
      }

      _error = result.message;
      notifyListeners();
      return result;
    } catch (e, st) {
      log('purchaseEpisode exception: $e', stackTrace: st);
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return SeriesPurchaseResult.failure(_error!);
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<SeriesPurchaseResult> purchaseSeason(
    int seasonId,
    int seriesId,
  ) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();

    if (_isPurchasing) {
      _error = 'Purchase already in progress. Please wait.';
      notifyListeners();
      return SeriesPurchaseResult.failure(_error!);
    }

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConstant.purchaseSeason(seasonId, user!.id);
      log('Purchase Season URL: $url');

      final response = await _apiHelper.putApi(url);
      log('Purchase Season Status: ${response.statusCode}');
      log('Purchase Season Raw: ${response.body}');

      if (response.statusCode != 200) {
        _error =
            'Server error (${response.statusCode}). Please try again later.';
        notifyListeners();
        return SeriesPurchaseResult.failure(_error!);
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final result = SeriesPurchaseResult.fromJson(json);

      if (result.success) {
        await fetchSeriesDetails(seriesId);
        return result;
      }

      _error = result.message;
      notifyListeners();
      return result;
    } catch (e, st) {
      log('purchaseSeason exception: $e', stackTrace: st);
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return SeriesPurchaseResult.failure(_error!);
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  void clear() {
    _series = null;
    _error = null;
    notifyListeners();
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
