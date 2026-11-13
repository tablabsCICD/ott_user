import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/utils/image_url_utils.dart';
import 'package:ott/app/pages/help%20support%20page/HelpSupportPage.dart';
import 'package:ott/app/pages/profile%20page/component/change_language.dart';
import 'package:ott/app/pages/shorts%20page/ShortsPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/pages/upcoming%20movies%20page/UpcomingPage.dart';
import 'package:ott/app/pages/home%20page/HomePage.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';

import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/feature_tour.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/route/routes/web_navigation_routes.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../provider/userProvider.dart';
import 'package:ott/app/pages/sign in page/LoginCard.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({
    super.key,
    this.initialIndex = 0,
    this.initialHomeContentType = 'MOVIE',
    this.startAppTourOnHome = false,
  });

  final int initialIndex;
  final String initialHomeContentType;
  final bool startAppTourOnHome;

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late int _currentIndex;
  bool _isExitDialogOpen = false;
  bool _isSidebarExpanded = false;
  Widget? _profileDetail;
  String? _profileDetailTitle;
  late String _homeContentType;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildCurrentPage([int? pageIndex]) {
    switch (pageIndex ?? _currentIndex) {
      case 0:
        return HomePage(
          initialSelectedType: _homeContentType,
        );
      case 1:
        return const HomePage(
          initialSelectedType: 'SHORT_FILM',
          lockContentType: true,
        );
      case 2:
        return ShortsPage();
      case 3:
        return SearchPage();
      case 4:
        return WatchlistPage();
      case 5:
        final detail = _profileDetail;
        if (detail != null) {
          return ProfileDetailShell(
            title: _profileDetailTitle ?? 'Profile',
            onBack: _closeProfileDetail,
            child: detail,
          );
        }
        return ProfilePage(onOpenDetail: _openProfileDetail);
      case 6:
        return UpcomingPage();
      case 7:
        return WalletPage();
      case 8:
        return const WatchlistPage(initialFilter: WatchlistFilter.downloaded);
      case 9:
        return const ChangeLanguage();
      case 10:
        return const HelpSupportPage();

      default:
        return HomePage(
          initialSelectedType: _homeContentType,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _homeContentType = widget.initialHomeContentType;
    _logWebNavigation(
      'NavigationPage init index=$_currentIndex homeContentType=$_homeContentType',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DeepLinkService.instance.consumePendingNavigation();
      final tourProvider = context.read<OnboardingTourProvider>();
      if (widget.startAppTourOnHome) {
        tourProvider.replayTour(context: context);
      } else {
        unawaited(tourProvider.startFirstLaunchTour(context: context));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedThemeData = themeProvider.getTheme;
    final isMobile = ResponsiveWidget.isMobile(context);
    final isTvLayout = ResponsiveWidget.isTabletOrTv(context);
    final lang = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final profilePhotoUrl =
        normalizeNetworkImageUrl(userProvider.userObj.profilePhoto);
    final mobilePageIndices = [0, 1, 3, 4, 5];
    final mobileCurrentIndex = mobilePageIndices.contains(_currentIndex)
        ? mobilePageIndices.indexOf(_currentIndex)
        : 0;
    final visiblePageIndex =
        isMobile && !mobilePageIndices.contains(_currentIndex)
            ? 0
            : _currentIndex;

    return PopScope(
      canPop: kIsWeb && _profileDetail == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: selectedThemeData.scaffoldBackgroundColor,
        body: Stack(
          children: [
            isTvLayout && ResponsiveWidget.isAndroidTv(context)
                ? _buildTvShell(context, selectedThemeData, visiblePageIndex)
                : isTvLayout
                ? Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: _isSidebarExpanded ? 250 : 112,
                        color: selectedThemeData.cardColor,
                        child: MouseRegion(
                          onEnter: (_) => _setSidebarExpanded(true),
                          onExit: (_) => _setSidebarExpanded(false),
                          child: Focus(
                            canRequestFocus: false,
                            onFocusChange: (hasScopeFocus) {
                              _setSidebarExpanded(hasScopeFocus);
                            },
                            child: _buildDrawerContent(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildCurrentPage(visiblePageIndex),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      _buildCurrentPage(visiblePageIndex),
                    ],
                  ),
          ],
        ),
        drawer: null,
        bottomNavigationBar: isMobile
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: mobileCurrentIndex,
                onTap: (index) => setState(() {
                  _currentIndex = mobilePageIndices[index];
                  if (_currentIndex == 0) {
                    _homeContentType = "MOVIE";
                  }
                }),
                backgroundColor: selectedThemeData.scaffoldBackgroundColor,
                selectedItemColor: selectedThemeData.primaryColor,
                unselectedItemColor: selectedThemeData.canvasColor,
                selectedIconTheme: IconThemeData(
                  color: selectedThemeData.primaryColor,
                  size: 26,
                ),
                unselectedIconTheme: IconThemeData(
                  color: selectedThemeData.canvasColor.withOpacity(0.76),
                  size: 24,
                ),
                showSelectedLabels: true,
                showUnselectedLabels: false,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: lang.home,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library),
                    label: 'Short Film',
                  ),
                  /*   BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle),
                    label: lang.minSeries,
                  ), */
                  BottomNavigationBarItem(
                    icon: FeatureTourTarget(
                      id: FeatureTourStepId.search,
                      child: Icon(Icons.search),
                    ),
                    label: lang.search,
                  ),
                  BottomNavigationBarItem(
                    icon: FeatureTourTarget(
                      id: FeatureTourStepId.watchlist,
                      child: Icon(Icons.movie),
                    ),
                    label: lang.watchlist,
                  ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.upcoming_outlined),
                  //   label: lang.upcoming,
                  // ),
                  BottomNavigationBarItem(
                    icon: FeatureTourTarget(
                      id: FeatureTourStepId.profile,
                      child: Icon(Icons.person),
                    ),
                    activeIcon: Hero(
                      tag: 'profile_nav',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedThemeData.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              selectedThemeData.primaryColor.withOpacity(0.5),
                          child: ClipOval(
                            child: profilePhotoUrl.isEmpty
                                ? Image.asset(
                                    ImageConstant.profile,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    profilePhotoUrl,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      ImageConstant.profile,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    label: lang.profile,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return;
    }

    if (_currentIndex == 5 && _profileDetail != null) {
      _closeProfileDetail();
      return;
    }

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    if (_isExitDialogOpen) return;
    _isExitDialogOpen = true;
    final shouldExit = await _showExitConfirmationDialog();
    _isExitDialogOpen = false;

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  void _openProfileDetail(String title, Widget page) {
    setState(() {
      _currentIndex = 5;
      _profileDetailTitle = title;
      _profileDetail = page;
    });
    if (kIsWeb) {
      final slug = title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      SystemNavigator.routeInformationUpdated(
        uri: Uri(path: '/profile/$slug'),
        replace: false,
      );
    }
  }

  void _closeProfileDetail() {
    if (!mounted || _profileDetail == null) return;
    setState(() {
      _profileDetail = null;
      _profileDetailTitle = null;
    });
    if (kIsWeb) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri(path: WebNavigationRoutes.profile.path),
        replace: true,
      );
    }
  }

  Future<bool?> _showExitConfirmationDialog() {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Close app?',
            style: TextStyle(
              color: theme.canvasColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to close the app?',
            style: TextStyle(
              color: theme.canvasColor.withOpacity(0.75),
            ),
          ),
          actions: [
            TextButton(
              autofocus: ResponsiveWidget.isTv(context),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.canvasColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    String? homeContentType,
    VoidCallback? onTap,
  }) {
    final selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: false).getTheme;
    final isSelected = index == _currentIndex &&
        (homeContentType == null || homeContentType == _homeContentType);
    void handleTap() {
      if (onTap != null) {
        onTap();
        return;
      }
      if (title == "Profile") {
        Provider.of<UserProvider>(context, listen: false).setValue();
      }
      _navigateTo(index, homeContentType: homeContentType);
    }

    final tile = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          minLeadingWidth: 24,
          horizontalTitleGap: 14,
          selected: isSelected,
          selectedTileColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          leading: Icon(
            icon,
            color: isSelected
                ? selectedThemeData.primaryColor
                : selectedThemeData.canvasColor,
          ),
          title: _isSidebarExpanded
              ? Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? selectedThemeData.primaryColor
                        : selectedThemeData.canvasColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                )
              : null,
          onTap: ResponsiveWidget.isMobile(context) ? handleTap : null,
        ),
      ),
    );

    if (ResponsiveWidget.isMobile(context)) return tile;

    return OttTvFocus(
      onTap: handleTap,
      onFocusChange: (focused) {
        if (focused) {
          _setSidebarExpanded(true);
        }
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          final moved = node.focusInDirection(TraversalDirection.right);
          if (moved) return KeyEventResult.handled;
          final nextMoved = node.nextFocus();
          if (nextMoved) return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      borderRadius: 14,
      scale: 1.02,
      child: tile,
    );
  }

  void _navigateTo(int index, {String? homeContentType}) {
    final nextHomeContentType = homeContentType ?? _homeContentType;
    if (kIsWeb) {
      final route = WebNavigationRoutes.fromIndex(
        index,
        homeContentType: nextHomeContentType,
      );
      _logWebNavigation(
        'Drawer requested path=${route.path} index=$index homeContentType=$nextHomeContentType',
      );
      Navigator.of(context).pushNamed(route.path);
      return;
    }

    setState(() {
      if (index != 5) {
        _profileDetail = null;
        _profileDetailTitle = null;
      }
      _currentIndex = index;
      if (homeContentType != null) {
        _homeContentType = homeContentType;
      }
    });
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Close the drawer safely
    }
  }

  void _logWebNavigation(String message) {
    if (!kIsWeb || !kDebugMode) return;
    developer.log(message, name: 'WebNavigation');
  }

  void _setSidebarExpanded(bool expanded) {
    if (_isSidebarExpanded == expanded) return;
    setState(() => _isSidebarExpanded = expanded);
  }

  Widget _buildDrawerContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedThemeData = themeProvider.getTheme;
    final isDark = selectedThemeData.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;
    final hideTabletLogo = ResponsiveWidget.isTablet(context);
    final logoSize = _isSidebarExpanded ? 132.0 : 82.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: hideTabletLogo ? 96 : 170,
          child: DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: hideTabletLogo
                  ? Colors.transparent
                  : selectedThemeData.primaryColor,
            ),
            child: hideTabletLogo
                ? const SizedBox.shrink()
                : Stack(
                    children: [
                      Center(
                        child: Hero(
                          tag: "logo",
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: SizedBox(
                              height: logoSize,
                              width: logoSize,
                              child: Image.asset(
                                ImageConstant.logo,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_isSidebarExpanded)
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: selectedThemeData.primaryColor,
                  thickness: 1,
                ),
              ),
              IconButton(
                tooltip: "Toggle Theme",
                icon: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: selectedThemeData.canvasColor,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
        _buildDrawerTile(
          context,
          index: 0,
          icon: Icons.home,
          title: lang.home,
          homeContentType: "MOVIE",
        ),
        _buildDrawerTile(context,
            index: 1, icon: Icons.video_library, title: lang.series),

        /*    _buildDrawerTile(context,
            index: 2, icon: Icons.play_circle_fill_sharp, title: 'Mini Series'), */
        _buildDrawerTile(context,
            index: 3, icon: Icons.search, title: lang.search),
        _buildDrawerTile(context,
            index: 4, icon: Icons.movie, title: lang.watchlist),
        _buildDrawerTile(context,
            index: 7,
            icon: Icons.account_balance_wallet,
            title: lang.wallet),
        _buildDrawerTile(context,
            index: 8, icon: Icons.download_rounded, title: "Downloads"),
        _buildDrawerTile(context,
            index: 5, icon: Icons.person, title: lang.profile),
        _buildDrawerTile(context,
            index: 9, icon: Icons.settings, title: "Settings"),
        _buildDrawerTile(context,
            index: 10, icon: Icons.support_agent_sharp, title: lang.help),
        Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final isLoggedIn = userProvider.userObj.id != null &&
                (userProvider.userObj.id ?? 0) > 0;
            if (isLoggedIn) {
              return _buildDrawerTile(
                context,
                index: -1,
                icon: Icons.logout,
                title: lang.logout,
                onTap: _showLogoutDialog,
              );
            }
            return _buildDrawerTile(
              context,
              index: -1,
              icon: Icons.login,
              title: lang.login,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginCard()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // ANDROID TV SIDEBAR (compact rail that expands over the content)
  // ===========================================================================
  static const double _tvRailWidth = 68;
  static const double _tvRailExpandedWidth = 208;

  Widget _buildTvShell(BuildContext context, ThemeData theme, int pageIndex) {
    return Stack(
      children: [
        // Content always reserves only the collapsed rail width, so the
        // poster rows never re-layout when the sidebar expands.
        Padding(
          padding: const EdgeInsets.only(left: _tvRailWidth),
          child: _buildCurrentPage(pageIndex),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: _isSidebarExpanded ? _tvRailExpandedWidth : _tvRailWidth,
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: _isSidebarExpanded
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 32,
                        offset: const Offset(8, 0),
                      ),
                    ]
                  : null,
            ),
            child: MouseRegion(
              onEnter: (_) => _setSidebarExpanded(true),
              onExit: (_) => _setSidebarExpanded(false),
              child: Focus(
                canRequestFocus: false,
                onFocusChange: _setSidebarExpanded,
                child: _buildTvDrawerContent(context, theme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTvDrawerContent(BuildContext context, ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    Widget tile({
      required int index,
      required IconData icon,
      required String title,
      String? homeContentType,
      VoidCallback? onTap,
    }) {
      final isSelected = index == _currentIndex &&
          (homeContentType == null || homeContentType == _homeContentType);
      return _TvSidebarTile(
        icon: icon,
        title: title,
        selected: isSelected,
        expanded: _isSidebarExpanded,
        onFocused: () => _setSidebarExpanded(true),
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }
          if (index == 5) {
            Provider.of<UserProvider>(context, listen: false).setValue();
          }
          _navigateTo(index, homeContentType: homeContentType);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand logo
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Hero(
              tag: "logo",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  ImageConstant.logo,
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          // All items fit on a 1080p TV; scrolling is only a safety net for
          // unusually small screens.
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              tile(
                index: 0,
                icon: Icons.home_rounded,
                title: lang.home,
                homeContentType: "MOVIE",
              ),
              tile(index: 1, icon: Icons.video_library, title: lang.series),
              tile(index: 3, icon: Icons.search, title: lang.search),
              tile(index: 4, icon: Icons.movie, title: lang.watchlist),
              tile(
                index: 7,
                icon: Icons.account_balance_wallet,
                title: lang.wallet,
              ),
              tile(
                index: 8,
                icon: Icons.download_rounded,
                title: "Downloads",
              ),
              tile(index: 5, icon: Icons.person, title: lang.profile),
              tile(index: 9, icon: Icons.settings, title: "Settings"),
              tile(
                index: 10,
                icon: Icons.support_agent_sharp,
                title: lang.help,
              ),
              tile(
                index: -2,
                icon: isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round,
                title: isDark ? "Light Theme" : "Dark Theme",
                onTap: themeProvider.toggleTheme,
              ),
              tile(
                index: -1,
                icon: Icons.logout,
                title: lang.logout,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Are you sure you want Logout?',
            style: TextStyle(
              color: theme.canvasColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            OttTvFocus(
              autofocus: true,
              borderRadius: 8,
              onTap: () => Navigator.pop(dialogContext, false),
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  lang.cancel,
                  style: TextStyle(color: theme.canvasColor),
                ),
              ),
            ),
            OttTvFocus(
              borderRadius: 8,
              onTap: () async {
                Navigator.pop(dialogContext, true);
                await _logout();
              },
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext, true);
                  await _logout();
                },
                child: Text(lang.logout),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await SessionManager.instance.performLogout(context);
  }
}

/// Compact sidebar item for Android TV: icon-only when collapsed, icon + label
/// when expanded, with a clearly visible focus state.
class _TvSidebarTile extends StatefulWidget {
  const _TvSidebarTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.expanded,
    required this.onTap,
    required this.onFocused,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onFocused;

  @override
  State<_TvSidebarTile> createState() => _TvSidebarTileState();
}

class _TvSidebarTileState extends State<_TvSidebarTile> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'tv-sidebar-tile');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: OttTvFocus(
        focusNode: _focusNode,
        borderRadius: 10,
        scale: 1.0,
        semanticLabel: widget.title,
        onTap: widget.onTap,
        onFocusChange: (focused) {
          if (focused) widget.onFocused();
        },
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            final moved = node.focusInDirection(TraversalDirection.right);
            if (moved) return KeyEventResult.handled;
            final nextMoved = node.nextFocus();
            if (nextMoved) return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ListenableBuilder(
          listenable: _focusNode,
          builder: (context, _) {
            final focused = _focusNode.hasFocus;
            final color = focused
                ? Colors.white
                : widget.selected
                    ? theme.primaryColor
                    : theme.canvasColor.withValues(alpha: 0.78);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: focused
                    ? theme.primaryColor
                    : widget.selected
                        ? theme.primaryColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: color),
                  if (widget.expanded) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: widget.selected || focused
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
