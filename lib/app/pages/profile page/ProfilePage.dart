import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/services/legal_document_service.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/utils/image_url_utils.dart';
import 'package:ott/app/core/utils/legal_document_url_utils.dart';
import 'package:ott/app/pages/bookmarks%20page/bookmark_page.dart';
import 'package:ott/app/pages/gifted%20movies%20page/GiftedMoviesPage.dart';
import 'package:ott/app/pages/help%20support%20page/HelpSupportPage.dart';
import 'package:ott/app/pages/device%20management%20page/DeviceManagementPage.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';
import 'package:ott/app/pages/profile%20page/component/EditProfilePage.dart';
import 'package:ott/app/pages/profile%20page/component/account_details_page.dart';
import 'package:ott/app/pages/profile%20page/PurchaseHistoryPage.dart';
import 'package:ott/app/pages/profile%20page/component/about_filmytell_dialog.dart';
import 'package:ott/app/pages/profile%20page/component/change_language.dart';
import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';
import 'package:ott/app/pages/upcoming%20movies%20page/UpcomingPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/purchase_history_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/shimmer%20loader/profile_shimmer.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/pages/profile page/component/in_app_privacy_policy_page.dart';
import 'package:ott/app/pages/profile page/component/in_app_terms_conditions_page.dart';
import 'package:ott/app/pages/profile page/component/in_app_licenses_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/presentation/web_landing/utils/post_logout_navigation.dart';
import '../../core/utils/sharepreferences.dart';
import '../../provider/userProvider.dart';
import '../../widgets/show_toast.dart';
import 'package:ott/app/pages/sign in page/LoginCard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onOpenDetail});

  final void Function(String title, Widget page)? onOpenDetail;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Android TV lays the app out on a 960x540 canvas; the phone/web sizes
  // below would fill most of the screen there, so TV uses a compact scale.
  bool get _isTv => ResponsiveWidget.isAndroidTv(context);

  void _openDetail(String title, Widget page) {
    final openInShell = widget.onOpenDetail;
    if (openInShell != null) {
      openInShell(title, page);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _fetchUserData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.hydrateFromCache();
    if (!mounted) return;

    if (user != null) {
      await userProvider.getUserById(user.id ?? 0);
      if (!mounted) return;
    }
    await Provider.of<WalletProvider>(context, listen: false).getBalance();
  }

  Future<void> _openPrivacyPolicy() async {
    if (FlavorConfig.current.isJio || FlavorConfig.current.isTv) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InAppPrivacyPolicyPage()),
      );
      return;
    }
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final opened = await launchUrl(
        legalDocumentViewUri(documentUrls.privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InAppPrivacyPolicyPage()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InAppPrivacyPolicyPage()),
      );
    }
  }

  Future<void> _openTerms() async {
    if (FlavorConfig.current.isJio || FlavorConfig.current.isTv) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InAppTermsConditionsPage()),
      );
      return;
    }
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final opened = await launchUrl(
        legalDocumentViewUri(documentUrls.termsAndConditionsUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InAppTermsConditionsPage()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InAppTermsConditionsPage()),
      );
    }
  }

  Future<void> _openRateUs() async {
    if (FlavorConfig.current.isJio) {
      CustomToast.show(
        context,
        'Thank you for using Filmytell on Jio STB!',
        isSuccess: true,
      );
      return;
    }
    try {
      bool launched = false;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final marketUri = Uri.parse('market://details?id=com.filmytell.ott');
        launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        launched = await launchUrl(
          Uri.parse(AppConstant.playStoreLink),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && mounted) {
        CustomToast.show(
          context,
          'Unable to open rating page right now.',
          isSuccess: false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'Unable to open rating page right now.',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var walletProvider = Provider.of<WalletProvider>(context);
    double walletBalance = walletProvider.walletBalance;
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;

    final sections = _profileSections(lang, walletBalance);

    // Android TV: two-column settings layout sized for the 540 px canvas.
    if (_isTv) {
      return _buildTv(context, theme, lang, sections);
    }

    return Scaffold(
      body: isLoading
          ? ProfileShimmer()
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, selectedThemeData),
                SliverToBoxAdapter(
                  child: Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                    return SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            for (final section in sections)
                              profileCard(
                                section.title,
                                [
                                  for (final entry in section.entries)
                                    ProfileOption(
                                      icon: entry.icon,
                                      title: entry.title,
                                      balance: entry.balance,
                                      onTap: entry.onTap,
                                    ),
                                ],
                              ),
                            SizedBox(height: _isTv ? 32 : 250),
                            Opacity(
                              opacity: 0.4,
                              child: CircleAvatar(
                                radius: _isTv ? 14 : null,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                foregroundColor: theme.scaffoldBackgroundColor,
                                foregroundImage: AssetImage(ImageConstant.logo),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const SizedBox(height: 2),
                            Text(
                              "Version - ${AppConstant.appVersion}",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: _isTv ? 10 : 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Copyright Filmytell - All Rights Reserved.",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
    );
  }

  /// Profile menu shared by the phone/web list and the Android TV layout,
  /// so both always offer the same entries with the same actions.
  List<_ProfileSection> _profileSections(
    AppLocalizations lang,
    double walletBalance,
  ) {
    return [
      _ProfileSection(lang.myCredits, [
        _ProfileEntry(
          icon: Icons.account_balance_wallet,
          title: lang.wallet,
          balance: walletBalance,
          onTap: () => _openDetail(lang.wallet, WalletPage()),
        ),
      ]),
      _ProfileSection(lang.features, [
        _ProfileEntry(
          icon: Icons.bookmark,
          title: "Bookmarks",
          onTap: () => _openDetail('Bookmarks', BookmarkPage()),
        ),
        _ProfileEntry(
          icon: Icons.history,
          title: lang.watchlist,
          onTap: () => _openDetail(lang.watchlist, const WatchlistPage()),
        ),
        _ProfileEntry(
          icon: Icons.receipt_long,
          title: lang.purchaseHistory,
          onTap: () => _openDetail(
            lang.purchaseHistory,
            ChangeNotifierProvider(
              create: (_) => PurchaseHistoryProvider(),
              child: const PurchaseHistoryPage(),
            ),
          ),
        ),
        _ProfileEntry(
          icon: Icons.download_rounded,
          title: lang.downloads,
          onTap: () => _openDetail(
            lang.downloads,
            const WatchlistPage(
              initialFilter: WatchlistFilter.downloaded,
            ),
          ),
        ),
        _ProfileEntry(
          icon: Icons.upcoming,
          title: lang.upcoming,
          onTap: () => _openDetail(lang.upcoming, UpcomingPage()),
        ),
        _ProfileEntry(
          icon: Icons.notifications,
          title: lang.notification,
          onTap: () =>
              _openDetail(lang.notification, const NotificationPage()),
        ),
        _ProfileEntry(
          icon: Icons.language_sharp,
          title: lang.selectPreferredLanguage,
          onTap: () {
            _openDetail(lang.selectPreferredLanguage, const ChangeLanguage());
          },
        ),
        _ProfileEntry(
          icon: Icons.manage_accounts_outlined,
          title: lang.accountDetails,
          onTap: () {
            _openDetail(lang.accountDetails, const AccountDetailsPage());
          },
        ),
        _ProfileEntry(
          icon: Icons.devices_other_outlined,
          title: 'Registered Devices',
          onTap: () {
            _openDetail('Registered Devices', const DeviceManagementPage());
          },
        ),
      ]),
      _ProfileSection(lang.gifts, [
        _ProfileEntry(
          icon: Icons.history_sharp,
          title: lang.giftedByYou,
          onTap: () => _openDetail(lang.giftedByYou, GiftedMoviesPage()),
        ),
        _ProfileEntry(
          icon: LucideIcons.gift,
          title: lang.claimGiftCard,
          onTap: () {
            showGiftClaimDialog(context);
          },
        ),
      ]),
      _ProfileSection(lang.feedbackAndInformation, [
        _ProfileEntry(
          icon: Icons.support_agent_sharp,
          title: lang.help,
          onTap: () => _openDetail(lang.help, const HelpSupportPage()),
        ),
        _ProfileEntry(
          icon: Icons.tour_rounded,
          title: 'App Tour',
          onTap: _startAppTour,
        ),
        _ProfileEntry(
          icon: Icons.file_copy,
          title: "Privacy Policy",
          onTap: () {
            _openPrivacyPolicy();
          },
        ),
        _ProfileEntry(
          icon: Icons.file_copy,
          title: "Terms & Condition",
          onTap: () {
            _openTerms();
          },
        ),
        _ProfileEntry(
          icon: Icons.info,
          title: lang.aboutFilmytell,
          onTap: () {
            _openDetail(lang.aboutFilmytell, const AboutFilmytellScreen());
          },
        ),
        _ProfileEntry(
          icon: Icons.star,
          title: lang.rateUs,
          onTap: _openRateUs,
        ),
      ]),
      _ProfileSection('', [
        _ProfileEntry(
          icon: Icons.logout,
          title: lang.logout,
          onTap: () {
            _showCupertinoDialog(context);
          },
        ),
      ]),
    ];
  }

  void _startAppTour() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const NavigationPage(
          initialIndex: 0,
          initialHomeContentType: 'MOVIE',
          startAppTourOnHome: true,
        ),
      ),
    );
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );
  }

  void _toggleTheme() {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  // ===========================================================================
  // ANDROID TV
  // ===========================================================================

  /// Opens the locale menu of the TV language selector from the remote.
  final GlobalKey<PopupMenuButtonState<String>> _tvLanguageMenuKey =
      GlobalKey<PopupMenuButtonState<String>>();

  Widget _buildTv(
    BuildContext context,
    ThemeData theme,
    AppLocalizations lang,
    List<_ProfileSection> sections,
  ) {
    // Opened as its own route there is no sidebar to leave through, so the
    // header shows a back button (same rule as the phone app bar).
    final showBack =
        widget.onOpenDetail == null && Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvDetailHeader(title: lang.profile, showBack: showBack),
          Expanded(
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.primaryColor,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TvDesign.pageGutter,
                      0,
                      TvDesign.pageGutter,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: _buildTvSummaryColumn(theme, lang),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTvSettingsList(sections)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvSummaryColumn(ThemeData theme, AppLocalizations lang) {
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.userObj;
        final first = (user.firstName ?? '').trim();
        final last = (user.lastName ?? '').trim();
        final fullName = '$first $last'.trim();
        final email = (user.emailId ?? '').trim();
        final mobile = (user.mobileNumber ?? '').trim();
        final profilePhotoUrl = normalizeNetworkImageUrl(user.profilePhoto);
        const avatarSize = 56.0;

        Widget avatarFallback() => Image.asset(
              ImageConstant.profile,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TvPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: "profile",
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.scaffoldBackgroundColor,
                                  border: Border.all(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: profilePhotoUrl.isEmpty
                                      ? avatarFallback()
                                      : Image.network(
                                          profilePhotoUrl,
                                          width: avatarSize,
                                          height: avatarSize,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              avatarFallback(),
                                        ),
                                ),
                              ),
                              if (user.verified ?? false)
                                Positioned(
                                  bottom: -1,
                                  right: -1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.cardColor,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName.isNotEmpty ? fullName : 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.canvasColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TvDesign.caption(theme),
                                ),
                              ],
                              if (mobile.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  mobile,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TvDesign.caption(theme),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TvCompactButton(
                      label: lang.editProfile,
                      icon: Icons.edit_outlined,
                      expand: true,
                      onPressed: _openEditProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TvPanel(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: OttTvFocus(
                        borderRadius: 8,
                        scale: 1.03,
                        semanticLabel: lang.translate,
                        onTap: () =>
                            _tvLanguageMenuKey.currentState?.showButtonMenu(),
                        child: LanguageDropdown(
                          menuKey: _tvLanguageMenuKey,
                          showSelectedLabel: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          // Fills the slot so the focus ring and the
                          // select box line up.
                          constraints: const BoxConstraints(
                            minHeight: 32,
                            minWidth: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tvIconAction(
                      theme,
                      icon: isDark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                      label: "Toggle Theme",
                      onTap: _toggleTheme,
                    ),
                    const SizedBox(width: 8),
                    _tvIconAction(
                      theme,
                      icon: Icons.logout,
                      label: "Logout",
                      onTap: () => _showCupertinoDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      foregroundColor: theme.scaffoldBackgroundColor,
                      foregroundImage: AssetImage(ImageConstant.logo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Version - ${AppConstant.appVersion}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const Text(
                          "Copyright Filmytell - All Rights Reserved.",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tvIconAction(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OttTvFocus(
      borderRadius: 8,
      scale: 1.06,
      semanticLabel: label,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.canvasColor.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(icon, size: 18, color: theme.canvasColor),
        ),
      ),
    );
  }

  Widget _buildTvSettingsList(List<_ProfileSection> sections) {
    // The first row takes the initial focus so the remote never starts with
    // nothing selected.
    var isFirstRow = true;
    final children = <Widget>[];
    for (final section in sections) {
      final rows = <Widget>[];
      for (final entry in section.entries) {
        rows.add(_TvProfileRow(entry: entry, autofocus: isFirstRow));
        isFirstRow = false;
      }
      if (section.title.isNotEmpty) {
        children.add(
          TvSectionHeader(
            section.title,
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
          ),
        );
      }
      children.add(
        TvPanel(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(children: rows),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: children,
    );
  }

  void _showCupertinoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    if (ResponsiveWidget.isTabletOrTv(context)) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
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
              onTap: () => Navigator.of(dialogContext).pop(),
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  lang.cancel,
                  style: TextStyle(color: theme.canvasColor),
                ),
              ),
            ),
            OttTvFocus(
              borderRadius: 8,
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await SessionManager.instance.performLogout(context);
              },
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await SessionManager.instance.performLogout(context);
                },
                child: Text(lang.logout),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Are you sure you want Logout?'),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.canvasColor),
            child: Text(lang.cancel),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.primaryColor),
            child: Text(lang.logout),
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              await SessionManager.instance.logoutFromServer();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              LocalSharePreferences localSharePreferences =
                  LocalSharePreferences();
              await localSharePreferences.clearSession();

              // clear all the APIs used for the user
              Provider.of<DashboardProvider>(context, listen: false).clear();
              Provider.of<BookmarkProvider>(context, listen: false).clear();
              Provider.of<UserProvider>(context, listen: false).clear();
              Provider.of<UserProvider>(context, listen: false).disposeData();
              pushPostLogoutReplacement(context);
            },
          ),
        ],
      ),
    );
  }

  Widget profileCard(String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      margin: _isTv
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
          : null,
      child: Padding(
        padding: EdgeInsets.all(_isTv ? 6.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(
                      left: 8.0,
                      top: _isTv ? 2 : 0,
                      bottom: _isTv ? 2 : 4,
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontWeight: FontWeight.bold,
                        fontSize: _isTv ? 13 : 16,
                      ),
                    ),
                  )
                : SizedBox(),
            ...children,
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, ThemeData theme) {
    final lang = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    bool isDark = theme.brightness == Brightness.dark;
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final profilePhotoUrl =
        normalizeNetworkImageUrl(userProvider.userObj.profilePhoto);

    final isTv = _isTv;
    final avatarSize = isTv ? 64.0 : 100.0;
    // Opened as its own route (e.g. the home page's profile icon) there is
    // no sidebar to leave through, so show a single back button. Inside the
    // navigation shell (onOpenDetail set) the shell handles navigation.
    final showBack =
        widget.onOpenDetail == null && Navigator.of(context).canPop();
    final actionIconSize = isTv ? 20.0 : 24.0;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      leading: showBack ? _buildBackButton(theme) : null,
      toolbarHeight: isTv ? 48 : kToolbarHeight,
      expandedHeight: isTv ? 210 : 280,
      backgroundColor: theme.scaffoldBackgroundColor,
      centerTitle: ResponsiveWidget.isDesktop(context) ? true : false,
      actions: [
        LanguageDropdown(),
        IconButton(
          icon: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            color: theme.canvasColor,
            size: actionIconSize,
          ),
          tooltip: "Toggle Theme",
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
        IconButton(
          onPressed: () {
            _showCupertinoDialog(context);
          },
          tooltip: "Logout",
          icon: Icon(
            Icons.logout,
            color: theme.canvasColor,
            size: actionIconSize,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        //titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),

        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],

        background: Center(
          child: Container(
            width: ResponsiveWidget.isMobile(context)
                ? double.infinity
                : (isTv ? 400 : 500),
            padding: EdgeInsets.all(isTv ? 12.0 : 20.0),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: ResponsiveWidget.isDesktop(context)
                  ? BorderRadius.circular(isTv ? 36 : 60)
                  : const BorderRadius.only(
                      bottomLeft: Radius.circular(70),
                      bottomRight: Radius.circular(70),
                    ),
            ),
            child: Column(
              children: [
                Spacer(),
                Hero(
                  tag: "profile",
                  child: Stack(
                    alignment: AlignmentGeometry.center,
                    children: [
                      CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: theme.cardColor,
                        child: ClipOval(
                          child: profilePhotoUrl.isEmpty
                              ? Image.asset(
                                  ImageConstant.profile,
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  profilePhotoUrl,
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    ImageConstant.profile,
                                    width: avatarSize,
                                    height: avatarSize,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      (userProvider.userObj.verified ?? false)
                          ? Positioned(
                              bottom: isTv ? 2 : 8,
                              right: isTv ? 2 : 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: isTv ? 14 : 18,
                                ),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
                SizedBox(height: isTv ? 6 : 10),
                Text(
                  (() {
                    final first =
                        (userProvider.userObj.firstName ?? '').trim();
                    final last = (userProvider.userObj.lastName ?? '').trim();
                    final full = '$first $last'.trim();
                    return full.isNotEmpty ? full : 'User';
                  })(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isTv ? 15 : 18,
                  ),
                ),
                Text(
                  userProvider.userObj.emailId ?? "",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTv ? 11.5 : 14,
                  ),
                ),
                Text(
                  userProvider.userObj.mobileNumber ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTv ? 11.5 : 14,
                  ),
                ),
                SizedBox(height: isTv ? 6 : 10),
                OttTvFocus(
                  onTap: _openEditProfile,
                  borderRadius: 12,
                  scale: 1.05,
                  semanticLabel: lang.editProfile,
                  child: ElevatedButton(
                    style: isTv
                        ? ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          )
                        : null,
                    onPressed: _openEditProfile,
                    child: Text(
                      lang.editProfile,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: isTv ? 12 : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    void goBack() => Navigator.of(context).maybePop();

    if (!_isTv) {
      return IconButton(
        onPressed: goBack,
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded, color: theme.canvasColor),
      );
    }

    // Same look as the movie details TV back button.
    return Center(
      child: OttTvFocus(
        onTap: goBack,
        borderRadius: 6,
        semanticLabel: 'Back',
        child: IconButton(
          onPressed: goBack,
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            fixedSize: const Size.square(36),
            minimumSize: const Size.square(36),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
    );
  }
}

class ProfileOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double? balance;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.balance,
  });

  @override
  State<ProfileOption> createState() => _ProfileOptionState();
}

class _ProfileOptionState extends State<ProfileOption> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTv = ResponsiveWidget.isAndroidTv(context);
    final option = SizedBox(
      width: ResponsiveWidget.isMobile(context)
          ? double.infinity
          : (isTv ? 480 : 600),
      child: ListTile(
        dense: true,
        visualDensity: isTv ? VisualDensity.compact : null,
        minLeadingWidth: isTv ? 24 : null,
        contentPadding:
            isTv ? const EdgeInsets.symmetric(horizontal: 10) : null,
        leading: Icon(
          widget.icon,
          color: Theme.of(context).primaryColor,
          size: isTv ? 18 : null,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: theme.canvasColor,
            fontWeight: FontWeight.normal,
            fontSize: isTv ? 12.5 : 14,
          ),
        ),
        subtitle: widget.balance != null
            ? Text(
                '₹ ${widget.balance!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.6),
                  fontWeight: FontWeight.normal,
                  fontSize: isTv ? 10.5 : 12,
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: isTv ? 12 : 16),
        onTap: widget.onTap,
      ),
    );

    if (ResponsiveWidget.isMobile(context)) return option;

    return OttTvFocus(
      onTap: widget.onTap,
      borderRadius: isTv ? 8 : 12,
      scale: 1.025,
      child: option,
    );
  }
}

/// One entry of the profile menu (shared by phone/web and Android TV).
class _ProfileEntry {
  const _ProfileEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.balance,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double? balance;
}

class _ProfileSection {
  const _ProfileSection(this.title, this.entries);

  final String title;
  final List<_ProfileEntry> entries;
}

/// Android TV settings row: 38 px tall, 18 px icon, single focus stop.
class _TvProfileRow extends StatelessWidget {
  const _TvProfileRow({required this.entry, this.autofocus = false});

  final _ProfileEntry entry;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = entry.balance;

    return OttTvFocus(
      autofocus: autofocus,
      onTap: entry.onTap,
      borderRadius: 8,
      scale: 1.015,
      semanticLabel: entry.title,
      child: SizedBox(
        height: 38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(entry.icon, size: 18, color: theme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (balance != null) ...[
                const SizedBox(width: 8),
                Text(
                  '₹ ${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: theme.canvasColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
