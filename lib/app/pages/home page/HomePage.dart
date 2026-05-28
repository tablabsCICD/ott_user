import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/home%20page/category_content_page.dart';
import 'package:ott/app/pages/madioo%20page/MadiooPage.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/profile%20page/component/change_language.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsLibraryPage.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/route/route_observer.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/continueWatchMovieCard.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/shimmer%20loader/home_shimmer.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/get_dashboard_data.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/sharepreferences.dart';
import '../../provider/userProvider.dart';

class HomePage extends StatefulWidget {
  final String initialSelectedType;

  const HomePage({
    super.key,
    this.initialSelectedType = "MOVIE",
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  late String selectedType = _normalizedInitialType;
  bool isLoading = true;

//// upcoming movie posters
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Content> trendingMovieList = [];

  bool _dataLoaded = false;
  int? _userId;

  /// 🔥 NEW: Scroll controllers for each horizontal row
  final Map<int, ScrollController> _rowControllers = {};
  final Map<int, ValueNotifier<int?>> _rowActiveIndexes = {};
  final Map<int, int> _rowItemCounts = {};
  final Map<int, List<Content>> _rowItems = {};
  final Map<int, GlobalKey> _rowKeys = {};
  final ScrollController _verticalController = ScrollController();
  final ScrollController _continueWatchController = ScrollController();
  final ValueNotifier<int?> _continueWatchActiveIndex = ValueNotifier<int?>(0);
  int _continueWatchItemCount = 0;
  List<Content> _continueWatchItems = const <Content>[];
  bool _continueWatchListenerAttached = false;
  final GlobalKey _continueWatchKey = GlobalKey();
  bool _visibleUpdateScheduled = false;
  bool _isOffline = false;
  bool _continueWatchRefreshInFlight = false;
  PageRoute<dynamic>? _route;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _heroAutoScrollTimer;
  Timer? _heroTrailerPreviewTimer;
  Content? _heroTrailerPreviewContent;
  final TrailerPreviewController _heroTrailerPreviewController =
      TrailerPreviewController();

  @override
  void initState() {
    super.initState();

    _verticalController.addListener(_updateVisibleRows);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_setConnectionStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_dataLoaded) {
        _dataLoaded = true;
        await _initializeData();
      }
      if (mounted) {
        _updateVisibleRows();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        routeObserver.unsubscribe(this);
      }
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedType != widget.initialSelectedType) {
      selectedType = _normalizedInitialType;
      _dataLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _fetchUserData();
      });
    }
  }

  String get _normalizedInitialType => widget.initialSelectedType == "HOME"
      ? "MOVIE"
      : widget.initialSelectedType;

  @override
  void didPopNext() {
    _refreshContinueWatching();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    for (final controller in _rowControllers.values) {
      controller.dispose();
    }
    for (final notifier in _rowActiveIndexes.values) {
      notifier.dispose();
    }
    _rowControllers.clear();
    _rowActiveIndexes.clear();
    _rowItemCounts.clear();
    _rowItems.clear();
    _rowKeys.clear();

    _verticalController.dispose();
    _continueWatchController.dispose();
    _continueWatchActiveIndex.dispose();
    _connectivitySubscription?.cancel();
    _heroAutoScrollTimer?.cancel();
    _heroTrailerPreviewTimer?.cancel();
    _heroTrailerPreviewController.pause?.call();
    super.dispose();
  }

  Future<void> _refreshContinueWatching() async {
    if (!mounted ||
        _continueWatchRefreshInFlight ||
        _isOffline ||
        selectedType == 'MINI SERIES' ||
        selectedType == 'MADIOO') {
      return;
    }

    _continueWatchRefreshInFlight = true;
    try {
      await context
          .read<DashboardProvider>()
          .getContinueWatchedMovieList(selectedType);
    } finally {
      _continueWatchRefreshInFlight = false;
    }
  }

  Future<void> _initializeData() async {
    await _updateConnectionStatus();
    await _fetchUserData();
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    confirmDetails(context);
  }

  Future<void> _updateConnectionStatus() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    _setConnectionStatus(connectivityResults);
  }

  void _setConnectionStatus(List<ConnectivityResult> connectivityResults) {
    final isOffline = !connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!mounted) return;
    if (_isOffline == isOffline) return;
    setState(() {
      _isOffline = isOffline;
    });
  }

  void _startAutoScroll() {
    if (_heroAutoScrollTimer != null || trendingMovieList.length < 2) return;

    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted ||
          trendingMovieList.length < 2 ||
          !_pageController.hasClients) {
        return;
      }

      final nextPage = (_currentPage + 1) % trendingMovieList.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _heroAutoScrollTimer?.cancel();
    _heroAutoScrollTimer = null;
  }

  void _startHeroTrailerPreviewTimer(Content content) {
    _heroTrailerPreviewTimer?.cancel();
    _stopAutoScroll();

    if (content.teaserOrTrailerUrl?.trim().isNotEmpty != true &&
        content.trailerUrl?.trim().isNotEmpty != true) {
      _startAutoScroll();
      return;
    }

    _heroTrailerPreviewTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _heroTrailerPreviewContent = content;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _heroTrailerPreviewController.play?.call();
        }
      });
    });
  }

  void _hideHeroTrailerPreview() {
    _heroTrailerPreviewTimer?.cancel();
    _heroTrailerPreviewTimer = null;
    _heroTrailerPreviewController.pause?.call();
    if (mounted && _heroTrailerPreviewContent != null) {
      setState(() {
        _heroTrailerPreviewContent = null;
      });
    } else {
      _heroTrailerPreviewContent = null;
    }
    _startAutoScroll();
  }

  void confirmDetails(BuildContext context) {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false).userObject;

    if (userProvider.emailId!.isEmpty ||
        userProvider.firstName!.isEmpty ||
        userProvider.lastName!.isEmpty ||
        //userProvider.gender!.isEmpty ||
        userProvider.dob!.isEmpty) {
      userDetailsPopUp(context);
      return;
    } else if (userProvider.location!.country == null ||
        userProvider.location!.state == null ||
        userProvider.location!.district == null) {
      userLocationPopUp(context);
      return;
    } else {
      return;
    }
  }

  Future<void> _fetchUserData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (user != null && mounted) {
      _userId = user.id;
      await Provider.of<UserProvider>(context, listen: false)
          .getUserById(user.id!);
    }
    final dashBoardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final selectedLanguages = Provider.of<UserProvider>(context, listen: false)
            .userObject
            .selectedLanguages ??
        [];

    if (selectedLanguages.isEmpty || selectedLanguages == []) {
      await getMovieList(dashBoardProvider, selectedType, ["English"]);
    } else {
      await getMovieList(dashBoardProvider, selectedType, selectedLanguages);
    }
  }

  /// 🔥 NEW: Horizontal pagination trigger
  void _onRowScroll(
    ScrollController controller,
    DashboardProvider provider,
    DashboardData row,
  ) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      if (_userId != null) {
        provider.loadMoreRowData(row, selectedType, _userId!);
      }
    }
  }

  void _updateActiveIndex(
    ValueNotifier<int?> notifier,
    ScrollController controller,
    int itemCount,
    List<Content>? items,
  ) {
    if (!controller.hasClients || itemCount <= 0) {
      if (notifier.value != null) {
        notifier.value = null;
      }
      return;
    }

    final viewport = controller.position.viewportDimension;
    if (viewport <= 0) {
      if (notifier.value != null) {
        notifier.value = null;
      }
      return;
    }

    final maxScrollExtent = controller.position.maxScrollExtent;
    if (maxScrollExtent - controller.offset <= 1.0) {
      int bestLastIndex = itemCount - 1;

      if (items != null && items.isNotEmpty) {
        for (int i = itemCount - 1; i >= 0; i--) {
          if (i < items.length &&
              (items[i].trailerUrl?.trim().isNotEmpty ?? false)) {
            bestLastIndex = i;
            break;
          }
        }
      }

      if (notifier.value != bestLastIndex) {
        notifier.value = bestLastIndex;
      }
      return;
    }

    final viewStart = controller.offset;
    final viewEnd = viewStart + viewport;
    final firstCandidate = math.max(
      0,
      (viewStart / MovieCard.itemExtent).floor(),
    );
    final lastCandidate = math.min(
      itemCount - 1,
      ((viewEnd - 0.001) / MovieCard.itemExtent).floor(),
    );

    int? bestIndex;
    int? fallbackIndex;
    double bestOverlap = 0;

    for (int candidate = firstCandidate;
        candidate <= lastCandidate;
        candidate++) {
      final overlap = _visibleOverlap(viewStart, viewEnd, candidate);
      if (overlap <= 0) continue;

      fallbackIndex = candidate;
      final hasTrailer = items != null &&
          candidate < items.length &&
          (items[candidate].trailerUrl?.trim().isNotEmpty ?? false);
      if (!hasTrailer) {
        continue;
      }

      if (bestIndex == null ||
          overlap > bestOverlap ||
          (overlap == bestOverlap && candidate > bestIndex)) {
        bestOverlap = overlap;
        bestIndex = candidate;
      }
    }

    bestIndex ??= fallbackIndex;

    if (bestIndex == null) {
      if (notifier.value != null) {
        notifier.value = null;
      }
      return;
    }

    if (notifier.value != bestIndex) {
      notifier.value = bestIndex;
    }
  }

  double _visibleOverlap(double viewStart, double viewEnd, int index) {
    final itemStart = index * MovieCard.itemExtent;
    final itemEnd = itemStart + MovieCard.itemExtent;
    final overlap = math.min(viewEnd, itemEnd) - math.max(viewStart, itemStart);
    return overlap <= 0 ? 0 : overlap;
  }

  double? _rowCenterY(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final position = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    final centerY = position.dy + (size.height / 2);

    return centerY;
  }

  void _updateVisibleRows() {
    if (!mounted) return;

    final screenHeight = MediaQuery.of(context).size.height;
    for (final entry in _rowActiveIndexes.entries) {
      final rowIndex = entry.key;
      final notifier = entry.value;
      final controller = _rowControllers[rowIndex];
      final itemCount = _rowItemCounts[rowIndex] ?? 0;
      final items = _rowItems[rowIndex];
      final key = _rowKeys[rowIndex];
      final centerY = key == null ? null : _rowCenterY(key);
      final isVisible =
          centerY != null && centerY >= 0 && centerY <= screenHeight;

      if (!isVisible || controller == null) {
        if (notifier.value != null) {
          notifier.value = null;
        }
        continue;
      }

      _updateActiveIndex(notifier, controller, itemCount, items);
    }

    if (_continueWatchItemCount > 0) {
      final centerY = _rowCenterY(_continueWatchKey);
      final isVisible =
          centerY != null && centerY >= 0 && centerY <= screenHeight;
      if (isVisible) {
        _updateActiveIndex(
          _continueWatchActiveIndex,
          _continueWatchController,
          _continueWatchItemCount,
          _continueWatchItems,
        );
      } else if (_continueWatchActiveIndex.value != null) {
        _continueWatchActiveIndex.value = null;
      }
    }
  }

  void _scheduleVisibleUpdate() {
    if (_visibleUpdateScheduled) return;
    _visibleUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibleUpdateScheduled = false;
      _updateVisibleRows();
    });
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;
    final isMobile = ResponsiveWidget.isMobile(context);

    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      body: isLoading
          ? HomeShimmer()
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isMobile
                      ? [
                          selectedThemeData.scaffoldBackgroundColor,
                          selectedThemeData.scaffoldBackgroundColor,
                        ]
                      : [
                          const Color(0xFF12141C),
                          selectedThemeData.scaffoldBackgroundColor,
                          selectedThemeData.scaffoldBackgroundColor,
                        ],
                ),
              ),
              child: CustomScrollView(
                controller: _verticalController,
                slivers: [
                  _buildSliverAppBar(context, selectedThemeData),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveWidget.isMobile(context) ? 8 : 0,
                        vertical: ResponsiveWidget.isMobile(context) ? 8 : 0,
                      ),
                      child: Consumer<DashboardProvider>(
                          builder: (context, dashboardProvider, child) {
                        final showContentLoader = dashboardProvider.isLoading &&
                            (selectedType == 'MOVIE' ||
                                selectedType == 'SERIES');

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroSpotlight(
                              context,
                              selectedThemeData,
                              dashboardProvider,
                            ),
                            SizedBox(
                              height:
                                  ResponsiveWidget.isMobile(context) ? 5 : 14,
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildFilterButtons(
                                  context, dashboardProvider),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            showContentLoader
                                ? _buildDashboardSectionLoader(
                                    context,
                                    selectedThemeData,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      selectedType == 'MINI SERIES' ||
                                              selectedType == 'MADIOO'
                                          ? SizedBox.shrink()
                                          : _isOffline
                                              ? _continueWatchShimmerWidget()
                                              : continueWatchWidget(
                                                  continueWatchList:
                                                      dashboardProvider
                                                          .continueWatchedMovies),
                                      selectedType == 'MINI SERIES'
                                          ? ShortsLibraryPage(
                                              useParentScroll: true)
                                          : selectedType == 'MADIOO'
                                              ? MadiooPage(
                                                  useParentScroll: true)
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      NeverScrollableScrollPhysics(),
                                                  padding: EdgeInsets.zero,
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  itemCount: dashboardProvider
                                                      .dashboardData.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    DashboardData
                                                        dashboardData =
                                                        dashboardProvider
                                                                .dashboardData[
                                                            index];

                                                    _rowControllers.putIfAbsent(
                                                        index,
                                                        () =>
                                                            ScrollController());
                                                    _rowActiveIndexes
                                                        .putIfAbsent(
                                                            index,
                                                            () => ValueNotifier<
                                                                int?>(0));
                                                    _rowItemCounts[index] =
                                                        dashboardData.movies
                                                                ?.length ??
                                                            0;
                                                    _rowItems[index] =
                                                        dashboardData.movies ??
                                                            const <Content>[];
                                                    _rowKeys.putIfAbsent(index,
                                                        () => GlobalKey());

                                                    final controller =
                                                        _rowControllers[index]!;
                                                    final activeIndex =
                                                        _rowActiveIndexes[
                                                            index]!;
                                                    final rowKey =
                                                        _rowKeys[index]!;
                                                    final rowIndex = index;

                                                    // 🔥 Attach listener ONLY once
                                                    if (!controller
                                                        .hasListeners) {
                                                      controller
                                                          .addListener(() {
                                                        final rowNotifier =
                                                            _rowActiveIndexes[
                                                                rowIndex];
                                                        final rowController =
                                                            _rowControllers[
                                                                rowIndex];
                                                        final rowItemCount =
                                                            _rowItemCounts[
                                                                    rowIndex] ??
                                                                0;
                                                        final rowItems =
                                                            _rowItems[rowIndex];

                                                        if (rowNotifier !=
                                                                null &&
                                                            rowController !=
                                                                null) {
                                                          _updateActiveIndex(
                                                            rowNotifier,
                                                            rowController,
                                                            rowItemCount,
                                                            rowItems,
                                                          );
                                                        }

                                                        _scheduleVisibleUpdate();

                                                        if (controller.position
                                                                .pixels >=
                                                            controller.position
                                                                    .maxScrollExtent -
                                                                200) {
                                                          if (_userId != null) {
                                                            dashboardProvider
                                                                .loadMoreRowData(
                                                                    dashboardData,
                                                                    selectedType,
                                                                    _userId!);
                                                          }
                                                        }
                                                      });
                                                    }

                                                    _scheduleVisibleUpdate();

                                                    return KeyedSubtree(
                                                      key: rowKey,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          (dashboardData.movies ==
                                                                      null ||
                                                                  dashboardData
                                                                      .movies!
                                                                      .isEmpty)
                                                              ? SizedBox
                                                                  .shrink()
                                                              : InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap: () {
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (_) =>
                                                                                CategoryContentPage(
                                                                          categoryTitle:
                                                                              "${dashboardData.language} - ${dashboardData.category}",
                                                                          contents:
                                                                              dashboardData.movies ?? [],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          "${dashboardData.language} - ${dashboardData.category}",
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style:
                                                                              GoogleFonts.inter(
                                                                            fontSize: ResponsiveWidget.isMobile(context)
                                                                                ? 18
                                                                                : 20,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                selectedThemeData.canvasColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Icon(
                                                                        Icons
                                                                            .arrow_forward_ios,
                                                                        size:
                                                                            18,
                                                                        color: selectedThemeData
                                                                            .primaryColor,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            3,
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                          (dashboardData.movies ==
                                                                      null ||
                                                                  dashboardData
                                                                      .movies!
                                                                      .isEmpty)
                                                              ? SizedBox
                                                                  .shrink()
                                                              : SizedBox(
                                                                  height: 270,
                                                                  child: ListView
                                                                      .builder(
                                                                    controller:
                                                                        controller,
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    //padding: EdgeInsets.zero,
                                                                    itemCount: dashboardData
                                                                            .movies!
                                                                            .length +
                                                                        (dashboardData.isRowLoading
                                                                            ? 1
                                                                            : 0),
                                                                    itemBuilder:
                                                                        (context,
                                                                            i) {
                                                                      if (i <
                                                                          dashboardData
                                                                              .movies!
                                                                              .length) {
                                                                        return MovieCard(
                                                                          movie:
                                                                              dashboardData.movies![i],
                                                                          index:
                                                                              i,
                                                                          activeIndexListenable: ResponsiveWidget.isTabletOrTv(context)
                                                                              ? activeIndex
                                                                              : null,
                                                                        );
                                                                      } else if (dashboardData
                                                                          .isRowLoading) {
                                                                        return Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              12),
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                40,
                                                                            height:
                                                                                40,
                                                                            child:
                                                                                CircularProgressIndicator(strokeWidth: 2),
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        return const SizedBox
                                                                            .shrink();
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                          (dashboardData.movies ==
                                                                      null ||
                                                                  dashboardData
                                                                      .movies!
                                                                      .isEmpty)
                                                              ? SizedBox
                                                                  .shrink()
                                                              : SizedBox(
                                                                  height: 20),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                    ],
                                  ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSpotlight(
    BuildContext context,
    ThemeData theme,
    DashboardProvider dashboardProvider,
  ) {
    final candidates = dashboardProvider.dashboardData
        .expand((row) => row.movies ?? const <Content>[])
        .where((item) => item.posterUrlList?.isNotEmpty == true)
        .toList();

    if (candidates.isEmpty ||
        selectedType == 'MINI SERIES' ||
        selectedType == 'MADIOO') {
      return const SizedBox.shrink();
    }

    trendingMovieList = candidates.take(8).toList();
    _startAutoScroll();
    final useCinematicHero = ResponsiveWidget.isTabletOrTv(context);

    if (!useCinematicHero) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 520,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        /*  boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            // blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ], */
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: trendingMovieList.length,
            onPageChanged: (index) {
              _hideHeroTrailerPreview();
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final content = trendingMovieList[index];
              return _buildHeroSlide(context, theme, content, true);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(trendingMovieList.length, (index) {
                final selected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(
    BuildContext context,
    ThemeData theme,
    Content content,
    bool isTv,
  ) {
    final posterUrl = content.posterUrlList!.first;

    final genreText = content.genreList?.take(3).join('  •  ') ?? '';

    final previewGenreText = content.genreList?.take(2).join('  |  ') ?? '';
    final previewTrailerUrl =
        (content.teaserOrTrailerUrl?.trim().isNotEmpty ?? false)
            ? content.teaserOrTrailerUrl
            : content.trailerUrl;

    bool isHovered = false;
    bool isFocused = false;

    void startTrailerPreview() {
      _startHeroTrailerPreviewTimer(content);
    }

    void stopTrailerPreviewIfIdle() {
      if (!isHovered && !isFocused) {
        _hideHeroTrailerPreview();
      }
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final showPreview = _heroTrailerPreviewContent?.id == content.id &&
            previewTrailerUrl?.trim().isNotEmpty == true;

        return MouseRegion(
          onEnter: (_) {
            setLocalState(() => isHovered = true);
            startTrailerPreview();
          },
          onExit: (_) {
            setLocalState(() => isHovered = false);
            stopTrailerPreviewIfIdle();
          },
          child: OttTvFocus(
            onFocusChange: (focused) {
              isFocused = focused;
              if (focused) {
                startTrailerPreview();
              } else {
                stopTrailerPreviewIfIdle();
              }
            },
            onTap: () {
              _hideHeroTrailerPreview();
              _openContentDetails(content);
            },
            /*   borderRadius: BorderRadius.circular(
              isTv ? 28 : 20,
            ), */
            scale: 1.008,
            child: GestureDetector(
              onTap: () {
                _hideHeroTrailerPreview();
                _openContentDetails(content);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // BACKGROUND IMAGE
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 420,
                    ),
                    child: Image.network(
                      posterUrl,
                      key: ValueKey(
                        posterUrl,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.cardColor,
                        child: Icon(
                          Icons.movie_creation_outlined,
                          color: theme.canvasColor.withValues(
                            alpha: 0.4,
                          ),
                          size: 64,
                        ),
                      ),
                    ),
                  ),

                  // LEFT OVERLAY
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black,
                          Colors.black.withValues(
                            alpha: 0.86,
                          ),
                          Colors.black.withValues(
                            alpha: 0.22,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [
                          0,
                          0.38,
                          0.72,
                          1,
                        ],
                      ),
                    ),
                  ),

                  // BOTTOM OVERLAY
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // LEFT NAVIGATION ARROW
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(
                          milliseconds: 250,
                        ),
                        opacity: isHovered ? 1 : 0.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            100,
                          ),
                          onTap: () {
                            if (_pageController.hasClients) {
                              _pageController.previousPage(
                                duration: const Duration(
                                  milliseconds: 450,
                                ),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.45,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // RIGHT NAVIGATION ARROW
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(
                          milliseconds: 250,
                        ),
                        opacity: isHovered ? 1 : 0.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            100,
                          ),
                          onTap: () {
                            if (_pageController.hasClients) {
                              _pageController.nextPage(
                                duration: const Duration(
                                  milliseconds: 450,
                                ),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.45,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: isTv ? 72 : 58,
                    right: isTv ? 86 : 18,
                    width: isTv
                        ? MediaQuery.of(context).size.width * 0.36
                        : MediaQuery.of(context).size.width * 0.48,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(curved),
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.96,
                                end: 1,
                              ).animate(curved),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: showPreview
                          ? _buildHeroTrailerPreviewPanel(
                              context: context,
                              theme: theme,
                              content: content,
                              trailerUrl: previewTrailerUrl,
                              genreText: previewGenreText,
                              isTv: isTv,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // CONTENT AREA
                  Positioned(
                    left: isTv ? 70 : 22,
                    right: isTv ? MediaQuery.of(context).size.width * 0.46 : 22,
                    bottom: isTv ? 64 : 44,
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 320,
                      ),
                      transitionBuilder: (
                        child,
                        animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(
                                0.04,
                                0,
                              ),
                              end: Offset.zero,
                            ).animate(
                              animation,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(
                          content.id,
                        ),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _heroBadge(
                            theme,
                            '#${(_currentPage % 10) + 1} Trending',
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          Text(
                            content.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: isTv ? 46 : 27,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            [
                              content.releaseDate,
                              genreText,
                              '${double.parse((content.ratings ?? 0).toStringAsFixed(1))} ★',
                            ]
                                .where(
                                  (value) => value.trim().isNotEmpty,
                                )
                                .join('  •  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            content.description ?? '',
                            maxLines: isTv ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.76,
                              ),
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _heroAction(
                                theme: theme,
                                icon: Icons.play_arrow_rounded,
                                label: 'Watch Now',
                                primary: true,
                                onTap: () => _openContentDetails(
                                  content,
                                ),
                              ),
                              _heroAction(
                                theme: theme,
                                icon: Icons.movie_filter_rounded,
                                label: 'Trailer',
                                onTap: () => _openHeroTrailer(
                                  content,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroTrailerPreviewPanel({
    required BuildContext context,
    required ThemeData theme,
    required Content content,
    required String? trailerUrl,
    required String genreText,
    required bool isTv,
  }) {
    return ClipRRect(
      key: ValueKey('hero-preview-${content.id}'),
      borderRadius: BorderRadius.circular(isTv ? 24 : 18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isTv ? 0 : 0),
                    ),
                    child: TrailerPreview(
                      trailerUrl: trailerUrl,
                      content: content,
                      controller: _heroTrailerPreviewController,
                      autoplayMuted: true,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.44),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Trailer Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTv ? 18 : 14,
                  14,
                  isTv ? 18 : 14,
                  isTv ? 18 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: isTv ? 22 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (genreText.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        genreText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: isTv ? 13 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBadge(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _heroAction({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return OttTvFocus(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      scale: 1.05,
      child: Material(
        color:
            primary ? theme.primaryColor : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHeroTrailer(Content content) {
    _hideHeroTrailerPreview();
    final trailerUrl = (content.teaserOrTrailerUrl?.trim().isNotEmpty ?? false)
        ? content.teaserOrTrailerUrl
        : content.trailerUrl;
    if (trailerUrl == null || trailerUrl.trim().isEmpty) {
      CustomToast.show(context, "Trailer is not available", isSuccess: false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: content,
        ),
      ),
    );
  }

  void _openContentDetails(Content content) {
    if (content.id == null || content.type == null) return;
    _hideHeroTrailerPreview();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => content.type!.toLowerCase() == 'movie'
            ? MovieDetailsPage(movieId: content.id!)
            : SeriesDetailsPage(seriesId: content.id!, content: content),
      ),
    );
  }

  Widget continueWatchWidget({
    required List<Content> continueWatchList,
  }) {
    final items = continueWatchList
        .where((item) => (item.watchedPercentage ?? 0) < 95)
        .toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    var theme = Theme.of(context);

    _continueWatchItemCount = items.length;
    _continueWatchItems = items;
    if (!_continueWatchListenerAttached) {
      _continueWatchListenerAttached = true;
      _continueWatchController.addListener(() {
        _scheduleVisibleUpdate();
      });
    }

    _scheduleVisibleUpdate();

    return KeyedSubtree(
      key: _continueWatchKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 LABEL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
            child: Text(
              "Continue Watching",
              style: GoogleFonts.inter(
                fontSize: ResponsiveWidget.isMobile(context) ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: theme.canvasColor,
              ),
            ),
          ),

          // 🎬 HORIZONTAL LIST
          SizedBox(
            height: 220, //270,
            child: ListView.builder(
              controller: _continueWatchController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                // return SizedBox(
                //   width: MovieCard.itemExtent,
                //   child: MovieCard(
                //     movie: item,
                //     index: index,
                //     activeIndexListenable: _continueWatchActiveIndex,
                //   ),
                // );
                return SizedBox(
                  width: ContinueWatchMovieCard.itemExtent,
                  child: ContinueWatchMovieCard(
                    movie: item,
                    index: index,
                    enableTrailerPreview: false,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _continueWatchShimmerWidget() {
    final theme = Theme.of(context);
    final itemCount = ResponsiveWidget.isMobile(context)
        ? 2
        : ResponsiveWidget.isDesktop(context)
            ? 5
            : 3;

    _continueWatchItemCount = 0;
    _continueWatchItems = const <Content>[];
    if (_continueWatchActiveIndex.value != null) {
      _continueWatchActiveIndex.value = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: ShimmerLoader(
            width: ResponsiveWidget.isMobile(context) ? 170 : 220,
            height: ResponsiveWidget.isMobile(context) ? 18 : 20,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                width: ContinueWatchMovieCard.itemExtent,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: ShimmerLoader(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerLoader(
                            width: double.infinity,
                            height: 6,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 10),
                          ShimmerLoader(
                            width: ContinueWatchMovieCard.itemExtent * 0.62,
                            height: 14,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 8),
                          ShimmerLoader(
                            width: ContinueWatchMovieCard.itemExtent * 0.4,
                            height: 10,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

// double bannerHeight(BuildContext context) {
  //   final width = MediaQuery.of(context).size.width;

  //   const posterRatio = 16 / 8;
  //   return width / posterRatio;
  // }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, ThemeData selectedThemeData) {
    final lang = AppLocalizations.of(context)!;
    final isMobile = ResponsiveWidget.isMobile(context);

    return SliverAppBar(
      automaticallyImplyLeading: false,
      forceMaterialTransparency: true,
      // expandedHeight: bannerHeight(context),
      floating: false,
      pinned: true,
      stretch: true,
      toolbarHeight: isMobile ? 72 : 82,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        ),
      ),
      title: Row(
        children: [
          //  _buildAppLogo(context),
          if (!isMobile) const Spacer(),
        ],
      ),
      titleSpacing: isMobile ? 10 : 28,
      actions: [
        //LanguageDropdown(),
        IconButton(
          icon: Icon(Icons.search,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.search,
          style: IconButton.styleFrom(
              backgroundColor: ResponsiveWidget.isDesktop(context)
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchPage()),
          ),
        ),
        SizedBox(
          width: 4,
        ),
        IconButton(
          icon: Icon(Icons.notifications_active,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.notification,
          style: IconButton.styleFrom(
              backgroundColor: ResponsiveWidget.isDesktop(context)
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationPage()),
          ),
        ),
        SizedBox(
          width: 4,
        ),
        IconButton(
          tooltip: lang.selectPreferredLanguage,
          style: IconButton.styleFrom(
            backgroundColor: ResponsiveWidget.isDesktop(context)
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
          ),
          icon: Icon(Icons.language_sharp,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeLanguage(),
            ),
          ),
        ),

        SizedBox(
          width: 4,
        ),
        Consumer<UserProvider>(builder: (context, userProvider, child) {
          final walletProvider =
              Provider.of<WalletProvider>(context, listen: false);

          final user = userProvider.userObject;
          return Row(
            children: [
              IconButton(
                icon: Icon(Icons.account_balance_wallet,
                    color: ResponsiveWidget.isDesktop(context)
                        ? selectedThemeData.canvasColor
                        : Colors.white),
                tooltip: "${walletProvider.walletBalance}",
                style: IconButton.styleFrom(
                    backgroundColor: ResponsiveWidget.isDesktop(context)
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WalletPage()),
                ),
              ),
              SizedBox(
                width: 4,
              ),
              Tooltip(
                textStyle: TextStyle(
                  fontSize: 10,
                  color: selectedThemeData.scaffoldBackgroundColor,
                ),
                message:
                    "${userProvider.userObj.firstName} ${userProvider.userObj.lastName}",
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ProfilePage()));
                  },
                  child: Hero(
                    tag: "profile",
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: selectedThemeData.canvasColor,
                        backgroundImage:
                            userProvider.userObj.profilePhoto == null
                                ? AssetImage(ImageConstant.profile)
                                : userProvider.userObj.profilePhoto!.isNotEmpty
                                    ? NetworkImage(
                                        userProvider.userObj.profilePhoto!,
                                      )
                                    : AssetImage(ImageConstant.profile),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(width: 16),
      ],
      // flexibleSpace: FlexibleSpaceBar(
      //   stretchModes: const [
      //     StretchMode.zoomBackground,
      //     StretchMode.fadeTitle,
      //   ],
      //   background: Stack(
      //     children: [
      //       // Base fallback
      //       Positioned.fill(
      //         child: Container(
      //           color: selectedThemeData.scaffoldBackgroundColor,
      //         ),
      //       ),

      //       // Banner carousel
      //       Positioned.fill(
      //         child: trendingMovieList.isEmpty
      //             ? const SizedBox.shrink()
      //             : PageView.builder(
      //                 controller: _pageController,
      //                 itemCount: trendingMovieList.length,
      //                 onPageChanged: (i) {
      //                   setState(() => _currentPage = i);
      //                 },
      //                 itemBuilder: (context, index) {
      //                   final poster = trendingMovieList[index].posterUrlList;
      //                   return poster != null && poster.isNotEmpty
      //                       ? Image.network(
      //                           poster.first,
      //                           fit: BoxFit.cover,
      //                           errorBuilder: (_, __, ___) => Container(
      //                             color: Colors.black12,
      //                             child: const Icon(Icons.broken_image),
      //                           ),
      //                         )
      //                       : const SizedBox.shrink();
      //                 },
      //               ),
      //       ),

      //       // Hotstar-style dark gradient
      //       Positioned.fill(
      //         child: Container(
      //           decoration: const BoxDecoration(
      //             gradient: LinearGradient(
      //               begin: Alignment.topCenter,
      //               end: Alignment.bottomCenter,
      //               colors: [
      //                 Color.fromARGB(120, 0, 0, 0),
      //                 Color.fromARGB(60, 0, 0, 0),
      //                 Colors.transparent,
      //                 Color.fromARGB(180, 0, 0, 0),
      //               ],
      //             ),
      //           ),
      //         ),
      //       ),

      //       if (trendingMovieList.isNotEmpty) ...[
      //         // Bottom-left content
      //         Positioned(
      //           left: 16,
      //           right: ResponsiveWidget.isMobile(context) ? 150 : 360,
      //           bottom: 16,
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Text(
      //                 trendingMovieList[_currentPage].title ?? '',
      //                 maxLines: 1,
      //                 overflow: TextOverflow.ellipsis,
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: ResponsiveWidget.isMobile(context) ? 20 : 24,
      //                   fontWeight: FontWeight.w700,
      //                 ),
      //               ),
      //               const SizedBox(height: 4),
      //               Row(
      //                 children: [
      //                   StarRatingWidget(
      //                     rating: double.parse(
      //                       (trendingMovieList[_currentPage].ratings ?? 0)
      //                           .toStringAsFixed(1),
      //                     ),
      //                   ),
      //                   const SizedBox(width: 8),
      //                   Text(
      //                     (trendingMovieList[_currentPage]
      //                                 .genreList
      //                                 ?.isNotEmpty ??
      //                             false)
      //                         ? trendingMovieList[_currentPage]
      //                             .genreList!
      //                             .join(', ')
      //                         : 'N/A',
      //                     style: const TextStyle(
      //                       color: Colors.white70,
      //                       fontWeight: FontWeight.bold,
      //                       fontSize: 11,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                 ],
      //               ),
      //               const SizedBox(height: 4),
      //               Row(
      //                 crossAxisAlignment: CrossAxisAlignment.center,
      //                 children: [
      //                   Text(
      //                     (trendingMovieList[_currentPage]
      //                                 .languageList
      //                                 ?.isNotEmpty ??
      //                             false)
      //                         ? trendingMovieList[_currentPage]
      //                             .languageList!
      //                             .map((e) => e.language)
      //                             .join(', ')
      //                         : 'N/A',
      //                     style: const TextStyle(
      //                       color: Colors.white,
      //                       fontSize: 11,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                   Text(
      //                     ' | ',
      //                     style: TextStyle(
      //                       color: selectedThemeData.primaryColor,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                   Text(
      //                     "${trendingMovieList[_currentPage].runtime ?? 'xx min'} min",
      //                     style: const TextStyle(
      //                       color: Colors.white,
      //                       fontSize: 11,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                   Text(
      //                     ' | ',
      //                     style: TextStyle(
      //                       color: selectedThemeData.primaryColor,
      //                       fontSize: 14,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                   Text(
      //                     "${trendingMovieList[_currentPage].releaseDate ?? 'NA'}",
      //                     style: const TextStyle(
      //                       color: Colors.white,
      //                       fontSize: 11,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //                 ],
      //               ),
      //               const SizedBox(height: 4),
      //               Text(
      //                 trendingMovieList[_currentPage].description ?? '',
      //                 maxLines: 2,
      //                 overflow: TextOverflow.ellipsis,
      //                 style: const TextStyle(
      //                   color: Colors.white70,
      //                   fontSize: 11,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),

      //         // Bottom-right button
      //         Positioned(
      //           right: 16,
      //           bottom: 48,
      //           child: GestureDetector(
      //             onTap: () => Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) => trendingMovieList[_currentPage]
      //                             .type!
      //                             .toLowerCase() ==
      //                         'movie'
      //                     ? MovieDetailsPage(
      //                         movieId: trendingMovieList[_currentPage].id!,
      //                       )
      //                     : SeriesDetailsPage(
      //                         seriesId: trendingMovieList[_currentPage].id ?? 0,
      //                         content: trendingMovieList[_currentPage],
      //                       ),
      //               ),
      //             ),
      //             child: Container(
      //               decoration: BoxDecoration(
      //                 borderRadius: BorderRadius.circular(
      //                   10,
      //                 ),
      //                 color: selectedThemeData.primaryColor.withOpacity(0.9),
      //               ),
      //               child: Padding(
      //                 padding: EdgeInsets.symmetric(
      //                   vertical: 8.0,
      //                   horizontal: 16,
      //                 ),
      //                 child: Text(
      //                   "Watch",
      //                   style: TextStyle(
      //                     fontSize: 14,
      //                     fontWeight: FontWeight.bold,
      //                     color: Colors.white,
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //           // child: GestureDetector(
      //           //   onTap: () {},
      //           //   child: Container(
      //           //     padding:
      //           //         const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      //           //     decoration: BoxDecoration(
      //           //       color: selectedThemeData.primaryColor,
      //           //       borderRadius: BorderRadius.circular(6),
      //           //     ),
      //           //     child: Text(
      //           //       trendingMovieList[_currentPage].isRental == true
      //           //           ? (trendingMovieList[_currentPage]
      //           //                       .type
      //           //                       ?.toLowerCase() ==
      //           //                   "movie"
      //           //               ? lang.watchMovie
      //           //               : lang.watchSeries)
      //           //           : "₹${trendingMovieList[_currentPage].price}",
      //           //       style: const TextStyle(
      //           //         color: Colors.white,
      //           //         fontSize: 14,
      //           //         fontWeight: FontWeight.w600,
      //           //       ),
      //           //     ),
      //           //   ),
      //           // ),
      //         ),
      //       ],
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return OttTvFocus(
      onTap: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NavigationPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      scale: 1.04,
      child: Hero(
        tag: "logo",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            ImageConstant.inAppLogo,
            width: 82,
            height: 54,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons(
      BuildContext context, DashboardProvider dashboardProvider) {
    final lang = AppLocalizations.of(context)!;
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        "MOVIE",
        "SERIES",
        "MINI SERIES",
        "MADIOO",
      ].map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: OttTvFocus(
            borderRadius: BorderRadius.circular(12),
            scale: 1.04,
            onTap: () async {
              setState(() {
                selectedType = type;
              });
              final selectedLanguages =
                  Provider.of<UserProvider>(context, listen: false)
                          .userObject
                          .selectedLanguages ??
                      []; // Ensure it doesn't throw null

              print(selectedLanguages);
              if (selectedType == 'MINI SERIES') {
                return;
              }
              if (selectedType == 'MADIOO') {
                return;
              }
              if (selectedLanguages.isEmpty || selectedLanguages == []) {
                await getMovieList(
                    dashboardProvider, selectedType, ["Hindi", "English"]);
              } else {
                await getMovieList(
                    dashboardProvider, selectedType, selectedLanguages);
              }
            },
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  selectedType = type;
                });
                final selectedLanguages =
                    Provider.of<UserProvider>(context, listen: false)
                            .userObject
                            .selectedLanguages ??
                        [];

                print(selectedLanguages);
                if (selectedType == 'MINI SERIES') {
                  return;
                }
                if (selectedType == 'MADIOO') {
                  return;
                }
                if (selectedLanguages.isEmpty || selectedLanguages == []) {
                  await getMovieList(
                      dashboardProvider, selectedType, ["Hindi", "English"]);
                } else {
                  await getMovieList(
                      dashboardProvider, selectedType, selectedLanguages);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selectedType == type
                      ? selectedThemeData.primaryColor
                      : selectedThemeData.cardColor.withOpacity(0.68),
                  border: Border.all(
                    color: selectedType == type
                        ? selectedThemeData.primaryColor
                        : selectedThemeData.canvasColor.withOpacity(0.6),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Text(
                    type == 'MOVIE'
                        ? lang.movie
                        : type == 'SERIES'
                            ? lang.series
                            : type == 'MINI SERIES'
                                ? 'Mini Series'
                                : 'Madioo',
                    style: TextStyle(
                      color: selectedType == type
                          ? Colors.white
                          : selectedThemeData.primaryColor,
                      fontWeight: selectedType == type
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          //
        );
      }).toList(),
    );
  }

  Widget _buildDashboardSectionLoader(
      BuildContext context, ThemeData selectedThemeData) {
    final cardCount = ResponsiveWidget.isMobile(context)
        ? 1
        : ResponsiveWidget.isDesktop(context)
            ? 4
            : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (sectionIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: sectionIndex == 2 ? 0 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ShimmerLoader(
                  width: ResponsiveWidget.isMobile(context) ? 170 : 220,
                  height: 18,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cardCount,
                  itemBuilder: (context, index) {
                    return Container(
                      width: MovieCard.itemWidth,
                      margin: const EdgeInsets.all(MovieCard.itemMargin),
                      decoration: BoxDecoration(
                        color:
                            selectedThemeData.cardColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 8,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: const ShimmerLoader(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 0,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerLoader(
                                    width: 80,
                                    height: 10,
                                    borderRadius: 6,
                                  ),
                                  const SizedBox(height: 8),
                                  const ShimmerLoader(
                                    width: double.infinity,
                                    height: 14,
                                  ),
                                  const SizedBox(height: 6),
                                  ShimmerLoader(
                                    width: 110,
                                    height: 10,
                                    borderRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> getMovieList(DashboardProvider dashBoardProvider,
      String selectedType, List<String> langList) async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    log('User in getMovieList method ${user!.firstName} ');
    await dashBoardProvider.getContinueWatchedMovieList(selectedType);

    await dashBoardProvider.getDashboardData(selectedType, langList, user.id!);
  }

//get user baisc details after sign in
  Future<void> userDetailsPopUp(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final lang = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) {
        UserProvider userProvider =
            Provider.of<UserProvider>(context, listen: true);
        var selectedThemeData =
            Provider.of<ThemeProvider>(context, listen: true).getTheme;
        return AlertDialog(
          backgroundColor: selectedThemeData.scaffoldBackgroundColor,
          title: Text(lang.enterDetails),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(lang.birthDate,
                          style: TextStyle(
                              color: selectedThemeData.canvasColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500))),
                  SizedBox(height: 5),
                  TextFormField(
                    cursorColor: const Color(0xFFE50914),
                    controller: userProvider.dobController,
                    readOnly: true,
                    onTap: () {
                      _selectDate(userProvider);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: selectedThemeData.cardColor,
                      hintText: lang.enterBirthDate,
                      hintStyle: TextStyle(
                        color: selectedThemeData.canvasColor,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: selectedThemeData.primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    controller: userProvider.firstNameController,
                    isName: true,
                    label: lang.firstName,
                    hintText: lang.enterFirstName,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.lastNameController,
                    isName: true,
                    label: lang.lastName,
                    hintText: lang.enterLastName,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.emailController,
                    isEmail: true,
                    isValidator: true,
                    label: lang.email,
                    hintText: lang.enterEmail,
                    textInputType: TextInputType.emailAddress,
                    // decoration: const InputDecoration(labelText: 'Email'),
                    // validator: (value) =>
                    //     value!.contains('@') ? null : 'Enter a valid email',
                  ),
                  CustomTextField(
                    controller: userProvider.refferedByController,
                    hintText: lang.referralCodeOptional,
                    label: lang.enterReferralCode,
                    textInputType: TextInputType.text,
                    capitalization: TextCapitalization.characters,
                    isValidator: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedThemeData.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                var result = await userProvider.updateUserDetails();
                if (result['success'] == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', true);

                  CustomToast.show(context, lang.profileUpdatedSuccessfully,
                      isSuccess: true);

                  Navigator.of(context).pop();
                } else {
                  CustomToast.show(context, 'Failure: ${result['message']}',
                      isSuccess: false);
                  Navigator.of(context).pop();
                }
              },
              child: Center(
                child: Text(
                  lang.save,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

//get user location details after sign in
  Future<void> userLocationPopUp(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final lang = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadCountryOptions();

    await showDialog(
      context: context,
      builder: (ctx) {
        UserProvider userProvider =
            Provider.of<UserProvider>(context, listen: true);
        var selectedThemeData =
            Provider.of<ThemeProvider>(context, listen: true).getTheme;
        return AlertDialog(
          backgroundColor: selectedThemeData.scaffoldBackgroundColor,
          title: Text(
            lang.enterLocationDetails,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userProvider.officeBuildingController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [CapitalizeWordsTextInputFormatter()],
                    cursorColor: selectedThemeData.primaryColor,
                    onChanged: (value) {
                      userProvider.searchAddressSuggestions(value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: selectedThemeData.cardColor,
                      labelText: 'Address',
                      hintText: 'Search your address',
                      labelStyle:
                          TextStyle(color: selectedThemeData.canvasColor),
                      hintStyle: TextStyle(
                        color: selectedThemeData.canvasColor,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: selectedThemeData.primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: selectedThemeData.canvasColor,
                      ),
                      suffixIcon: userProvider.isSearchingAddress
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: selectedThemeData.primaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                    style: TextStyle(color: selectedThemeData.canvasColor),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: userProvider.isFetchingCurrentLocation
                        ? null
                        : () async {
                            final allowed =
                                await _showLocationPermissionPrompt(ctx);
                            if (!ctx.mounted) return;
                            if (allowed != true) return;

                            final locationFilled = await userProvider
                                .useCurrentLocationFromGoogle();
                            if (!ctx.mounted) return;
                            if (!locationFilled) {
                              CustomToast.show(
                                ctx,
                                'Unable to fetch your location. Please enter address manually.',
                                isSuccess: false,
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedThemeData.primaryColor,
                      side: BorderSide(color: selectedThemeData.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: userProvider.isFetchingCurrentLocation
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: selectedThemeData.primaryColor,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      userProvider.isFetchingCurrentLocation
                          ? 'Fetching location...'
                          : 'Use current location',
                    ),
                  ),
                  if (userProvider.addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedThemeData.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedThemeData.primaryColor
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userProvider.addressSuggestions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: selectedThemeData.canvasColor
                              .withValues(alpha: 0.08),
                        ),
                        itemBuilder: (context, index) {
                          final suggestion =
                              userProvider.addressSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.place_outlined,
                              color: selectedThemeData.primaryColor,
                            ),
                            title: Text(
                              suggestion['description'] ?? '',
                              style: TextStyle(
                                color: selectedThemeData.canvasColor,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              userProvider.selectAddressSuggestion(suggestion);
                            },
                          );
                        },
                      ),
                    ),
                  _buildEditableLocationDropdown(
                    context: context,
                    selectedThemeData: selectedThemeData,
                    controller: userProvider.countryController,
                    label: lang.country,
                    hintText: lang.enterCountry,
                    options: userProvider.countryOptions,
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        userProvider.loadStateOptionsByCountry('');
                      }
                    },
                    onFieldSubmitted: (value) {
                      userProvider.loadStateOptionsByCountry(value);
                    },
                    onOptionSelected: (value) {
                      userProvider.loadStateOptionsByCountry(value);
                    },
                  ),
                  _buildEditableLocationDropdown(
                    context: context,
                    selectedThemeData: selectedThemeData,
                    controller: userProvider.stateController,
                    label: lang.state,
                    hintText: lang.enterState,
                    options: userProvider.stateOptions,
                  ),
                  _buildEditableLocationDropdown(
                    context: context,
                    selectedThemeData: selectedThemeData,
                    controller: userProvider.districtController,
                    label: lang.district,
                    hintText: lang.enterDistrict,
                    options: userProvider.districtOptions,
                  ),
                  _buildEditableLocationDropdown(
                    context: context,
                    selectedThemeData: selectedThemeData,
                    controller: userProvider.cityController,
                    label: lang.taluka,
                    hintText: lang.enterTaluka,
                    options: userProvider.talukaOptions,
                  ),
                  _buildEditableLocationDropdown(
                    context: context,
                    selectedThemeData: selectedThemeData,
                    controller: userProvider.pinCodeDateController,
                    label: 'Pincode',
                    hintText: 'Enter pincode',
                    options: userProvider.pincodeOptions,
                    keyboardType: TextInputType.number,
                    isRequired: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedThemeData.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                var result = await userProvider.updateUserLocation();
                if (result['success'] == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', true);

                  CustomToast.show(context, lang.profileUpdatedSuccessfully,
                      isSuccess: true);

                  Navigator.of(context).pop();
                } else {
                  CustomToast.show(context, 'Failure: ${result['message']}',
                      isSuccess: false);
                  Navigator.of(context).pop();
                }
              },
              child: Center(
                child: Text(
                  lang.save,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showLocationPermissionPrompt(BuildContext dialogContext) {
    final selectedThemeData = Theme.of(dialogContext);

    return showDialog<bool>(
      context: dialogContext,
      builder: (permissionContext) {
        return AlertDialog(
          backgroundColor: selectedThemeData.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.my_location,
                color: selectedThemeData.primaryColor,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Use your location?'),
              ),
            ],
          ),
          content: Text(
            'Filmytell can use your current location to fill your registration address details automatically.',
            style: TextStyle(color: selectedThemeData.canvasColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(permissionContext).pop(false),
              child: Text(
                'Not now',
                style: TextStyle(color: selectedThemeData.canvasColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedThemeData.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(permissionContext).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableLocationDropdown({
    required BuildContext context,
    required ThemeData selectedThemeData,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required List<String> options,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    ValueChanged<String>? onOptionSelected,
  }) {
    final cleanOptions =
        options.where((option) => option.trim().isNotEmpty).toSet().toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selectedThemeData.canvasColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: keyboardType == TextInputType.number
                ? TextCapitalization.none
                : TextCapitalization.words,
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : [CapitalizeWordsTextInputFormatter()],
            cursorColor: selectedThemeData.primaryColor,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$hintText is required';
                    }
                    return null;
                  }
                : null,
            style: TextStyle(
              color: selectedThemeData.canvasColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: selectedThemeData.cardColor,
              hintText: hintText,
              hintStyle: TextStyle(
                color: selectedThemeData.canvasColor,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: selectedThemeData.primaryColor),
                borderRadius: BorderRadius.circular(6),
              ),
              suffixIcon: cleanOptions.isEmpty
                  ? PopupMenuButton<String>(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: selectedThemeData.primaryColor,
                      ),
                      color: selectedThemeData.cardColor,
                      enabled: false,
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Text(
                            'No options available',
                            style: TextStyle(
                              color: selectedThemeData.canvasColor
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    )
                  : PopupMenuButton<String>(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: selectedThemeData.primaryColor,
                      ),
                      color: selectedThemeData.cardColor,
                      onSelected: (value) {
                        controller.text = value;
                        if (onOptionSelected != null) {
                          onOptionSelected(value);
                        }
                      },
                      itemBuilder: (context) {
                        return cleanOptions
                            .map(
                              (option) => PopupMenuItem<String>(
                                value: option,
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: selectedThemeData.canvasColor,
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(UserProvider userProvider) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      userProvider.setDate(pickedDate);
    }
  }
}
