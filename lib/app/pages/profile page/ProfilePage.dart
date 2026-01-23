import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/gifted%20movies%20page/GiftedMoviesPage.dart';
import 'package:ott/app/pages/help%20support%20page/HelpSupportPage.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';
import 'package:ott/app/pages/profile%20page/component/EditProfilePage.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/pages/upcoming%20movies%20page/UpcomingPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/pages/watchlist%20page/WatchlistPage.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/shimmer%20loader/profile_shimmer.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constant/prefrense_constant.dart';
import '../../core/utils/sharepreferences.dart';
import '../../provider/userProvider.dart';
import '../../widgets/show_toast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _fetchUserData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (user != null) {
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .getUserById(user.id ?? 0);
      }
    }
    await Provider.of<WalletProvider>(context, listen: false).getBalance();
  }

  @override
  Widget build(BuildContext context) {
    var walletProvider = Provider.of<WalletProvider>(context);
    double walletBalance = walletProvider.walletBalance;
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;
    bool isDark = selectedThemeData.brightness == Brightness.dark;

    return Scaffold(
      body: isLoading
          ? ProfileShimmer()
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, selectedThemeData),
                SliverToBoxAdapter(
                  child: Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                    final user = userProvider.userObject;

                    if (user == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    TextEditingController couponCodeController =
                        TextEditingController();

                    return SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: [
                            // Container(
                            //   width: ResponsiveWidget.isMobile(context)
                            //       ? double.infinity
                            //       : 400,
                            //   padding: const EdgeInsets.all(20.0),
                            //   decoration: BoxDecoration(
                            //     color: theme.primaryColor,
                            //     borderRadius: const BorderRadius.only(
                            //       bottomLeft: Radius.circular(70),
                            //       bottomRight: Radius.circular(70),
                            //     ),
                            //   ),
                            //   child: Column(
                            //     children: [
                            //       Hero(
                            //         tag: "profile",
                            //         child: CircleAvatar(
                            //           radius: 50,
                            //           backgroundColor:
                            //               selectedThemeData.cardColor,
                            //           backgroundImage: userProvider
                            //                       .userObj.profilePhoto ==
                            //                   null
                            //               ? AssetImage(ImageConstant.profile)
                            //               : userProvider.userObj.profilePhoto!
                            //                       .isNotEmpty
                            //                   ? NetworkImage(
                            //                       userProvider
                            //                           .userObj.profilePhoto!,
                            //                     )
                            //                   : AssetImage(
                            //                       ImageConstant.profile),
                            //         ),
                            //       ),
                            //       const SizedBox(height: 10),
                            //       Text(
                            //         "${userProvider.userObj.firstName ?? 'First Name'} ${userProvider.userObj.lastName ?? 'Last Name'}",
                            //         style: theme.textTheme.titleLarge?.copyWith(
                            //           color: Colors.white,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //       Text(
                            //         userProvider.userObj.emailId ?? "",
                            //         style: theme.textTheme.titleSmall?.copyWith(
                            //           color: Colors.white70,
                            //         ),
                            //       ),
                            //       Text(
                            //         userProvider.userObj.mobileNumber ?? '',
                            //         style: theme.textTheme.titleSmall?.copyWith(
                            //           color: Colors.white70,
                            //         ),
                            //       ),
                            //       const SizedBox(height: 10),
                            //       ElevatedButton(
                            //         onPressed: () {
                            //           Navigator.push(
                            //             context,
                            //             MaterialPageRoute(
                            //               builder: (context) =>
                            //                   const EditProfilePage(),
                            //             ),
                            //           );
                            //         },
                            //         child: Text(
                            //           lang.editProfile,
                            //           style: TextStyle(
                            //             color: selectedThemeData.canvasColor,
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            const SizedBox(height: 10),
                            profileCard(
                              'My Credits',
                              [
                                ProfileOption(
                                  icon: Icons.account_balance_wallet,
                                  title: lang.wallet,
                                  balance: walletBalance,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => WalletPage()),
                                  ),
                                ),
                              ],
                            ),
                            profileCard(
                              'Gifts',
                              [
                                ProfileOption(
                                  icon: Icons.history_sharp,
                                  title: 'Gifted Movies',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            GiftedMoviesPage()),
                                  ),
                                ),
                                ProfileOption(
                                  icon: LucideIcons.gift,
                                  title: 'Claim Gift Card',
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return Dialog(
                                          backgroundColor: theme.cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          insetPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 24),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: SizedBox(
                                              width: ResponsiveWidget.isMobile(
                                                      context)
                                                  ? double.infinity
                                                  : 400,
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    top: 1,
                                                    left: 1,
                                                    right: 1,
                                                    bottom: 1,
                                                    child: Icon(
                                                      LucideIcons.gift,
                                                      size: 200,
                                                      color: theme.canvasColor
                                                          .withOpacity(0.1),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Description
                                                      Text(
                                                        "Enter Gift Card Number",
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color:
                                                              theme.canvasColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),

                                                      // Input field
                                                      CustomTextField(
                                                        backgroundColor: theme
                                                            .scaffoldBackgroundColor,
                                                        isDigits: true,
                                                        controller:
                                                            couponCodeController,
                                                        hintText:
                                                            "Enter 16 Digit Number",
                                                        textInputType:
                                                            TextInputType.text,
                                                      ),
                                                      const SizedBox(
                                                          height: 24),

                                                      // Action buttons
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: Text(
                                                              "Cancel",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor: theme
                                                                  .primaryColor,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 24,
                                                                vertical: 12,
                                                              ),
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              final provider =
                                                                  Provider.of<
                                                                          GiftProvider>(
                                                                      context,
                                                                      listen:
                                                                          false);

                                                              if (couponCodeController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          "Please enter a coupon code")),
                                                                );
                                                                return;
                                                              }

                                                              try {
                                                                final result = await provider
                                                                    .useGiftByCoupon(
                                                                        couponCodeController
                                                                            .text
                                                                            .trim());
                                                                if (couponCodeController
                                                                            .text
                                                                            .length >
                                                                        16 ||
                                                                    couponCodeController
                                                                            .text
                                                                            .length <
                                                                        16) {
                                                                  CustomToast
                                                                      .show(
                                                                    context,
                                                                    "Coupon code is invalid, try again.",
                                                                    isSuccess:
                                                                        false,
                                                                  );
                                                                  return;
                                                                }
                                                                if (result[
                                                                        "success"] ==
                                                                    true) {
                                                                  CustomToast
                                                                      .show(
                                                                    context,
                                                                    "Coupon applied successfully",
                                                                    isSuccess:
                                                                        true,
                                                                  );

                                                                  Navigator.pop(
                                                                      context,
                                                                      true);
                                                                } else {
                                                                  CustomToast
                                                                      .show(
                                                                    context,
                                                                    "Failed to apply coupon",
                                                                    isSuccess:
                                                                        false,
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                CustomToast
                                                                    .show(
                                                                  context,
                                                                  "Something went wrong",
                                                                  isSuccess:
                                                                      false,
                                                                );
                                                              }
                                                            },
                                                            child: const Text(
                                                              "Redeem",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            profileCard(
                              'Features',
                              [
                                ProfileOption(
                                  icon: Icons.history,
                                  title: lang.watchlist,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const WatchlistPage()),
                                  ),
                                ),
                                ProfileOption(
                                  icon: Icons.upcoming,
                                  title: lang.upcoming,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UpcomingPage()),
                                  ),
                                ),
                                ProfileOption(
                                  icon: Icons.notifications,
                                  title: lang.notification,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationPage()),
                                  ),
                                ),
                                ProfileOption(
                                  icon: Icons.language_sharp,
                                  title: lang.selectPreferredLanguage,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ChangeLanguage()),
                                  ),
                                ),
                              ],
                            ),
                            profileCard(
                              'Feedback & Information',
                              [
                                ProfileOption(
                                  icon: Icons.support_agent_sharp,
                                  title: lang.help,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HelpSupportPage()),
                                  ),
                                ),
                                ProfileOption(
                                  icon: Icons.file_copy,
                                  title: 'Terms, Policies and Licenses',
                                  onTap: () {},
                                ),
                                ProfileOption(
                                  icon: Icons.info,
                                  title: 'About Filmytell',
                                  onTap: () {},
                                ),
                                ProfileOption(
                                  icon: Icons.star,
                                  title: 'Rate Us',
                                  onTap: () {},
                                ),
                              ],
                            ),
                            profileCard(
                              '',
                              [
                                ProfileOption(
                                  icon: Icons.logout,
                                  title: lang.logout,
                                  onTap: () {
                                    _showCupertinoDialog(context);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 200),

                            Text(
                              "Version · ${AppConstant.appVersion}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Text(
                            //   'Joining date: ${userProvider.userObject.joinDate}',
                            //   style: const TextStyle(
                            //     color: Colors.grey,
                            //     fontWeight: FontWeight.bold,
                            //     fontSize: 12,
                            //   ),
                            // ),
                            const SizedBox(height: 2),
                            Text(
                              "© Filmytell - All Rights Reserved.",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
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

  void _showCupertinoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Are you sure you want Logout?'),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.canvasColor),
            child: Text(lang.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.primaryColor),
            child: Text(lang.logout),
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              LocalSharePreferences localSharePreferences =
                  LocalSharePreferences();
              localSharePreferences.setBool(
                  SharedPreferencesConstant.isUserLoggedIn, false);
              print(
                  "check  SEtLogin ${await localSharePreferences.getBool(SharedPreferencesConstant.isUserLoggedIn)}");
              localSharePreferences.setString(
                  SharedPreferencesConstant.currentUser, '');

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginCard()),
              );
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      bottom: 4,
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: theme.scaffoldBackgroundColor,
      centerTitle: ResponsiveWidget.isDesktop(context) ? true : false,
      actions: [
        LanguageDropdown(),
        IconButton(
          icon: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            color: theme.canvasColor,
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
          ),
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
            width: ResponsiveWidget.isMobile(context) ? double.infinity : 500,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: ResponsiveWidget.isDesktop(context)
                  ? BorderRadius.circular(60)
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
                        radius: 50,
                        backgroundColor: theme.cardColor,
                        backgroundImage:
                            userProvider.userObj.profilePhoto == null
                                ? AssetImage(ImageConstant.profile)
                                : userProvider.userObj.profilePhoto!.isNotEmpty
                                    ? NetworkImage(
                                        userProvider.userObj.profilePhoto!,
                                      )
                                    : AssetImage(ImageConstant.profile),
                      ),
                      userProvider.userObj.verified!
                          ? Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${userProvider.userObj.firstName ?? 'First Name'} ${userProvider.userObj.lastName ?? 'Last Name'}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  userProvider.userObj.emailId ?? "",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  userProvider.userObj.mobileNumber ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  userProvider.userObj.id.toString() ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: Text(
                    lang.editProfile,
                    style: TextStyle(
                      color: theme.canvasColor,
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
}

///////////////////////////// Profile Option Widget /////////////////////////////
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
    return SizedBox(
      width: ResponsiveWidget.isMobile(context) ? double.infinity : 600,
      child: ListTile(
        dense: true,
        leading: Icon(widget.icon, color: Theme.of(context).primaryColor),
        title: Text(
          widget.title,
          style: TextStyle(
            color: theme.canvasColor,
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: widget.balance != null
            ? Text(
                '₹ ${widget.balance}',
                style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.6),
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: widget.onTap,
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  @override
  void initState() {
    super.initState();
    // Move fetchLanguage to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch languages here
    fetchLanguage();
  }

  Future<void> fetchLanguage() async {
    LanguageProvider languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.fetchLanguages();
  }

  void _toggleSelection(String language, UserProvider userProvider) {
    setState(() {
      userProvider.selectedLanguages.contains(language)
          ? userProvider.selectedLanguages.remove(language)
          : userProvider.selectedLanguages.add(language);
    });
    // Update Provider
    Provider.of<LanguageProvider>(context, listen: false)
        .updateLanguages(userProvider.selectedLanguages);
  }

  Future<void> _saveLanguages(UserProvider userProvider) async {
    if (userProvider.selectedLanguages.length < 3) {
      CustomToast.show(context, 'Please select at least 3 languages.',
          isSuccess: false);

      return;
    }

    var result =
        await userProvider.updateUserLang(userProvider.selectedLanguages);
    if (result['success'] == true) {
      print(result['message']);
      // CustomToast.show(result['message'].toString(),isSuccess: true);
      CustomToast.show(context, "Language has been updated successfully.",
          isSuccess: true);
    } else {
      print('Failure: ${result['message']}');
      CustomToast.show(context, result['message'].toString(), isSuccess: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    var themeProvider = Provider.of<ThemeProvider>(context);
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: selectedThemeData.canvasColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: selectedThemeData.scaffoldBackgroundColor,
        title: Text(
          lang.selectPreferredLanguage,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<LanguageProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: provider.allLanguages.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          ResponsiveWidget.isMobile(context) ? 3 : 6,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 5 / 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final language = provider.allLanguages[index];
                      return ElevatedButton(
                        onPressed: () =>
                            _toggleSelection(language, userProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              provider.selectedLanguages.contains(language)
                                  ? selectedThemeData.primaryColor
                                  : selectedThemeData.cardColor,
                          foregroundColor:
                              provider.selectedLanguages.contains(language)
                                  ? Colors.white
                                  : selectedThemeData.canvasColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(language, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: ResponsiveWidget.isMobile(context)
                        ? double.infinity
                        : 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedThemeData.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        _saveLanguages(userProvider);
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
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}
