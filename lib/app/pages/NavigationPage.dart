import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/pages/shorts%20page/ShortsPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/pages/help%20support%20page/HelpSupportPage.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/pages/upcoming%20movies%20page/UpcomingPage.dart';
import 'package:ott/app/pages/home%20page/HomePage.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';
import 'package:ott/app/pages/series%20page/SeriesListPage.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/userProvider.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;
  String _homeContentType = "HOME";
  bool _isExitDialogOpen = false;

  // NEW
  bool _isSidebarExpanded = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int _homeIndex = 0;
  static const int _seriesIndex = 1;
  static const int _shortsIndex = 2;
  static const int _searchIndex = 3;
  static const int _watchlistIndex = 4;
  static const int _profileIndex = 5;
  static const int _upcomingIndex = 6;
  static const int _walletIndex = 7;
  //static const int _downloadsIndex = 8;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedThemeData = themeProvider.getTheme;
    final usePersistentSidebar = ResponsiveWidget.isTabletOrTv(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      body: usePersistentSidebar
          ? Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: _isSidebarExpanded ? 250 : 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.92),
                        selectedThemeData.cardColor.withValues(alpha: 0.96),
                        selectedThemeData.scaffoldBackgroundColor,
                      ],
                    ),
                    border: Border(
                      right: BorderSide(
                        color: selectedThemeData.canvasColor
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.34),
                        blurRadius: 30,
                        offset: const Offset(12, 0),
                      ),
                    ],
                  ),
                  child: FocusTraversalGroup(
                    child: _buildDrawerContent(context),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('$_currentIndex-$_homeContentType'),
                      child: _currentPage(),
                    ),
                  ),
                ),
              ],
            )
          : _currentPage(),
    );
  }

  Widget _currentPage() {
    switch (_currentIndex) {
      case _homeIndex:
        return HomePage(
          key: ValueKey(_homeContentType),
          initialSelectedType: _homeContentType,
        );

      case _seriesIndex:
        return SeriesListPage();

      case _shortsIndex:
        return ShortsPage();

      case _searchIndex:
        return SearchPage();

      case _watchlistIndex:
        return WatchlistPage();

      case _profileIndex:
        return ProfilePage();

      case _upcomingIndex:
        return UpcomingPage();

      case _walletIndex:
        return WalletPage();

      /*  case _downloadsIndex:
        return const WatchlistPage(
          initialFilter: WatchlistFilter.downloaded,
        ); */

      default:
        return HomePage(
          key: ValueKey(_homeContentType),
          initialSelectedType: _homeContentType,
        );
    }
  }

  Widget _buildDrawerContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final selectedThemeData = themeProvider.getTheme;

    final lang = AppLocalizations.of(context)!;

    final userProvider = Provider.of<UserProvider>(context);

    final profilePhoto = userProvider.userObj.profilePhoto ?? '';

    final hasProfilePhoto = profilePhoto.trim().isNotEmpty;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: selectedThemeData.scaffoldBackgroundColor
                .withValues(alpha: 0.88),
            border: Border(
              right: BorderSide(
                color: selectedThemeData.canvasColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // TOP AREA
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    children: [
                      // HAMBURGER
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            icon: Icon(
                              _isSidebarExpanded
                                  ? Icons.menu_open_rounded
                                  : Icons.menu_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = !_isSidebarExpanded;
                              });
                            },
                          ),
                        ),
                      ),

                      // LOGO
                      Container(
                        width: double.infinity,
                        height: 90,
                        alignment: Alignment.center,
                        child: Hero(
                          tag: "logo",
                          child: Image.asset(
                            ImageConstant.inAppLogo,
                            width: _isSidebarExpanded ? 140 : 140,
                            height: _isSidebarExpanded ? 200 : 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // PROFILE SECTION
                if (_isSidebarExpanded)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: selectedThemeData.primaryColor
                                .withValues(alpha: 0.22),
                            backgroundImage: hasProfilePhoto
                                ? NetworkImage(profilePhoto)
                                : AssetImage(ImageConstant.profile)
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${userProvider.userObj.firstName ?? ''} ${userProvider.userObj.lastName ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selectedThemeData.canvasColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProvider.userObj.emailId ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selectedThemeData.canvasColor
                                        .withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // MENU LIST
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      _buildDrawerTile(
                        context,
                        index: _homeIndex,
                        icon: Icons.home,
                        title: lang.home,
                        homeContentType: "HOME",
                      ),
                      _buildDrawerTile(
                        context,
                        index: _seriesIndex,
                        icon: Icons.video_library,
                        title: lang.series,
                      ),
                      _buildDrawerTile(
                        context,
                        index: _searchIndex,
                        icon: Icons.search,
                        title: lang.search,
                      ),
                      _buildDrawerTile(
                        context,
                        index: _watchlistIndex,
                        icon: Icons.playlist_play_rounded,
                        title: "My List",
                      ),
                      _buildDrawerTile(
                        context,
                        index: _profileIndex,
                        icon: Icons.person,
                        title: lang.profile,
                      ),
                    ],
                  ),
                ),

                // BOTTOM ACTIONS
                Column(
                  children: [
                    _buildDrawerAction(
                      context,
                      icon: Icons.logout_rounded,
                      title: lang.logout,
                      onTap: _logout,
                      destructive: true,
                    ),
                    if (_isSidebarExpanded)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                          top: 6,
                        ),
                        child: Text(
                          "Version ${AppConstant.appVersion}",
                          style: TextStyle(
                            color: selectedThemeData.canvasColor
                                .withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    String? homeContentType,
  }) {
    final selectedThemeData = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).getTheme;

    final isSelected = index == _currentIndex &&
        (homeContentType == null || homeContentType == _homeContentType);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (title == "Profile") {
              Provider.of<UserProvider>(
                context,
                listen: false,
              ).setValue();
            }

            _navigateTo(
              index,
              homeContentType: homeContentType,
            );
          },
          child: OttTvFocus(
            onTap: () {
              if (title == "Profile") {
                Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).setValue();
              }

              _navigateTo(
                index,
                homeContentType: homeContentType,
              );
            },
            borderRadius: BorderRadius.circular(16),
            scale: 1.04,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 220,
              ),
              curve: Curves.easeOutCubic,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedThemeData.primaryColor.withValues(
                        alpha: 0.18,
                      )
                    : Colors.white.withValues(
                        alpha: 0.02,
                      ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: isSelected
                      ? selectedThemeData.primaryColor
                      : Colors.white.withValues(
                          alpha: 0.05,
                        ),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedThemeData.primaryColor.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 18,
                          offset: const Offset(
                            0,
                            8,
                          ),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: _isSidebarExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (_isSidebarExpanded)
                    const SizedBox(
                      width: 14,
                    ),
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? selectedThemeData.primaryColor
                        : selectedThemeData.canvasColor,
                  ),
                  if (_isSidebarExpanded)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selectedThemeData.canvasColor,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  if (_isSidebarExpanded && isSelected)
                    Container(
                      width: 4,
                      height: 28,
                      margin: const EdgeInsets.only(
                        right: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selectedThemeData.primaryColor,
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  if (!_isSidebarExpanded)
                    const SizedBox(
                      width: 14,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final theme = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).getTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      child: OttTvFocus(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        scale: 1.03,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.02),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              const SizedBox(width: 14),
              Icon(
                icon,
                color: destructive ? theme.primaryColor : theme.canvasColor,
              ),
              if (_isSidebarExpanded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: destructive
                            ? theme.primaryColor
                            : theme.canvasColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(
    int index, {
    String? homeContentType,
  }) {
    setState(() {
      _currentIndex = index;

      if (homeContentType != null) {
        _homeContentType = homeContentType;
      }
    });

    // Close drawer safely for mobile
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    final localSharePreferences = LocalSharePreferences();
    localSharePreferences.setBool(
      SharedPreferencesConstant.isUserLoggedIn,
      false,
    );
    localSharePreferences.setString(
      SharedPreferencesConstant.currentUser,
      '',
    );

    if (!mounted) return;
    Provider.of<DashboardProvider>(context, listen: false).clear();
    Provider.of<BookmarkProvider>(context, listen: false).clear();
    Provider.of<UserProvider>(context, listen: false).clear();
    Provider.of<UserProvider>(context, listen: false).disposeData();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginCard()),
    );
  }
}
