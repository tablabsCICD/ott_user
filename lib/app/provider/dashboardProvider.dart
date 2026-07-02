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

  // ==================== DASHBOARD LOAD ====================

  Future<void> getDashboardData(
    String type,
    List<String> languages,
    int userId,
  ) async {
    if (_isLoadingDashboard) return;

    _isLoadingDashboard = true;
    List<DashboardData> finalDashboardData = [];

    debugPrint("Languages: $languages");

    for (final lang in languages) {
      debugPrint("➡ Loading dashboard for: $lang");

      try {
        final latest = await getDashboardLatestData(type, [lang], userId);
        final trending = await getDashboardTrendingData(type, [lang], userId);
        final upcoming = await getDashboardUpcomingData(type, [lang], userId);

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

    _dashboardData = finalDashboardData;
    notifyListeners();

    _isLoadingDashboard = false;
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

  getContinueWatchedMovieList(String type) async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    String apiUrl = ApiConstant.continueWatchedMoviesByUser(user!.id, type);
    ApiHelper apiHelper = ApiHelper();
    debugPrint(apiUrl);
    try {
      var response = await apiHelper.getApi1(apiUrl);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        ContinueWatchedResponse continueWatchedResponse =
            ContinueWatchedResponse.fromJson(responseBody);

        if (continueWatchedResponse.isSuccess == true &&
            continueWatchedResponse.data != null) {
          _continueWatchedMovies = continueWatchedResponse.data!;
          debugPrint(_continueWatchedMovies.length.toString());
          notifyListeners();
        }
      } else {
        _continueWatchedMovies.clear();
      }
    } catch (error) {
      debugPrint("❌ continue watching error: $error");
    }
  }

  void clear() {
    _dashboardData.clear();
    _continueWatchedMovies.clear();
    _castList.clear();
    notifyListeners();
  }
}
