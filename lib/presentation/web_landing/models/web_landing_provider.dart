import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/presentation/web_landing/models/web_landing_section.dart';

class WebLandingProvider extends ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper();

  bool _isLoading = false;
  String? _errorMessage;
  List<Content> _topTen = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Content> get topTen => List.unmodifiable(_topTen);

  Content? get featuredContent => _topTen.isEmpty ? null : _topTen.first;

  List<WebLandingSection> get sections {
    final movies = _topTen
        .where((item) => (item.type ?? '').toUpperCase() == 'MOVIE')
        .toList();
    final series = _topTen
        .where((item) => (item.type ?? '').toUpperCase() == 'SERIES')
        .toList();
    final recentlyAdded = List<Content>.from(_topTen)
      ..sort((a, b) => '${b.releaseDate}'.compareTo('${a.releaseDate}'));

    return [
      WebLandingSection(
        title: 'Trending Now',
        items: _topTen,
        numbered: true,
      ),
      WebLandingSection(
        title: 'Top 10 in India',
        items: _topTen.take(10).toList(),
        numbered: true,
      ),
      WebLandingSection(
        title: 'Popular Movies',
        items: movies.isEmpty ? _topTen : movies,
      ),
      WebLandingSection(
        title: 'Popular Series',
        items: series.isEmpty ? _topTen : series,
      ),
      WebLandingSection(
        title: 'Recently Added',
        items: recentlyAdded,
      ),
    ];
  }

  List<String> get genres {
    final values = <String>{};
    for (final item in _topTen) {
      values.addAll(item.genreList ?? const []);
    }
    return values.take(12).toList();
  }

  Future<void> loadLandingContent() async {
    if (_isLoading || _topTen.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiHelper.getApi(ApiConstant.publicTopTenContent);
      if (response.statusCode != 200) {
        throw Exception('Landing API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = decoded['data']?['TopTenContent'] as List? ?? const [];
      _topTen = rawList
          .whereType<Map>()
          .map((item) => _contentFromTopTenItem(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => _posterFor(item) != null)
          .toList();
    } catch (error) {
      _errorMessage = 'Unable to load featured content right now.';
      debugPrint('Web landing load error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Content> loadContentWithTrailer(Content content) async {
    final existingTrailer = content.teaserOrTrailerUrl?.trim() ?? '';
    if (existingTrailer.isNotEmpty || content.id == null) {
      return content;
    }

    try {
      final response = await _apiHelper.getApi(ApiConstant.getVideoById(
        content.id,
        1,
      ));
      if (response.statusCode != 200) return content;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = GetContentResponse.fromJson(decoded).data?.contentList;
      if (detail == null) return content;

      final index = _topTen.indexWhere((item) => item.id == content.id);
      if (index != -1) {
        _topTen[index] = detail;
        notifyListeners();
      }
      return detail;
    } catch (error) {
      debugPrint('Web landing trailer detail load error: $error');
      return content;
    }
  }

  Content _contentFromTopTenItem(Map<String, dynamic> json) {
    final content = Content.fromJson(json);
    final topTenTrailerUrl = _topTenTrailerUrl(json);
    if ((content.trailerUrl?.trim().isEmpty ?? true) &&
        topTenTrailerUrl != null) {
      content.trailerUrl = topTenTrailerUrl;
    }
    return content;
  }

  String? _topTenTrailerUrl(Map<String, dynamic> json) {
    for (final key in const [
      'trailerUrl',
      'trailerFileUrl',
      'trailer_file_url',
      'trailer_url',
    ]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final trailerAudioUrlList = json['trailerAudioUrlList'];
    if (trailerAudioUrlList is List) {
      for (final item in trailerAudioUrlList) {
        final value = item?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }

    return null;
  }

  String? _posterFor(Content content) {
    for (final url in content.posterUrlList ?? const <String>[]) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
