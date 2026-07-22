import 'dart:convert';
import 'dart:developer' as developer;

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

  WebLandingProvider() {
    _logPerformance('WebLandingProvider created');
  }

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
    if (_disposed) {
      _logPerformance('loadLandingContent skipped: provider disposed');
      return;
    }
    if (_isLoading || _topTen.isNotEmpty) return;
    final existingLandingLoad = _landingLoadFuture;
    if (existingLandingLoad != null) {
      await existingLandingLoad;
      return;
    }

    if (_restoreFreshCache()) {
      _logPerformance('Landing restored from cache');
      _notifyIfAlive();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    final loadWatch = Stopwatch()..start();
    _landingLoadFuture = _loadLandingContentInternal(loadWatch);
    try {
      await _landingLoadFuture;
    } finally {
      if (!_disposed) _landingLoadFuture = null;
    }
  }

  Future<void> _loadLandingContentInternal(Stopwatch loadWatch) async {
    try {
      final topTenFuture = _fetchTopTenContent();
      final landingLatestType = _latestType;
      final latestFuture = _fetchLatestContentPage(
        0,
        type: landingLatestType,
      ).then<_LatestContentPageResult?>(
        (result) => result,
        onError: (error) {
          debugPrint('Web landing latest load error: $error');
          return null;
        },
      );

      final topTen = await topTenFuture;
      if (_disposed) {
        _logPerformance('Landing top-ten completed after dispose; ignoring');
        return;
      }
      _topTen = topTen;
      _logPerformance(
        'Hero section data ready in ${loadWatch.elapsedMilliseconds}ms',
      );

      final latestResult = await latestFuture;
      if (_disposed) {
        _logPerformance('Landing latest completed after dispose; ignoring');
        return;
      }
      if (latestResult != null && _latestType == landingLatestType) {
        _latestContent = latestResult.items;
        _latestPage = 1;
        _hasMoreLatest = latestResult.hasMore;
      } else if (_latestType == landingLatestType) {
        _hasMoreLatest = false;
      }

      if (_latestType == null) _storeCache();
    } catch (error) {
      _errorMessage = 'Unable to load featured content right now.';
      debugPrint('Web landing load error: $error');
    } finally {
      if (_disposed) {
        _logPerformance('Landing load finalization skipped after dispose');
        return;
      }
      _isLoading = false;
      _logPerformance(
        'Landing page load completed in ${loadWatch.elapsedMilliseconds}ms',
      );
      _notifyIfAlive();
    }
  }

  Future<void> loadMoreLatestContent({bool notify = true}) async {
    if (_disposed) {
      _logPerformance('loadMoreLatestContent skipped: provider disposed');
      return;
    }
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
      if (_disposed) {
        _logPerformance('Latest page completed after dispose; ignoring');
        return;
      }
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
      debugPrint('Web landing latest load error: $error');
    } finally {
      if (_disposed ||
          requestToken != _latestRequestToken ||
          requestType != _latestType) {
        _logPerformance('Latest load finalization skipped');
        return;
      }
      _isLoadingLatest = false;
      if (notify) _notifyIfAlive();
    }
  }

  Future<void> loadLatestContentByType(String? type) async {
    if (_disposed) {
      _logPerformance('loadLatestContentByType skipped: provider disposed');
      return;
    }

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
      debugPrint('Web landing filtered latest load error: $error');
    } finally {
      if (_disposed || requestToken != _latestRequestToken) return;
      _isLoadingLatest = false;
      _notifyIfAlive();
    }
  }

  Future<Content> loadContentWithTrailer(Content content) async {
    final existingTrailer = content.teaserOrTrailerUrl?.trim() ?? '';
    if (existingTrailer.isNotEmpty || content.id == null) {
      return content;
    }

    try {
      final watch = Stopwatch()..start();
      final response = await _apiHelper.getApi(ApiConstant.getVideoById(
        content.id,
        1,
      ));
      if (_disposed) {
        _logPerformance('Trailer detail completed after dispose; ignoring');
        return content;
      }
      _logPerformance(
        'Trailer detail API completed in ${watch.elapsedMilliseconds}ms',
      );
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
      debugPrint('Web landing trailer detail load error: $error');
      return content;
    }
  }

  Future<List<Content>> _fetchTopTenContent() async {
    final watch = Stopwatch()..start();
    final response = await _apiHelper.getApi(ApiConstant.publicTopTenContent);
    _logPerformance(
      'Banner/top-ten API completed in ${watch.elapsedMilliseconds}ms',
    );
    if (response.statusCode != 200) {
      throw Exception('Landing API failed with ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = decoded['data']?['TopTenContent'] as List? ?? const [];
    return rawList
        .whereType<Map>()
        .map((item) => _contentFromTopTenItem(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => _posterFor(item) != null)
        .toList();
  }

  Future<_LatestContentPageResult> _fetchLatestContentPage(
    int page, {
    String? type,
  }) async {
    final watch = Stopwatch()..start();
    final response = await _apiHelper.getApi(
      ApiConstant.publicLatestContent(
        page: page,
        size: _latestPageSize,
        type: type,
      ),
    );
    _logPerformance(
      'Latest content API page=$page type=${type ?? 'all'} completed in ${watch.elapsedMilliseconds}ms',
    );
    if (response.statusCode != 200) {
      throw Exception('Latest API failed with ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = _extractContentList(
      decoded,
      const [
        'LatestContent',
        'latestContent',
        'content',
        'contentList',
        'contents',
        'items',
      ],
    );

    final items = rawList
        .whereType<Map>()
        .map((item) => _contentFromTopTenItem(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => _posterFor(item) != null)
        .toList();
    return _LatestContentPageResult(
      items: items,
      hasMore: _hasNextPage(decoded) ?? rawList.length >= _latestPageSize,
    );
  }

  List<dynamic> _extractContentList(
    Map<String, dynamic> decoded,
    List<String> preferredKeys,
  ) {
    final data = decoded['data'];
    if (data is Map) {
      for (final key in preferredKeys) {
        final value = data[key];
        if (value is List) return value;
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List) return value;
        if (value is Map) {
          final nestedContent = value['content'];
          if (nestedContent is List) return nestedContent;
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

  List<String> _posterUrlsFromJson(Map<String, dynamic> json) {
    final posters = <String>[];
    final posterList = json['posterUrlList'];
    if (posterList is List) {
      posters.addAll(
        posterList.map((item) => item.toString().trim()).where(
              (url) => url.isNotEmpty,
            ),
      );
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
    ]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && !posters.contains(value)) {
        posters.add(value);
      }
    }

    return posters;
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

  String? _firstStringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
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

  void _notifyIfAlive() {
    if (_disposed) {
      _logPerformance('notifyListeners skipped: provider disposed');
      return;
    }
    _logPerformance('notifyListeners called');
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

  void _logPerformance(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'WebLandingPerformance');
  }

  @override
  void dispose() {
    _logPerformance('WebLandingProvider dispose called');
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
