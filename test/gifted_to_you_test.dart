import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/playMediaProvider.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/purchesContentListResponse.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/data/themes/custom_theme.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the gifted-content API: records each fetch and returns a
/// fixed result / list, so the screen's states can be checked without HTTP.
class _FakePurchaseContentProvider extends PurchaseContentProvider {
  _FakePurchaseContentProvider({
    this.items = const [],
    this.result = const {'success': true, 'message': 'ok'},
  });

  List<UserContent> items;
  Map<String, Object> result;
  final List<({bool isGifted, bool isExpired})> calls = [];

  @override
  List<UserContent> get userContentList => items;

  @override
  Future<Map<String, Object>> getPurchaseContent({
    bool isGifted = false,
    bool isExpired = false,
  }) async {
    calls.add((isGifted: isGifted, isExpired: isExpired));
    return result;
  }
}

/// No network: playback falls back to the gifted item's own URL.
class _FakeDashboardProvider extends DashboardProvider {
  @override
  Future<Content?> getContentById(int id) async => null;
}

/// Records every route pushed on the navigator it observes.
class _PushLog extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

const _connectivityMethod =
    MethodChannel('dev.fluttercommunity.plus/connectivity');
const _connectivityEvents =
    EventChannel('dev.fluttercommunity.plus/connectivity_status');

void _mockConnectivity(String status) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    _connectivityMethod,
    (call) async => [status],
  );
  messenger.setMockStreamHandler(
    _connectivityEvents,
    MockStreamHandler.inline(onListen: (_, __) {}),
  );
}

Widget _app(
  Widget home, {
  PurchaseContentProvider? purchase,
  List<NavigatorObserver> observers = const [],
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(isDark: false)),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => WalletProvider()),
      ChangeNotifierProvider(create: (_) => LocaleLanguageProvider()),
      ChangeNotifierProvider<PurchaseContentProvider>(
        create: (_) => purchase ?? _FakePurchaseContentProvider(),
      ),
      ChangeNotifierProvider(create: (_) => OfflineDownloadProvider()),
      ChangeNotifierProvider(create: (_) => PlayMediaProvider()),
      ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ChangeNotifierProvider<DashboardProvider>(
          create: (_) => _FakeDashboardProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: observers,
      home: home,
    ),
  );
}

UserContent _gift(int id, String title, String type) => UserContent(
      id: id,
      isGifted: true,
      active: true,
      movie: Content(
        id: id,
        title: title,
        type: type,
        contentUrl: 'https://example.com/$id.m3u8',
      ),
    );

/// MovieCard schedules zero-length timers (fonts / dial); let them run
/// before the test ends.
Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockConnectivity('wifi');
  });

  group('Profile menu', () {
    testWidgets('Gifted To You sits directly below Claim Gift Card and opens '
        'the Watchlist gifted list', (tester) async {
      String? openedTitle;
      Widget? openedPage;
      await tester.pumpWidget(_app(ProfilePage(
        onOpenDetail: (title, page) {
          openedTitle = title;
          openedPage = page;
        },
      )));
      await tester.pump(const Duration(milliseconds: 600));

      final titles = tester
          .widgetList<ProfileOption>(
              find.byType(ProfileOption, skipOffstage: false))
          .map((o) => o.title)
          .toList();
      final claim = titles.indexOf('Claim Gift Card');
      expect(claim, isNonNegative);
      expect(titles[claim + 1], 'Gifted To You');

      final option = tester.widget<ProfileOption>(find.byWidgetPredicate(
          (w) => w is ProfileOption && w.title == 'Gifted To You',
          skipOffstage: false));
      expect(option.icon, Icons.card_giftcard_rounded);

      option.onTap();
      expect(openedTitle, 'Gifted To You');
      expect(openedPage, isA<WatchlistPage>());
      final page = openedPage! as WatchlistPage;
      expect(page.giftedOnly, isTrue);
      expect(page.initialFilter, WatchlistFilter.gifted);
    });

    testWidgets('is hidden with the rest of gifting in the native iOS app',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(_app(ProfilePage(onOpenDetail: (_, __) {})));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Gifted To You', skipOffstage: false), findsNothing);
        expect(find.text('Claim Gift Card', skipOffstage: false), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('Gifted To You screen', () {
    testWidgets('fetches the existing gifted API once and shows the gifted '
        'cards without the Watchlist filter chips', (tester) async {
      final purchase = _FakePurchaseContentProvider(items: [
        _gift(1, 'Gift Movie', 'MOVIE'),
        _gift(2, 'Gift Series', 'SERIES'),
        _gift(3, 'Gift Mini', 'MINI_SERIES'),
        _gift(4, 'Gift Short', 'SHORT_FILM'),
      ]);
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
          _app(const WatchlistPage.giftedToYou(), purchase: purchase));
      await tester.pump(const Duration(milliseconds: 300));

      expect(purchase.calls, [(isGifted: true, isExpired: false)]);
      expect(find.text('Gifted To You'), findsOneWidget);
      for (final title in [
        'Gift Movie',
        'Gift Series',
        'Gift Mini',
        'Gift Short'
      ]) {
        expect(find.text(title), findsWidgets);
      }
      // Home page MovieCards at the Home card size; gifted content is
      // already accessible, so each shows Watch Now (no price / purchase).
      expect(find.byType(MovieCard), findsNWidgets(4));
      expect(find.text('Watch Now'), findsNWidgets(4));
      expect(find.textContaining('₹'), findsNothing);
      final card = tester.getSize(find.byType(MovieCard).first);
      // Cards widen to fill the grid row (final_ott layout): at least the
      // standard width, 16:9 poster grows with it, details area unchanged.
      expect(card.width, greaterThanOrEqualTo(MovieCard.mobileCardWidth));
      final detailsHeight = MovieCard.standardHeight -
          MovieCard.mobileCardWidth / MovieCard.standardPosterAspectRatio;
      expect(
        card.height,
        closeTo(
            card.width / MovieCard.standardPosterAspectRatio + detailsHeight,
            0.01),
      );
      await _flush(tester);
      // No Watchlist filter chips on this screen.
      expect(find.text('Available'), findsNothing);
      expect(find.text('Expired'), findsNothing);
    });

    testWidgets(
        'inside the Profile nested navigator, a gifted movie opens the player '
        'on the root navigator exactly once (no Home redirect)',
        (tester) async {
      final rootLog = _PushLog();
      final nestedLog = _PushLog();
      final purchase = _FakePurchaseContentProvider(
          items: [_gift(7, 'Gift Movie', 'MOVIE')]);
      await tester.pumpWidget(_app(
        // Same structure as ProfileDetailShell.
        Navigator(
          observers: [nestedLog],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const WatchlistPage.giftedToYou(),
          ),
        ),
        purchase: purchase,
        observers: [rootLog],
      ));
      await tester.pump(const Duration(milliseconds: 300));
      final rootBefore = rootLog.pushed.length;
      final nestedBefore = nestedLog.pushed.length;

      // Double tap: only one player route.
      await tester.tap(find.text('Watch Now'));
      await tester.tap(find.text('Watch Now'), warnIfMissed: false);
      await tester.pump();
      await tester.pump();

      final newRoot = rootLog.pushed.skip(rootBefore).toList();
      expect(newRoot, hasLength(1));
      expect(newRoot.single.settings.name, isNull);
      expect(nestedLog.pushed.length, nestedBefore);
      final page = (newRoot.single as MaterialPageRoute)
          .builder(tester.element(find.byType(WatchlistPage)));
      expect(page.runtimeType.toString(), 'PlayMediaPage');
      expect((page as dynamic).content.id, 7);
      expect((page as dynamic).videoUrl, 'https://example.com/7.m3u8');
      await _flush(tester);
    });

    testWidgets('shows the empty state when there are no gifts',
        (tester) async {
      await tester.pumpWidget(_app(const WatchlistPage.giftedToYou()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Gifts Yet'), findsOneWidget);
      expect(
        find.text('Movies and content gifted to you will appear here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    });

    testWidgets('shows the backend error and retries on tap', (tester) async {
      final purchase = _FakePurchaseContentProvider(
        result: const {'success': false, 'message': 'Server says no'},
      );
      await tester.pumpWidget(
          _app(const WatchlistPage.giftedToYou(), purchase: purchase));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Server says no'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(purchase.calls, hasLength(1));

      purchase
        ..result = const {'success': true, 'message': 'ok'}
        ..items = [_gift(9, 'Late Gift', 'MOVIE')];
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(purchase.calls, hasLength(2));
      expect(find.text('Server says no'), findsNothing);
      expect(find.text('Late Gift'), findsWidgets);
      await _flush(tester);
    });

    testWidgets('offline: shows no-connection message instead of downloads',
        (tester) async {
      _mockConnectivity('none');
      final purchase = _FakePurchaseContentProvider();
      await tester.pumpWidget(
          _app(const WatchlistPage.giftedToYou(), purchase: purchase));
      await tester.pump(const Duration(milliseconds: 300));

      expect(purchase.calls, isEmpty);
      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  testWidgets('Watchlist itself is unchanged: filter chips incl. Gifted, '
      'default available fetch', (tester) async {
    final purchase = _FakePurchaseContentProvider();
    await tester.pumpWidget(_app(const WatchlistPage(), purchase: purchase));
    await tester.pump(const Duration(milliseconds: 300));

    expect(purchase.calls, [(isGifted: false, isExpired: false)]);
    expect(find.text('Gifted'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Gifted To You'), findsNothing);
  });
}
