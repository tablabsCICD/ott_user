import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/presentation/web_landing/models/web_landing_section.dart';

class WebLandingProvider extends ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper();

  bool _disposed = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Content> _topTen = [];
  List<Content> _latestContent = [];
  int _latestPage = 0;
  bool _isLoadingLatest = false;
  bool _hasMoreLatest = true;
  String? _latestType;
  int _latestRequestToken = 0;
  Future<void>? _landingLoadFuture;
  Future<void>? _latestLoadFuture;

  static const int _latestPageSize = 10;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static DateTime? _cacheLoadedAt;
  static List<Content>? _cachedTopTen;
  static List<Content>? _cachedLatestContent;
  static int _cachedLatestPage = 0;
  static bool _cachedHasMoreLatest = true;

  WebLandingProvider();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Content> get topTen => List.unmodifiable(_topTen);
  List<Content> get latestContent => List.unmodifiable(_latestContent);
  bool get isLoadingLatest => _isLoadingLatest;
  bool get hasMoreLatest => _hasMoreLatest;
  String? get latestType => _latestType;

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
    if (_disposed) return;
    if (_isLoading || _topTen.isNotEmpty) return;
    final existingLandingLoad = _landingLoadFuture;
    if (existingLandingLoad != null) {
      await existingLandingLoad;
      return;
    }

    if (_restoreFreshCache()) {
      _notifyIfAlive();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    _landingLoadFuture = _loadLandingContentInternal();
    try {
      await _landingLoadFuture;
    } finally {
      if (!_disposed) _landingLoadFuture = null;
    }
  }

  Future<void> _loadLandingContentInternal() async {
    try {
      final landingLatestType = _latestType;

      final results = await Future.wait([
        _fetchTopTenContent().catchError((_) => <Content>[]),
        _fetchLatestContentPage(
          0,
          type: landingLatestType,
        ).catchError(
          (_) => const _LatestContentPageResult(items: [], hasMore: false),
        ),
      ]);

      if (_disposed) return;

      var topTen = results[0] as List<Content>;
      final latestResult = results[1] as _LatestContentPageResult;

      if (latestResult.items.isNotEmpty && _latestType == landingLatestType) {
        _latestContent = latestResult.items;
        _latestPage = 1;
        _hasMoreLatest = latestResult.hasMore;
      } else if (_latestType == landingLatestType) {
        _hasMoreLatest = false;
      }

      // Mutual fallback if one source is empty
      if (topTen.isEmpty && _latestContent.isNotEmpty) {
        topTen = List<Content>.from(_latestContent);
      } else if (_latestContent.isEmpty &&
          topTen.isNotEmpty &&
          _latestType == null) {
        _latestContent = List<Content>.from(topTen);
        _latestPage = 1;
        _hasMoreLatest = false;
      }

      _topTen = topTen;

      if (_topTen.isEmpty && _latestContent.isEmpty) {
        _errorMessage = 'Unable to load featured content right now.';
      } else {
        _errorMessage = null;
      }

      if (_latestType == null &&
          (_topTen.isNotEmpty || _latestContent.isNotEmpty)) {
        _storeCache();
      }
    } catch (error) {
      if (_topTen.isEmpty && _latestContent.isEmpty) {
        _errorMessage = 'Unable to load featured content right now.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> loadMoreLatestContent({bool notify = true}) async {
    if (_disposed) return;
    if (_isLoadingLatest || !_hasMoreLatest) return;
    final existingLatestLoad = _latestLoadFuture;
    if (existingLatestLoad != null) {
      await existingLatestLoad;
      return;
    }

    _isLoadingLatest = true;
    if (notify) _notifyIfAlive();

    _latestLoadFuture = _loadMoreLatestContentInternal(notify: notify);
    try {
      await _latestLoadFuture;
    } finally {
      if (!_disposed) _latestLoadFuture = null;
    }
  }

  Future<void> _loadMoreLatestContentInternal({required bool notify}) async {
    final requestToken = _latestRequestToken;
    final requestType = _latestType;
    try {
      final result = await _fetchLatestContentPage(
        _latestPage,
        type: requestType,
      );
      if (_disposed) return;
      if (requestToken != _latestRequestToken || requestType != _latestType) {
        return;
      }
      final existingIds =
          _latestContent.map((item) => item.id).whereType<int>().toSet();
      final nextItems = result.items
          .where((item) => item.id == null || !existingIds.contains(item.id))
          .toList();

      _latestContent = [..._latestContent, ...nextItems];
      _latestPage += 1;
      _hasMoreLatest = result.hasMore;
      if (_latestType == null) _storeCache();
    } catch (error) {
      if (requestToken != _latestRequestToken || requestType != _latestType) {
        return;
      }
      _hasMoreLatest = false;
    } finally {
      if (!_disposed &&
          requestToken == _latestRequestToken &&
          requestType == _latestType) {
        _isLoadingLatest = false;
        if (notify) _notifyIfAlive();
      }
    }
  }

  Future<void> loadLatestContentByType(String? type) async {
    if (_disposed) return;

    final nextType = _normalizeLatestType(type);
    final requestToken = ++_latestRequestToken;
    _latestType = nextType;
    _latestPage = 0;
    _latestContent = [];
    _hasMoreLatest = true;
    _isLoadingLatest = true;
    _notifyIfAlive();

    try {
      final result = await _fetchLatestContentPage(0, type: nextType);
      if (_disposed || requestToken != _latestRequestToken) return;

      _latestContent = result.items;
      _latestPage = 1;
      _hasMoreLatest = result.hasMore;
    } catch (error) {
      if (_disposed || requestToken != _latestRequestToken) return;
      _latestContent = [];
      _hasMoreLatest = false;
    } finally {
      if (!_disposed && requestToken == _latestRequestToken) {
        _isLoadingLatest = false;
        _notifyIfAlive();
      }
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
      if (_disposed) return content;
      if (response.statusCode != 200) return content;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = GetContentResponse.fromJson(decoded).data?.contentList;
      if (detail == null) return content;

      final index = _topTen.indexWhere((item) => item.id == content.id);
      if (index != -1) {
        _topTen[index] = detail;
        _notifyIfAlive();
      }
      return detail;
    } catch (error) {
      return content;
    }
  }

  Future<List<Content>> _fetchTopTenContent() async {
    List<Content> items = [];

    // 1. Primary: Public TopTen Content API
    try {
      final response =
          await _apiHelper.getApi(ApiConstant.publicTopTenContent);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          items = _parseContentListFromDecoded(decoded);
        } else if (decoded is List) {
          items = decoded
              .whereType<Map>()
              .map((item) =>
                  _contentFromTopTenItem(Map<String, dynamic>.from(item)))
              .where((item) => _posterFor(item) != null)
              .toList();
        }
      }
    } catch (_) {}

    if (items.isNotEmpty) return items;

    // 2. Secondary fallback: Public Latest Content API
    try {
      final response = await _apiHelper.getApi(
        ApiConstant.publicLatestContent(page: 0, size: 10),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          items = _parseContentListFromDecoded(decoded);
        }
      }
    } catch (_) {}

    if (items.isNotEmpty) return items;

    // 3. Tertiary fallback: User Dashboard trending/latest endpoints
    final fallbackEndpoints = [
      '${ApiConstant.getNewDashboardData}trending?type=MOVIE&lang=Hindi&userId=1&page=0&size=10',
      '${ApiConstant.getNewDashboardData}latest?type=MOVIE&lang=Hindi&userId=1&page=0&size=10',
      ApiConstant.getUpcomingVideo,
      ApiConstant.getTopTrendingContentLast7Days(1),
    ];

    for (final endpoint in fallbackEndpoints) {
      try {
        final response = await _apiHelper.getApi(endpoint);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            items = _parseContentListFromDecoded(decoded);
          } else if (decoded is List) {
            items = decoded
                .whereType<Map>()
                .map((item) =>
                    _contentFromTopTenItem(Map<String, dynamic>.from(item)))
                .where((item) => _posterFor(item) != null)
                .toList();
          }
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return items;
  }

  Future<_LatestContentPageResult> _fetchLatestContentPage(
    int page, {
    String? type,
  }) async {
    // 1. Primary: Public Latest Content API
    try {
      final response = await _apiHelper.getApi(
        ApiConstant.publicLatestContent(
          page: page,
          size: _latestPageSize,
          type: type,
        ),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawList = _extractContentList(
            decoded,
            const [
              'LatestContent',
              'latestContent',
              'TopTenContent',
              'topTenContent',
              'content',
              'contentList',
              'contents',
              'items',
              'movies',
              'data',
            ],
          );

          final items = rawList
              .whereType<Map>()
              .map((item) => _contentFromTopTenItem(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => _posterFor(item) != null)
              .toList();

          if (items.isNotEmpty || page > 0) {
            return _LatestContentPageResult(
              items: items,
              hasMore: _hasNextPage(decoded) ?? rawList.length >= _latestPageSize,
            );
          }
        }
      }
    } catch (_) {}

    // 2. Secondary fallback on initial page
    if (page == 0) {
      final fallbackEndpoint =
          '${ApiConstant.getNewDashboardData}latest?type=${type ?? 'MOVIE'}&lang=Hindi&userId=1&page=0&size=$_latestPageSize';
      try {
        final response = await _apiHelper.getApi(fallbackEndpoint);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final items = _parseContentListFromDecoded(decoded);
            if (items.isNotEmpty) {
              return _LatestContentPageResult(items: items, hasMore: false);
            }
          }
        }
      } catch (_) {}
    }

    return const _LatestContentPageResult(items: [], hasMore: false);
  }

  List<Content> _parseContentListFromDecoded(Map<String, dynamic> decoded) {
    final rawList = _extractContentList(
      decoded,
      const [
        'TopTenContent',
        'topTenContent',
        'TopTen',
        'topTen',
        'LatestContent',
        'latestContent',
        'content',
        'contentList',
        'contents',
        'items',
        'movies',
        'data',
      ],
    );

    final mapped = rawList
        .whereType<Map>()
        .map((item) => _contentFromTopTenItem(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    final withPosters = mapped.where((item) => _posterFor(item) != null).toList();
    return withPosters.isNotEmpty ? withPosters : mapped;
  }

  List<dynamic> _extractContentList(
    Map<String, dynamic> decoded,
    List<String> preferredKeys,
  ) {
    final data = decoded['data'];
    if (data is List) return data;

    if (data is Map) {
      for (final key in preferredKeys) {
        final value = data[key];
        if (value is List) return value;
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List) return value;
        if (value is Map) {
          final nested = value['content'] ??
              value['contentList'] ??
              value['items'] ??
              value['movies'];
          if (nested is List) return nested;
        }
      }
    }

    for (final key in preferredKeys) {
      final value = decoded[key];
      if (value is List) return value;
    }

    return const [];
  }

  bool? _hasNextPage(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    final candidates = <dynamic>[
      if (data is Map) ...[
        data['hasNext'],
        data['hasMore'],
        data['last'] is bool ? !(data['last'] as bool) : null,
        data['isLast'] is bool ? !(data['isLast'] as bool) : null,
      ],
      decoded['hasNext'],
      decoded['hasMore'],
      decoded['last'] is bool ? !(decoded['last'] as bool) : null,
      decoded['isLast'] is bool ? !(decoded['isLast'] as bool) : null,
    ];

    for (final value in candidates) {
      if (value is bool) return value;
    }
    return null;
  }

  String? _normalizeLatestType(String? type) {
    final value = type?.trim().toLowerCase();
    if (value == null || value.isEmpty || value == 'all') return null;
    final normalized = value.replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (normalized == 'movie') return 'MOVIE';
    if (normalized == 'series') return 'SERIES';
    if (normalized == 'short film') return 'SHORT_FILM';
    if (normalized == 'mini series' ||
        normalized == 'shorts' ||
        normalized == 'short') {
      return 'MINI SERIES';
    }
    return value.toUpperCase();
  }

  Content _contentFromTopTenItem(Map<String, dynamic> json) {
    final content = Content.fromJson(json);
    final posterUrls = _posterUrlsFromJson(json);
    if ((content.posterUrlList?.isEmpty ?? true) && posterUrls.isNotEmpty) {
      content.posterUrlList = posterUrls;
    }
    if ((content.type?.trim().isEmpty ?? true)) {
      content.type = _firstStringValue(json, const [
            'contentType',
            'content_type',
            'mediaType',
            'media_type',
            'type',
          ]) ??
          (json.containsKey('totalParts') ? 'MINI SERIES' : null);
    }
    final topTenTrailerUrl = _topTenTrailerUrl(json);
    if ((content.trailerUrl?.trim().isEmpty ?? true) &&
        topTenTrailerUrl != null) {
      content.trailerUrl = topTenTrailerUrl;
    }
    return content;
  }

  String? _firstStringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _topTenTrailerUrl(Map<String, dynamic> json) {
    final direct = _firstStringValue(json, const [
      'trailerUrl',
      'trailer_url',
      'trailer',
      'videoUrl',
      'video_url',
    ]);
    if (direct != null) return _sanitizeUrl(direct);

    for (final subKey in const ['movie', 'series', 'video', 'media', 'details']) {
      final sub = json[subKey];
      if (sub is Map<String, dynamic>) {
        final nested = _topTenTrailerUrl(sub);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  List<String> _posterUrlsFromJson(Map<String, dynamic> json) {
    final posters = <String>[];
    final posterList = json['posterUrlList'] ??
        json['poster_url_list'] ??
        json['posters'] ??
        json['posterList'] ??
        json['images'] ??
        json['thumbnails'];

    if (posterList is List) {
      for (final item in posterList) {
        final s = _sanitizeUrl(_stringFromField(item));
        if (s != null && s.isNotEmpty && !posters.contains(s)) {
          posters.add(s);
        }
      }
    }

    for (final key in const [
      'posterUrl',
      'poster',
      'thumbnail',
      'thumbnailUrl',
      'imageUrl',
      'bannerUrl',
      'coverUrl',
      'poster_url',
      'thumbnail_url',
      'image_url',
      'banner_url',
      'cover_url',
      'landscapePoster',
      'landscape_poster',
      'verticalPoster',
      'vertical_poster',
      'horizontalPoster',
      'horizontal_poster',
      'backdropUrl',
      'backdrop_url',
      'backdrop',
      'mobileBanner',
      'webBanner',
      'posterPath',
      'poster_path',
      'filePath',
      'file_path',
      'mediaUrl',
      'media_url',
      'url',
    ]) {
      final s = _sanitizeUrl(json[key]?.toString());
      if (s != null && s.isNotEmpty && !posters.contains(s)) {
        posters.add(s);
      }
    }

    for (final subKey in const ['movie', 'series', 'video', 'media', 'details']) {
      final sub = json[subKey];
      if (sub is Map<String, dynamic>) {
        final subPosters = _posterUrlsFromJson(sub);
        for (final s in subPosters) {
          if (!posters.contains(s)) {
            posters.add(s);
          }
        }
      }
    }

    return posters;
  }

  String? _sanitizeUrl(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('//')) {
      url = 'https:$url';
    } else if (url.startsWith('http://')) {
      url = 'https://${url.substring(7)}';
    }
    return url;
  }

  String? _stringFromField(dynamic field) {
    if (field == null) return null;
    if (field is Map) {
      for (final key in const ['url', 'fileUrl', 'file_url', 'path']) {
        final value = field[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }
    final value = field.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? _posterFor(Content content) {
    final list = content.posterUrlList ?? const <String>[];
    final sanitizedList = list
        .map((u) => _sanitizeUrl(u))
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    if (sanitizedList.isNotEmpty) {
      sanitizedList.sort((a, b) {
        final aIsS3 = a.contains('amazonaws.com') || a.contains('filmytell.com');
        final bIsS3 = b.contains('amazonaws.com') || b.contains('filmytell.com');
        if (aIsS3 && !bIsS3) return -1;
        if (!aIsS3 && bIsS3) return 1;
        return 0;
      });
      return sanitizedList.first;
    }
    return null;
  }

  void _notifyIfAlive() {
    if (_disposed) return;
    notifyListeners();
  }

  bool _restoreFreshCache() {
    final loadedAt = _cacheLoadedAt;
    final cachedTopTen = _cachedTopTen;
    final cachedLatest = _cachedLatestContent;
    if (loadedAt == null || cachedTopTen == null || cachedLatest == null) {
      return false;
    }
    if (DateTime.now().difference(loadedAt) > _cacheTtl) return false;

    _topTen = List<Content>.from(cachedTopTen);
    _latestContent = List<Content>.from(cachedLatest);
    _latestPage = _cachedLatestPage;
    _hasMoreLatest = _cachedHasMoreLatest;
    _latestType = null;
    _isLoading = false;
    _errorMessage = null;
    return true;
  }

  void _storeCache() {
    _cacheLoadedAt = DateTime.now();
    _cachedTopTen = List<Content>.from(_topTen);
    _cachedLatestContent = List<Content>.from(_latestContent);
    _cachedLatestPage = _latestPage;
    _cachedHasMoreLatest = _hasMoreLatest;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _LatestContentPageResult {
  const _LatestContentPageResult({
    required this.items,
    required this.hasMore,
  });

  final List<Content> items;
  final bool hasMore;
}
