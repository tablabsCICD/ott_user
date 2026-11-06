// Regression tests for the Series Details trailer lifecycle around the
// episode player:
//  * The episode player forces landscape. On most iPhones that crosses the
//    mobile width breakpoint, which used to rebuild the covered Series page
//    into the TV layout and back, recreating the trailer (it then autoplayed
//    in the background) and resetting the scroll position.
//  * A replaced TrailerPreview used to clear the shared controller callbacks
//    of its replacement on dispose, so stop-on-scroll / stop-on-episode
//    silently stopped working until the page was refreshed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/playMediaProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/route/route_observer.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockSeriesProvider extends SeriesProvider {
  final SeriesEntity? _series;

  _MockSeriesProvider(this._series);

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  SeriesEntity? get series => _series;

  @override
  Future<void> fetchSeriesDetails(int seriesId) async {}
}

class _MockVideoProvider extends VideoProvider {
  @override
  Future<Map<String, Object>> getRatingReview(int movieId) async =>
      <String, Object>{'success': true, 'data': []};
}

final _navigatorKey = GlobalKey<NavigatorState>();

/// Marker for the Series page's mobile (phone) layout.
const _mobileHero = ValueKey('seriesDetailHero');

SeriesEntity _series() => SeriesEntity(
      id: 301,
      title: 'Route Lifecycle Series',
      description: 'desc',
      posterUrl: 'https://example.com/poster.jpg',
      seasons: [
        SeasonEntity(
          seasonId: 1,
          title: 'Season 1',
          seasonNumber: 1,
          description: 'Season 1',
          releaseDate: 0,
          price: 0,
          isSeasonPurchased: true,
          episodes: [
            EpisodeEntity(
              episodeId: 11,
              title: 'Episode 1',
              description: 'Episode 1',
              episodeNumber: 1,
              runtime: 40,
              releaseDate: 0,
              posterUrl: 'https://example.com/ep1.jpg',
              videoUrl: 'https://example.com/ep1.mp4',
              isPurchased: true,
              isFree: false,
              isLocked: false,
              price: 0,
            ),
          ],
        ),
      ],
    );

Widget _app(SeriesEntity series) {
  final content = Content(
    id: series.id,
    title: series.title,
    type: 'series',
    teaserUrl: 'https://example.com/trailer.mp4',
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SeriesProvider>.value(
        value: _MockSeriesProvider(series),
      ),
      ChangeNotifierProvider<VideoProvider>(
          create: (_) => _MockVideoProvider()),
      ChangeNotifierProvider<PlayMediaProvider>(
        create: (_) => PlayMediaProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<OfflineDownloadProvider>(
        create: (_) => OfflineDownloadProvider(),
      ),
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => DashboardProvider(),
      ),
    ],
    child: MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [routeObserver],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SeriesDetailsPage(seriesId: series.id, content: content),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

State _trailerState(WidgetTester tester) =>
    tester.state(find.byType(TrailerPreview, skipOffstage: false).first);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrailerPreviewController ownership', () {
    testWidgets(
        'disposing a replaced preview keeps the replacement callbacks bound',
        (tester) async {
      final controller = TrailerPreviewController();
      final content = Content(id: 1, title: 'T', type: 'series');

      Widget host({required bool first}) => MaterialApp(
            home: Scaffold(
              body: first
                  ? SizedBox(
                      key: const ValueKey('a'),
                      child: TrailerPreview(
                        trailerUrl: null,
                        content: content,
                        controller: controller,
                      ),
                    )
                  : Center(
                      key: const ValueKey('b'),
                      child: TrailerPreview(
                        trailerUrl: null,
                        content: content,
                        controller: controller,
                      ),
                    ),
            ),
          );

      await tester.pumpWidget(host(first: true));
      expect(controller.pause, isNotNull);

      // Same frame: new preview binds in initState, old one disposes after.
      await tester.pumpWidget(host(first: false));
      expect(controller.pause, isNotNull);
      expect(controller.play, isNotNull);
      expect(controller.isPlaying, isNotNull);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(controller.pause, isNull);
      expect(controller.play, isNull);
    });
  });

  group('Series Details layout while covered by the episode player', () {
    testWidgets(
        'landscape player on top does not rebuild the covered page into the '
        'TV layout or recreate the trailer', (tester) async {
      _setSize(tester, const Size(400, 800));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_series()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(_mobileHero), findsOneWidget);
      final before = _trailerState(tester);

      // Open a full-screen route (stands in for the episode player).
      _navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Player rotates the device to landscape (width above breakpoint).
      _setSize(tester, const Size(900, 420));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(_mobileHero, skipOffstage: false), findsOneWidget,
          reason: 'covered page must keep its mobile layout');
      expect(identical(_trailerState(tester), before), isTrue,
          reason: 'trailer must not be recreated while covered');

      // Player restores portrait, then pops.
      _setSize(tester, const Size(400, 800));
      await tester.pump();
      _navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(_mobileHero), findsOneWidget);
      expect(identical(_trailerState(tester), before), isTrue,
          reason: 'returning must reuse the same trailer instance');

      // Flush delayed autoplay / layout-hold timers.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'layout stays frozen during the pop until the orientation is restored',
        (tester) async {
      _setSize(tester, const Size(400, 800));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_series()));
      await tester.pump(const Duration(milliseconds: 300));
      final before = _trailerState(tester);

      _navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      _setSize(tester, const Size(900, 420));
      await tester.pump();

      // Pop while metrics are still landscape (rotation lands a bit later).
      _navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(_mobileHero, skipOffstage: false), findsOneWidget);

      _setSize(tester, const Size(400, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(_mobileHero), findsOneWidget);
      expect(identical(_trailerState(tester), before), isTrue);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('page that is not covered still follows a real size change',
        (tester) async {
      _setSize(tester, const Size(400, 800));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_series()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_mobileHero), findsOneWidget);

      _setSize(tester, const Size(1200, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_mobileHero), findsNothing,
          reason: 'visible page switches to the wide layout as before');

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
