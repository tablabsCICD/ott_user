import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/cast_member.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/continueWatchedResponse.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/data/models/user.dart';
import '../../data/models/response/get_dashboard_data.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import 'baseProvider.dart';

class DashboardProvider extends BaseProvider {
  DashboardProvider() : super('Ideal');

  static const Duration _continueWatchingCacheDuration = Duration(minutes: 2);
  static const Duration _continueWatchingRequestTimeout = Duration(seconds: 6);

  List<DashboardData> _dashboardData = [];
  List<DashboardData> get dashboardData => _dashboardData;

  Content _content = Content();
  Content get content => _content;
  List<CastMember> _castList = [];
  List<CastMember> get castList => _castList;

  TextEditingController searchContentController = TextEditingController();

  bool _isLoadingDashboard = false;
  bool get isLoading => _isLoadingDashboard;
  bool _isLoadingCast = false;
  bool get isLoadingCast => _isLoadingCast;

  List<Content> _continueWatchedMovies = [];
  List<Content> get continueWatchedMovies => _continueWatchedMovies;
  bool _isLoadingContinueWatching = false;
  bool get isLoadingContinueWatching => _isLoadingContinueWatching;
  String? _activeContinueWatchingKey;
  final Map<String, List<Content>> _continueWatchingCache = {};
  final Map<String, DateTime> _continueWatchingCacheTimes = {};
  final Map<String, Future<void>> _continueWatchingRequests = {};

  // ==================== DASHBOARD LOAD ====================

  Future<void> getDashboardData(
    String type,
    List<String> languages,
    int userId,
  ) async {
    if (_isLoadingDashboard) return;

    _isLoadingDashboard = true;
    notifyListeners();
    List<DashboardData> finalDashboardData = [];

    debugPrint("Languages: $languages");

    for (final lang in languages) {
      debugPrint("➡ Loading dashboard for: $lang");

      try {
        final dashboardRows = await Future.wait([
          getDashboardLatestData(type, [lang], userId),
          getDashboardTrendingData(type, [lang], userId),
          getDashboardUpcomingData(type, [lang], userId),
        ]);

        final latest = dashboardRows[0];
        final trending = dashboardRows[1];
        final upcoming = dashboardRows[2];

        _initRowLoadingState(latest);
        _initRowLoadingState(trending);
        _initRowLoadingState(upcoming);

        finalDashboardData.addAll(latest);
        finalDashboardData.addAll(trending);
        finalDashboardData.addAll(upcoming);
      } catch (e) {
        debugPrint("❌ Dashboard error ($lang): $e");
      }
    }

    _isLoadingDashboard = false;
    _dashboardData = finalDashboardData;
    notifyListeners();
  }

  /// Only reset UI loading state — pagination comes from backend
  void _initRowLoadingState(List<DashboardData> rows) {
    for (final row in rows) {
      row.isRowLoading = false;
    }
  }

  // ==================== HORIZONTAL PAGINATION ====================

  Future<void> loadMoreRowData(
    DashboardData row,
    String type,
    int userId,
  ) async {
    if (row.isRowLoading || !row.hasMore) return;

    row.isRowLoading = true;
    notifyListeners();

    final nextPage = row.currentPage + 1;

    try {
      List<DashboardData> newData = [];

      final cat = row.category?.toLowerCase() ?? "";

      if (cat.contains("latest")) {
        newData = await getDashboardLatestPaged(
            type, [row.language!], userId, nextPage);
      } else if (cat.contains("trending")) {
        newData = await getDashboardTrendingPaged(
            type, [row.language!], userId, nextPage);
      } else if (cat.contains("upcoming")) {
        newData = await getDashboardUpcomingPaged(
            type, [row.language!], userId, nextPage);
      }

      if (newData.isNotEmpty &&
          newData.first.movies != null &&
          newData.first.movies!.isNotEmpty) {
        row.movies!.addAll(newData.first.movies!);
        row.pagination = newData.first.pagination;
      }
    } catch (e) {
      debugPrint("❌ Pagination error: $e");
    }

    row.isRowLoading = false;
    notifyListeners();
  }

  // ==================== PAGED APIs ====================

  Future<List<DashboardData>> getDashboardLatestPaged(
    String type,
    List<String> languages,
    int userId,
    int page,
  ) async {
    return _getPagedApi("latest", type, languages, userId, page);
  }

  Future<List<DashboardData>> getDashboardTrendingPaged(
    String type,
    List<String> languages,
    int userId,
    int page,
  ) async {
    return _getPagedApi("trending", type, languages, userId, page);
  }

  Future<List<DashboardData>> getDashboardUpcomingPaged(
    String type,
    List<String> languages,
    int userId,
    int page,
  ) async {
    return _getPagedApi("upcoming", type, languages, userId, page);
  }

  Future<List<DashboardData>> _getPagedApi(
    String endpoint,
    String type,
    List<String> languages,
    int userId,
    int page,
  ) async {
    String languagesParam = languages.map((lang) => "lang=$lang").join('&');

    String apiUrl =
        "${ApiConstant.getNewDashboardData}$endpoint?type=$type&$languagesParam&userId=$userId&page=$page&size=10";

    ApiHelper apiHelper = ApiHelper();
    var response = await apiHelper.getApi(apiUrl);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return DashboardResponse.fromJson(responseBody).data ?? [];
    } else {
      throw Exception('$endpoint paged API Failed');
    }
  }

  // ==================== ORIGINAL APIs ====================

  Future<List<DashboardData>> getDashboardLatestData(
      String type, List<String> languages, int userId) async {
    return getDashboardLatestPaged(type, languages, userId, 0);
  }

  Future<List<DashboardData>> getDashboardTrendingData(
      String type, List<String> languages, int userId) async {
    return getDashboardTrendingPaged(type, languages, userId, 0);
  }

  Future<List<DashboardData>> getDashboardUpcomingData(
      String type, List<String> languages, int userId) async {
    return getDashboardUpcomingPaged(type, languages, userId, 0);
  }

  // ==================== CONTENT DETAILS ====================

  Future<Content?> getContentById(int id) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.getVideoById(id, user?.id ?? 1);
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        GetContentResponse addUserResponse =
            GetContentResponse.fromJson(responseBody);

        if (addUserResponse.success == true &&
            addUserResponse.data?.contentList != null) {
          _content = addUserResponse.data!.contentList!;
          notifyListeners();
          return _content;
        }
      }
    } catch (error) {
      debugPrint("❌ getContentById error::: $error");
    }
    return null;
  }

  Future<void> getCastByContentId(int contentId) async {
    _isLoadingCast = true;
    notifyListeners();

    final apiUrl = ApiConstant.getCastByContentId(contentId);
    final apiHelper = ApiHelper();

    try {
      final response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final castData = responseBody['data']?['cast'] as List?;

        _castList = castData == null
            ? []
            : castData.map((item) => CastMember.fromJson(item)).toList();
      } else {
        _castList = [];
      }
    } catch (error) {
      debugPrint("cast fetch error: $error");
      _castList = [];
    } finally {
      _isLoadingCast = false;
      notifyListeners();
    }
  }

  Future<void> getContinueWatchedMovieList(
    String type, {
    bool forceRefresh = false,
  }) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    final userId = user?.id;
    if (userId == null) {
      _setActiveContinueWatchingData(null, const <Content>[]);
      return;
    }

    final normalizedType = type.toUpperCase();
    final cacheKey = '$userId:$normalizedType';
    _activeContinueWatchingKey = cacheKey;

    final cachedItems = _continueWatchingCache[cacheKey];
    if (cachedItems != null) {
      _continueWatchedMovies = cachedItems;
      notifyListeners();

      if (!forceRefresh && _isContinueWatchingCacheFresh(cacheKey)) {
        return;
      }
    } else if (_continueWatchedMovies.isNotEmpty) {
      _continueWatchedMovies = const <Content>[];
      notifyListeners();
    }

    final inFlightRequest = _continueWatchingRequests[cacheKey];
    if (inFlightRequest != null) {
      await inFlightRequest;
      return;
    }

    _isLoadingContinueWatching = true;
    notifyListeners();

    final request = _fetchContinueWatching(
      apiUrl: ApiConstant.continueWatchedMoviesByUser(userId, normalizedType),
      cacheKey: cacheKey,
    );
    _continueWatchingRequests[cacheKey] = request;

    try {
      await request;
    } finally {
      _continueWatchingRequests.remove(cacheKey);
      if (_activeContinueWatchingKey == cacheKey) {
        _isLoadingContinueWatching = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchContinueWatching({
    required String apiUrl,
    required String cacheKey,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final response = await ApiHelper()
          .getApi1(apiUrl)
          .timeout(_continueWatchingRequestTimeout);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final continueWatchedResponse =
            ContinueWatchedResponse.fromJson(responseBody);

        if (continueWatchedResponse.isSuccess == true) {
          final items = continueWatchedResponse.data ?? const <Content>[];
          _continueWatchingCache[cacheKey] = items;
          _continueWatchingCacheTimes[cacheKey] = DateTime.now();
          debugPrint(
            "✅ continue watching loaded ${items.length} items "
            "in ${watch.elapsedMilliseconds}ms",
          );
          _setActiveContinueWatchingData(cacheKey, items);
          return;
        }
      }

      if (!_continueWatchingCache.containsKey(cacheKey)) {
        _setActiveContinueWatchingData(cacheKey, const <Content>[]);
      }
    } catch (error) {
      debugPrint("❌ continue watching error: $error");
      if (!_continueWatchingCache.containsKey(cacheKey)) {
        _setActiveContinueWatchingData(cacheKey, const <Content>[]);
      }
    }
  }

  bool _isContinueWatchingCacheFresh(String cacheKey) {
    final fetchedAt = _continueWatchingCacheTimes[cacheKey];
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) <
        _continueWatchingCacheDuration;
  }

  void _setActiveContinueWatchingData(String? cacheKey, List<Content> items) {
    if (cacheKey != null && _activeContinueWatchingKey != cacheKey) {
      return;
    }
    _continueWatchedMovies = items;
    notifyListeners();
  }

  void clear() {
    _dashboardData.clear();
    _continueWatchedMovies.clear();
    _continueWatchingCache.clear();
    _continueWatchingCacheTimes.clear();
    _continueWatchingRequests.clear();
    _isLoadingContinueWatching = false;
    _activeContinueWatchingKey = null;
    _castList.clear();
    notifyListeners();
  }
}
