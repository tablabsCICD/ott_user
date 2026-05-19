import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/shorts%20page/component/ShortsPlayerPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/route/navigation_service.dart';
import 'package:ott/app/route/routes/app_routes.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

class MovieDetailsRouteArgs {
  const MovieDetailsRouteArgs({
    required this.movieId,
    this.source = 'internal',
  });

  final int movieId;
  final String source;
}

enum DeepLinkContentType {
  movie,
  series,
  short,
  gift,
}

class DeepLinkTarget {
  const DeepLinkTarget({
    required this.type,
    this.id,
    this.couponCode,
  });

  final DeepLinkContentType type;
  final int? id;
  final String? couponCode;

  String get typeName => type.name;
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  static const String scheme = 'myapp';
  static const String movieHost = 'movie';
  static const String seriesHost = 'series';
  static const String shortHost = 'short';
  static const String giftHost = 'gift';
  static const String httpsHost = 'filmytell.in';
  static const String httpsWwwHost = 'www.filmytell.in';
  static const String ottPathPrefix = 'ott';
  static const String androidPackageName = 'com.filmytell.ott';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageName';

  StreamSubscription<Uri?>? _linkSubscription;
  DeepLinkTarget? _pendingTarget;
  bool _isInitialized = false;

  bool get hasPendingNavigation => _pendingTarget != null;

  bool get supportsUniversalLinks => true;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      final initialUri = await getInitialUri();
      await _handleIncomingUri(initialUri, source: 'initial_uri');
    } on FormatException catch (error, stackTrace) {
      _log('Invalid initial deep link received', error, stackTrace);
    } catch (error, stackTrace) {
      _log('Unable to read initial deep link', error, stackTrace);
    }

    _linkSubscription = uriLinkStream.listen(
      (uri) {
        unawaited(_handleIncomingUri(uri, source: 'uri_stream'));
      },
      onError: (Object error, StackTrace stackTrace) {
        _log('Deep link stream failed', error, stackTrace);
      },
    );

    _isInitialized = true;
  }

  Uri buildMovieDeepLink(int movieId) {
    return Uri(
      scheme: scheme,
      host: movieHost,
      pathSegments: <String>['$movieId'],
    );
  }

  Uri buildGiftDeepLink(String couponCode) {
    return Uri(
      scheme: scheme,
      host: giftHost,
      pathSegments: <String>[couponCode.trim().toUpperCase()],
    );
  }

  Uri buildDeepLink({
    required DeepLinkContentType type,
    required int id,
  }) {
    return Uri(
      scheme: scheme,
      host: type.name,
      pathSegments: <String>['$id'],
    );
  }

  Uri buildMovieAppLink(int movieId) {
    return Uri.https(httpsHost, 'movie/$movieId');
  }

  Uri buildGiftAppLink(String couponCode) {
    return Uri.https(
      httpsHost,
      '$giftHost/${couponCode.trim().toUpperCase()}',
    );
  }

  Uri buildAppLink({
    required DeepLinkContentType type,
    required int id,
  }) {
    return Uri.https(httpsHost, '${type.name}/$id');
  }

  Uri buildPreferredQrLink({
    required DeepLinkContentType type,
    required int id,
  }) {
    return buildAppLink(type: type, id: id);
  }

  DeepLinkTarget? parseTarget(Uri uri) {
    if (uri.scheme == scheme) {
      final type = _typeFromString(uri.host);
      final firstSegment =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

      if (type == DeepLinkContentType.gift) {
        final couponCode = _parseCouponCode(firstSegment);
        if (couponCode != null) {
          return DeepLinkTarget(
            type: DeepLinkContentType.gift,
            couponCode: couponCode,
          );
        }
      } else {
        final id = _parsePositiveInt(firstSegment);
        if (type != null && id != null) {
          return DeepLinkTarget(type: type, id: id);
        }
      }
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        _isSupportedHttpHost(uri.host)) {
      final pathSegments = uri.pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .toList(growable: false);
      final normalizedPathSegments = pathSegments.isNotEmpty &&
              pathSegments.first.toLowerCase() == ottPathPrefix
          ? pathSegments.sublist(1)
          : pathSegments;
      final pathType = normalizedPathSegments.isNotEmpty
          ? _typeFromString(normalizedPathSegments.first)
          : null;

      if (pathType == DeepLinkContentType.gift) {
        final couponCode = normalizedPathSegments.length >= 2
            ? _parseCouponCode(normalizedPathSegments[1])
            : _parseCouponCode(
                uri.queryParameters['couponCode'] ??
                    uri.queryParameters['code'],
              );
        if (couponCode != null) {
          return DeepLinkTarget(
            type: DeepLinkContentType.gift,
            couponCode: couponCode,
          );
        }
      } else {
        final pathId = normalizedPathSegments.length >= 2
            ? _parsePositiveInt(normalizedPathSegments[1])
            : null;
        if (pathType != null && pathId != null) {
          return DeepLinkTarget(type: pathType, id: pathId);
        }
      }

      final queryType = _typeFromString(uri.queryParameters['type']);
      final queryId = _parsePositiveInt(uri.queryParameters['id']);

      if (queryType == DeepLinkContentType.gift) {
        final couponCode = _parseCouponCode(
          uri.queryParameters['couponCode'] ?? uri.queryParameters['code'],
        );
        if (couponCode != null) {
          return DeepLinkTarget(
            type: DeepLinkContentType.gift,
            couponCode: couponCode,
          );
        }
      } else if (queryType != null && queryId != null) {
        return DeepLinkTarget(type: queryType, id: queryId);
      }
    }

    return null;
  }

  bool _isSupportedHttpHost(String rawHost) {
    final host = rawHost.trim().toLowerCase();
    return host == httpsHost || host == httpsWwwHost;
  }

  void consumePendingNavigation() {
    final target = _pendingTarget;
    if (target == null) {
      return;
    }

    _pendingTarget = null;
    unawaited(_navigateToTarget(target, source: 'pending_navigation'));
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }

  Future<void> _handleIncomingUri(Uri? uri, {required String source}) async {
    if (uri == null) {
      return;
    }

    final target = parseTarget(uri);
    developer.log(
      'Incoming URI: $uri',
      name: 'DeepLinkService',
    );
    developer.log(
      'Extracted type: ${target?.typeName ?? 'unknown'}',
      name: 'DeepLinkService',
    );
    developer.log(
      'Extracted id: ${target?.id ?? 'invalid'}',
      name: 'DeepLinkService',
    );
    developer.log(
      'Extracted coupon: ${target?.couponCode ?? 'none'}',
      name: 'DeepLinkService',
    );

    if (target == null) {
      developer.log(
        'Ignoring unsupported deep link: $uri',
        name: 'DeepLinkService',
        level: 900,
      );
      return;
    }

    if (source == 'initial_uri') {
      _pendingTarget = target;
      developer.log(
        'Queued ${target.typeName} deep link from initial launch',
        name: 'DeepLinkService',
      );
      return;
    }

    await _navigateToTarget(target, source: source);
  }

  Future<void> _navigateToTarget(
    DeepLinkTarget target, {
    required String source,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingTarget = target;
      developer.log(
        'Navigator unavailable. Queued ${target.typeName} deep link',
        name: 'DeepLinkService',
      );
      return;
    }

    developer.log(
      'Navigating to ${target.typeName} with id=${target.id} from $source',
      name: 'DeepLinkService',
    );

    switch (target.type) {
      case DeepLinkContentType.movie:
        await _openMovieDetails(navigator, target.id!, source: source);
        return;
      case DeepLinkContentType.series:
        await _openSeriesDetails(navigator, target.id!);
        return;
      case DeepLinkContentType.short:
        await _openShortDetails(navigator, target.id!);
        return;
      case DeepLinkContentType.gift:
        await _openGiftClaimDialog(navigator, target.couponCode!);
        return;
    }
  }

  Future<void> _openGiftClaimDialog(
    NavigatorState navigator,
    String couponCode,
  ) async {
    await showGiftClaimDialog(
      navigator.context,
      initialCouponCode: couponCode,
    );
  }

  Future<void> _openMovieDetails(
    NavigatorState navigator,
    int movieId, {
    required String source,
  }) async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(navigator.context, listen: false);
    await dashboardProvider.getContentById(movieId);
    final content = dashboardProvider.content;

    if (content.id == null || content.id! <= 0) {
      developer.log(
        'Movie content could not be loaded for id=$movieId',
        name: 'DeepLinkService',
        level: 900,
      );
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AppRoutes.movieDetails,
          arguments: MovieDetailsRouteArgs(
            movieId: movieId,
            source: source,
          ),
        ),
        builder: (_) => MovieDetailsPage(movieId: movieId),
      ),
    );
  }

  Future<void> _openSeriesDetails(
    NavigatorState navigator,
    int seriesId,
  ) async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(navigator.context, listen: false);
    await dashboardProvider.getContentById(seriesId);
    final content = dashboardProvider.content;

    if (content.id == null || content.id! <= 0) {
      developer.log(
        'Series content could not be loaded for id=$seriesId',
        name: 'DeepLinkService',
        level: 900,
      );
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AppRoutes.seriesDetails,
          arguments: <String, dynamic>{'id': seriesId},
        ),
        builder: (_) => SeriesDetailsPage(
          seriesId: seriesId,
          content: content,
        ),
      ),
    );
  }

  Future<void> _openShortDetails(
    NavigatorState navigator,
    int shortId,
  ) async {
    final shortProvider =
        Provider.of<ShortProvider>(navigator.context, listen: false);
    await shortProvider.fetchShortDetail(shortId, 1);
    final ShortDetailModel? detail = shortProvider.shortDetail;

    if (detail == null || detail.id <= 0) {
      developer.log(
        'Short content could not be loaded for id=$shortId',
        name: 'DeepLinkService',
        level: 900,
      );
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AppRoutes.shortDetails,
          arguments: <String, dynamic>{'id': shortId},
        ),
        builder: (_) => ShortsPlayerPage(short: detail),
      ),
    );
  }

  DeepLinkContentType? _typeFromString(String? rawType) {
    switch ((rawType ?? '').trim().toLowerCase()) {
      case movieHost:
        return DeepLinkContentType.movie;
      case seriesHost:
        return DeepLinkContentType.series;
      case shortHost:
        return DeepLinkContentType.short;
      case giftHost:
        return DeepLinkContentType.gift;
      default:
        return null;
    }
  }

  int? _parsePositiveInt(String? rawValue) {
    final value = int.tryParse((rawValue ?? '').trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String? _parseCouponCode(String? rawValue) {
    final value = (rawValue ?? '').trim().replaceAll(' ', '').toUpperCase();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'DeepLinkService',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
