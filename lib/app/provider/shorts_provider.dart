import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/data/models/user.dart';
import 'baseProvider.dart';

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

  Future<void> fetchShorts() async {
    await fetchShortsByLanguages(const ["English"]);
  }

  Future<void> fetchShortsByLanguages(List<String> languages) async {
    final effectiveLanguages = languages
        .where((lang) => lang.trim().isNotEmpty)
        .map((lang) => lang.trim())
        .toList();

    if (effectiveLanguages.isEmpty) {
      effectiveLanguages.add("English");
    }

    try {
      isLoading = true;
      notifyListeners();

      final sections = <ShortsSectionData>[];

      for (final lang in effectiveLanguages) {
        final trending = await _fetchShortsByType(
          type: "trending",
          lang: lang,
          page: 0,
        );
        final latest = await _fetchShortsByType(
          type: "latest",
          lang: lang,
          page: 0,
        );

        sections.add(
          ShortsSectionData(
            language: lang,
            category: "Trending Shorts",
            shorts: trending,
          ),
        );
        sections.add(
          ShortsSectionData(
            language: lang,
            category: "Latest Shorts",
            shorts: latest,
          ),
        );
      }

      _shortSections = sections;
      shorts = sections.expand((row) => row.shorts).toList();
    } catch (e) {
      print("Shorts Fetch Error → $e");
      _shortSections = [];
      shorts = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<List<ShortModel>> _fetchShortsByType({
    required String type,
    required String lang,
    int page = 0,
  }) async {
    final apiUrl = type.toLowerCase() == 'trending'
        ? ApiConstant.getTrendingShortsByLang(lang, page)
        : ApiConstant.getLatestShortsByLang(lang, page);
    final url = Uri.parse(apiUrl);
    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final content = (data["data"]?["content"] as List?) ?? [];

    return content.map((e) => ShortModel.fromJson(e)).toList();
  }

  Future<void> fetchShortDetail(int id, int userId) async {
    try {
      isLoading = true;
      notifyListeners();

      var url = Uri.parse(ApiConstant.shortsDetails(id, userId));
      var response = await http.get(url);
      final data = jsonDecode(response.body);

      shortDetail = ShortDetailModel.fromJson(data["data"]);
    } catch (e) {
      print("Short Detail Error → $e");
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
    final User? user =
        await LocalSharePreferences.localSharePreferences.getUser();

    if (user == null) return false;

    try {
      _isLiking = true;
      notifyListeners();

      final url = Uri.parse(
        isLike
            ? ApiConstant.likeshort(partId, user.id)
            : ApiConstant.unlikeshort(partId, user.id),
      );
      //log('liked/unliked URL======== $url');

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body["success"] == true;
      }

      return false;
    } catch (e) {
      debugPrint("Short like toggle error: $e");
      return false;
    } finally {
      _isLiking = false;
      notifyListeners();
    }
  }

  // views count for shorts
  Future<bool> addShortView({required int partId}) async {
    try {
      final url = Uri.parse(ApiConstant.viewsShort(partId));

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body["success"] == true;
      }
      return false;
    } catch (e) {
      debugPrint("View API error: $e");
      return false;
    }
  }

  //purchase short

  Future<Map<String, dynamic>?> purchaseShortPart({
    required int partId,
  }) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user == null) return null;
    final url = ApiConstant.purchaseShort(partId, user.id!);
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
      debugPrint("Purchase short error: $e");
      return null;
    }
  }
}
