import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/shorts%20page/ShortsPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/pages/upcoming%20movies%20page/UpcomingPage.dart';
import 'package:ott/app/pages/home%20page/HomePage.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../provider/userProvider.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    HomePage(),
    ShortsPage(),
    SearchPage(),
    WatchlistPage(),
    ProfilePage(),
    UpcomingPage(),
    WalletPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedThemeData = themeProvider.getTheme;
    final isMobile = ResponsiveWidget.isMobile(context);
    final isDesktop = ResponsiveWidget.isDesktop(context);
    final lang = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 250,
                  color: selectedThemeData.cardColor,
                  child: _buildDrawerContent(context),
                ),
                Expanded(
                  child: _pages[_currentIndex],
                ),
              ],
            )
          : Stack(
              children: [
                _pages[_currentIndex],
                if (!isMobile)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      icon: Icon(
                        Icons.menu,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
      drawer: isMobile
          ? null
          : Drawer(
              child: _buildDrawerContent(context),
            ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: selectedThemeData.scaffoldBackgroundColor,
              selectedItemColor: selectedThemeData.primaryColor,
              unselectedItemColor: selectedThemeData.canvasColor,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: lang.home,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle),
                  label: 'Shorts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: lang.search,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.movie),
                  label: lang.watchlist,
                ),
                // BottomNavigationBarItem(
                //   icon: Icon(Icons.upcoming_outlined),
                //   label: lang.upcoming,
                // ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  activeIcon: Hero(
                    tag: 'profile',
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
                        foregroundImage:
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
                  label: lang.profile,
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
  }) {
    final selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: false).getTheme;
    final isSelected = index == _currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? selectedThemeData.primaryColor
              : selectedThemeData.canvasColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? selectedThemeData.primaryColor
                : selectedThemeData.canvasColor,
          ),
        ),
        onTap: () {
          if (title == "Profile") {
            Provider.of<UserProvider>(context, listen: false).setValue();
          }
          _navigateTo(index);
        },
      ),
    );
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Close the drawer safely
    }
  }

  Widget _buildDrawerContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedThemeData = themeProvider.getTheme;
    final isDark = selectedThemeData.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: selectedThemeData.primaryColor,
          ),
          child: Hero(
            tag: "logo",
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(25),
              child: Image.asset(
                ImageConstant.logo2,
              ),
            ),
          ),
        ),
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
        _buildDrawerTile(context, index: 0, icon: Icons.home, title: lang.home),
        _buildDrawerTile(context,
            index: 1, icon: Icons.play_circle_fill_sharp, title: 'Shorts'),
        _buildDrawerTile(context,
            index: 2, icon: Icons.search, title: lang.search),
        _buildDrawerTile(context,
            index: 3, icon: Icons.movie, title: lang.watchlist),
        _buildDrawerTile(context,
            index: 5, icon: Icons.upcoming, title: lang.upcoming),
        _buildDrawerTile(context,
            index: 6, icon: Icons.account_balance_wallet, title: lang.wallet),
        _buildDrawerTile(context,
            index: 4, icon: Icons.person, title: lang.profile),
      ],
    );
  }
}
