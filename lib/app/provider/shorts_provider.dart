import 'package:flutter/foundation.dart';
import 'package:ott/app/core/utils/mini_series_api_log.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/data/models/user.dart';
import 'baseProvider.dart';
import 'package:ott/app/core/utils/app_l10n.dart';

class ShortsSectionData {
  final String language;
  final String category;
  final List<ShortModel> shorts;

  const ShortsSectionData({
    required this.language,
    required this.category,
    required this.shorts,
  });
}

class ShortProvider extends BaseProvider {
  List<ShortModel> shorts = [];
  List<ShortsSectionData> _shortSections = [];
  List<ShortsSectionData> get shortSections => _shortSections;
  ShortDetailModel? shortDetail;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchShorts() async {
    await fetchShortsByLanguages(const ["English"]);
  }

  Future<void> fetchShortsByLanguages(List<String> languages) async {
    final effectiveLanguages = languages
        .where((lang) => lang.trim().isNotEmpty)
        .map((lang) => lang.trim())
        .toSet()
        .toList();

    if (effectiveLanguages.isEmpty) {
      effectiveLanguages.add("English");
    }

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final sections = <ShortsSectionData>[];
      if (kDebugMode) {
        debugPrint('[MINI_SERIES_LIBRARY] Loading languages: $effectiveLanguages');
      }

      for (final lang in effectiveLanguages) {
        final latest = await getLatestMiniSeries(language: lang);
        final trending = await getTrendingMiniSeries(language: lang);

        sections.add(
          ShortsSectionData(
            language: lang,
            category: appL10n().msgLatestMiniSeries,
            shorts: latest.content,
          ),
        );
        sections.add(
          ShortsSectionData(
            language: lang,
            category: appL10n().msgTrendingMiniSeries,
            shorts: trending.content,
          ),
        );
      }

      _shortSections = sections;
      shorts = sections.expand((row) => row.shorts).toList();
      if (kDebugMode) {
        for (final short in shorts) {
          _engagementLog('MINI_SERIES_HOME_VIEWS',
              'seriesId=${short.id} viewCount=${short.viewCount}');
          _engagementLog('MINI_SERIES_HOME_LIKES',
              'seriesId=${short.id} likeCount=${short.likeCount} '
              '(not shown on the card)');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MINI_SERIES_LIBRARY] Load failed: ${e.runtimeType}: $e');
        debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
      }
      _shortSections = [];
      shorts = [];
      errorMessage = appL10n().msgUnableToLoadMiniSeries;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<MiniSeriesPage> getLatestMiniSeries({
    required String language,
    int page = 0,
    int size = 10,
  }) =>
      _fetchMiniSeriesPage(
          type: 'latest', language: language, page: page, size: size);

  Future<MiniSeriesPage> getTrendingMiniSeries({
    required String language,
    int page = 0,
    int size = 10,
  }) =>
      _fetchMiniSeriesPage(
          type: 'trending', language: language, page: page, size: size);

  Future<MiniSeriesPage> _fetchMiniSeriesPage({
    required String type,
    required String language,
    int page = 0,
    int size = 10,
  }) async {
    final apiUrl = type.toLowerCase() == 'trending'
        ? ApiConstant.getTrendingShortsByLang(language, page, size: size)
        : ApiConstant.getLatestShortsByLang(language, page, size: size);
    final url = Uri.parse(apiUrl);
    // Mini Series dashboard endpoints are authenticated, just like Movies.
    // ApiHelper attaches the current bearer token and applies session handling.
    final response = await ApiHelper().getApi(url.toString());
    if (kDebugMode) {
      final raw = response.body.toString();
      debugPrint('[MINI_SERIES_LIBRARY] GET $url -> ${response.statusCode} '
          'body: ${raw.length > 600 ? '${raw.substring(0, 600)}...' : raw}');
    }

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Mini Series $type request failed (${response.statusCode})',
        url,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Mini Series response is missing page data');
    }
    final result = MiniSeriesPage.fromJson(data);
    if (kDebugMode) {
      debugPrint('[MINI_SERIES_LIBRARY] $type/$language: '
          '${result.content.length} items (total ${result.totalElements})');
    }
    return result;
  }

  Future<void> fetchShortDetail(int id, int userId) async {
    try {
      isLoading = true;
      errorMessage = null;
      shortDetail = null;
      notifyListeners();

      final url = Uri.parse(ApiConstant.shortsDetails(id, userId));
      final apiHelper = ApiHelper();
      final stopwatch = Stopwatch()..start();
      // Debug-only logging; carries hasFullSeriesGiftAccess for gift access.
      MiniSeriesApiLog.request(
        apiName: MiniSeriesApiLog.detailRefresh,
        method: 'GET',
        url: url.toString(),
        headers: await apiHelper.headersForDiagnostics(),
      );
      final dynamic response;
      try {
        response = await apiHelper.getApi(url.toString());
      } catch (error, stackTrace) {
        MiniSeriesApiLog.exception(
          apiName: MiniSeriesApiLog.detailRefresh,
          url: url.toString(),
          error: error,
          stackTrace: stackTrace,
          elapsed: stopwatch.elapsed,
        );
        rethrow;
      }
      MiniSeriesApiLog.response(
        apiName: MiniSeriesApiLog.detailRefresh,
        url: url.toString(),
        statusCode: response.statusCode as int,
        body: response.body.toString(),
        headers: Map<String, String>.from(response.headers as Map),
        elapsed: stopwatch.elapsed,
      );
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Mini Series detail request failed (${response.statusCode})',
          url,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true ||
          decoded['data'] is! Map<String, dynamic>) {
        throw const FormatException(
          'Mini Series detail response is missing data',
        );
      }
      final data = decoded['data'] as Map<String, dynamic>;
      shortDetail = ShortDetailModel.fromJson(data);
      if (kDebugMode) {
        final detail = shortDetail!;
        _engagementLog('MINI_SERIES_ENGAGEMENT_MAPPING',
            'GET api/shortsMaster/$id status=200 seriesId=${detail.id} '
            'series likeCount=${detail.likeCount} viewCount=${detail.viewCount} '
            'parts=${detail.parts.length}');
        final rawParts = data['parts'];
        if (rawParts is List && rawParts.isNotEmpty && rawParts.first is Map) {
          _engagementLog('MINI_SERIES_ENGAGEMENT_MAPPING',
              'part fields from backend: ${(rawParts.first as Map).keys.toList()}');
        }
        for (final part in detail.parts) {
          _engagementLog('MINI_SERIES_EPISODE_LIKES',
              'seriesId=${detail.id} partId=${part.partId} '
              'part#${part.partNumber} likes=${part.likes} '
              'isLiked=${part.isLiked} views=${part.views}');
        }
      }
    } catch (e) {
      _engagementLog('MINI_SERIES_ENGAGEMENT_MAPPING',
          'detail $id failed: ${e.runtimeType}');
    }

    isLoading = false;
    notifyListeners();
  }

  /// like short
  bool _isLiking = false;
  bool get isLiking => _isLiking;

  Future<bool> likeShortPart({required int partId}) async {
    return _toggleLike(
      partId: partId,
      isLike: true,
    );
  }

  /// unlike short
  Future<bool> unlikeShortPart({required int partId}) async {
    return _toggleLike(
      partId: partId,
      isLike: false,
    );
  }

  Future<bool> _toggleLike({
    required int partId,
    required bool isLike,
  }) async {
    final action = isLike ? 'LIKE' : 'UNLIKE';
    // One like/unlike request at a time (repeated taps / double-tap).
    if (_isLiking) {
      _engagementLog('MINI_SERIES_LIKE_ACTION',
          '$action ignored (request in progress) partId=$partId');
      return false;
    }
    final User? user =
        await LocalSharePreferences.localSharePreferences.getUser();

    if (user == null) return false;

    try {
      _isLiking = true;
      notifyListeners();

      final url = isLike
          ? ApiConstant.likeshort(partId, user.id)
          : ApiConstant.unlikeshort(partId, user.id);
      _engagementLog('MINI_SERIES_LIKE_ACTION',
          '$action POST api/shortsMaster/part/$partId/${isLike ? "like" : "unlike"}');

      // The backend protects these endpoints (401 "Unauthorized access"
      // without a token): ApiHelper attaches the stored bearer token, the
      // same way every other Mini Series call is made. URL/method unchanged.
      final response = await ApiHelper().postApi(url);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final ok = body is Map && body["success"] == true;
        _engagementLog('MINI_SERIES_LIKE_ACTION',
            '$action partId=$partId status=200 success=$ok');
        return ok;
      }

      _engagementLog('MINI_SERIES_LIKE_ACTION',
          '$action partId=$partId status=${response.statusCode} (not applied)');
      return false;
    } catch (e) {
      _engagementLog('MINI_SERIES_LIKE_ACTION',
          '$action partId=$partId failed: ${e.runtimeType}');
      return false;
    } finally {
      _isLiking = false;
      notifyListeners();
    }
  }

  // views count for shorts
  Future<bool> addShortView({required int partId}) async {
    try {
      // Protected endpoint (401 without a token): sent through ApiHelper.
      final response =
          await ApiHelper().postApi(ApiConstant.viewsShort(partId));
      _engagementLog('MINI_SERIES_EPISODE_VIEWS',
          'POST api/shortsMaster/part/$partId/view status=${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body is Map && body["success"] == true;
      }
      return false;
    } catch (e) {
      _engagementLog('MINI_SERIES_EPISODE_VIEWS',
          'partId=$partId failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Debug-only engagement trace (no tokens, URLs with user ids, or bodies).
  void _engagementLog(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  //purchase short

  Future<Map<String, dynamic>?> purchaseShortPart({
    required int partId,
    String? couponCode,
    String? idempotencyKey,
  }) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user == null) return null;
    final url = ApiConstant.purchaseShort(
      partId,
      user.id!,
      couponCode: couponCode,
      idempotencyKey: idempotencyKey,
    );
    log('short purchase URL======== $url');
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.putApi(url);
      log('short purchase response statuscode======== ${response.statusCode}');

      if (response.statusCode == 200) {
        log('short purchase response ========1234 ');

        final body = json.decode(response.body);
        log('short purchase response======== $body');

        // Fresh purchase
        if (body["success"] == true) {
          return body["data"];
        }

        // Already purchased → treat as success
        if (body["success"] == false &&
            body["message"] == "You already purchased this short part") {
          return {
            "alreadyPurchased": true,
            "shortPartId": partId,
          };
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
