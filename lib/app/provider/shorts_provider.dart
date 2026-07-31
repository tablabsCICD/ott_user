import 'dart:convert';
import 'dart:developer';
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

      for (final lang in effectiveLanguages) {
        final latest = await getLatestMiniSeries(language: lang);
        final trending = await getTrendingMiniSeries(language: lang);

        sections.add(
          ShortsSectionData(
            language: lang,
            category: "Latest Mini Series",
            shorts: latest.content,
          ),
        );
        sections.add(
          ShortsSectionData(
            language: lang,
            category: "Trending Mini Series",
            shorts: trending.content,
          ),
        );
      }

      _shortSections = sections;
      shorts = sections.expand((row) => row.shorts).toList();
    } catch (e) {
      _shortSections = [];
      shorts = [];
      errorMessage = 'Unable to load Mini Series. Please try again.';
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
    final response = await ApiHelper().getApi(url.toString());

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
    return MiniSeriesPage.fromJson(data);
  }

  Future<void> fetchShortDetail(int id, int userId) async {
    try {
      isLoading = true;
      errorMessage = null;
      shortDetail = null;
      notifyListeners();

      final url = Uri.parse(ApiConstant.shortsDetails(id, userId));
      final response = await ApiHelper().getApi(url.toString());
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
      shortDetail = ShortDetailModel.fromJson(
        decoded['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      print("Short Detail Error → $e");
      errorMessage = 'Unable to load Mini Series details. Please try again.';
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
      return null;
    }
  }
}
