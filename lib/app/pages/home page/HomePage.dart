import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsLibraryPage.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/shimmer%20loader/home_shimmer.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/response/get_dashboard_data.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/sharepreferences.dart';
import '../../provider/userProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedType = "MOVIE";
  bool isLoading = true;

//// upcoming movie posters
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> posterImages = [
    "https://images.moneycontrol.com/static-mcnews/2025/10/20251015110202_Ranveer-Singh-teases-his-next-film.png?impolicy=website&width=770&height=431",
    "https://i.ytimg.com/vi/G2h0ySpSaDs/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLDDYeWkkhZBOvs4cTyuBQ8a4A6iBw",
    "https://indiawest.com/wp-content/uploads/2025/12/BORDER-2-Official-Trailer.webp",
    "https://m.media-amazon.com/images/M/MV5BZmE5MDk0ZjAtMzVjZS00M2JjLTliMWEtZWRkM2VhYmVhYWU0XkEyXkFqcGdeQWJpbndhYWtz._V1_.jpg",
    "https://www.cinejosh.com/newsimg/newsmainimg/ranveer-singh-action-soaked-dhurandhar-trailer_b_1811250259.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Auto scroll
    Future.delayed(const Duration(seconds: 2), () {
      _startAutoScroll();
    });
  }

  Future<void> _initializeData() async {
    await _fetchUserData();
    setState(() {
      isLoading = false;
    });
    confirmDetails(context);
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;

      _currentPage = (_currentPage + 1) % posterImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return true;
    });
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
      //log(" location ${userProvider.location!.country}");
      return;
    }
  }

  Future<void> _fetchUserData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (user != null && mounted) {
      await Provider.of<UserProvider>(context, listen: false)
          .getUserById(user.id!);
    }
    final dashBoardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final selectedLanguages = Provider.of<UserProvider>(context, listen: false)
            .userObject
            .selectedLanguages ??
        []; // Ensure it doesn't throw null

    log('selecetd languages===== $selectedLanguages');

// Check if the list is empty
    if (selectedLanguages.isEmpty ||
        selectedLanguages == [] ||
        selectedLanguages == null) {
      await getMovieList(dashBoardProvider, selectedType, ["Hindi", "English"]);
    } else {
      await getMovieList(dashBoardProvider, selectedType, selectedLanguages);
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    var selectedThemeData = themeProvider.getTheme;

    return Scaffold(
      body: isLoading
          ? HomeShimmer()
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, selectedThemeData),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Consumer<DashboardProvider>(
                        builder: (context, dashboardProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child:
                                _buildFilterButtons(context, dashboardProvider),
                          ),
                          SizedBox(height: 10),
                          selectedType == 'SHORTS'
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: ShortsLibraryPage(),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  itemCount:
                                      dashboardProvider.dashboardData.length,
                                  itemBuilder: (context, index) {
                                    DashboardData dashboardData =
                                        dashboardProvider.dashboardData[index];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${dashboardData.language} - ${dashboardData.category}",
                                          style: TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              fontSize:
                                                  ResponsiveWidget.isMobile(
                                                          context)
                                                      ? 18
                                                      : 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 10),
                                        (dashboardData.movies == null ||
                                                dashboardData.movies!.isEmpty)
                                            ? SizedBox.shrink()
                                            : SizedBox(
                                                height: 350,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: dashboardData
                                                          .movies?.length ??
                                                      0,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final movie = dashboardData
                                                        .movies?[index];
                                                    if (movie == null) {
                                                      return SizedBox();
                                                    }
                                                    return MovieCard(
                                                        movie: movie);
                                                  },
                                                ),
                                              ),
                                        SizedBox(height: 20),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, ThemeData selectedThemeData) {
    final lang = AppLocalizations.of(context)!;

    return SliverAppBar(
      forceMaterialTransparency:
          ResponsiveWidget.isDesktop(context) ? true : false,
      expandedHeight: ResponsiveWidget.isMobile(context)
          ? 240
          : ResponsiveWidget.isTablet(context)
              ? 360
              : 380,
      floating: false,
      pinned: true,
      stretch: true,
      surfaceTintColor: Colors.transparent,
      backgroundColor: ResponsiveWidget.isDesktop(context)
          ? selectedThemeData.scaffoldBackgroundColor
          : selectedThemeData.primaryColor,
      title: ResponsiveWidget.isDesktop(context)
          ? Text(
              "",
              style: TextStyle(
                color: selectedThemeData.canvasColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : SizedBox(
              width: 40,
              child: Hero(
                tag: "logo",
                child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  NavigationPage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    child: Image.asset(ImageConstant.logo2)),
              ),
            ),
      titleSpacing: ResponsiveWidget.isTablet(context) ? 50 : 10,
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
          icon: Icon(Icons.language_sharp,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.selectPreferredLanguage,
          style: IconButton.styleFrom(
              backgroundColor: ResponsiveWidget.isDesktop(context)
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChangeLanguage()),
          ),
        ),
        SizedBox(
          width: 4,
        ),
        Consumer<UserProvider>(builder: (context, userProvider, child) {
          final walletProvider =
              Provider.of<WalletProvider>(context, listen: false);

          final user = userProvider.userObject;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Row(
            children: [
              IconButton(
                icon: Icon(Icons.account_balance_wallet,
                    color: ResponsiveWidget.isDesktop(context)
                        ? selectedThemeData.canvasColor
                        : Colors.white),
                tooltip: "₹${walletProvider.walletBalance}",
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: selectedThemeData.canvasColor,
                      backgroundImage: userProvider.userObj.profilePhoto == null
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
            ],
          );
        }),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        //titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),

        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: selectedThemeData.scaffoldBackgroundColor,
                child: Icon(
                  Icons.broken_image,
                  color: selectedThemeData.canvasColor.withOpacity(0.2),
                  size: 60,
                ),
              ),
            ),
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: posterImages.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    posterImages[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // Dark shadow overlay (top area)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        selectedThemeData.scaffoldBackgroundColor
                            .withOpacity(0.3),
                        selectedThemeData.scaffoldBackgroundColor
                            .withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        "SHORTS",
      ].map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GestureDetector(
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
              if (selectedType == 'SHORTS') {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ShortsScreen(),
                //   ),
                // );
                return;
              }
              if (selectedLanguages.isEmpty ||
                  selectedLanguages == [] ||
                  selectedLanguages == null) {
                await getMovieList(
                    dashboardProvider, selectedType, ["Hindi", "English"]);
              } else {
                await getMovieList(
                    dashboardProvider, selectedType, selectedLanguages);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedType == type
                      ? selectedThemeData.primaryColor
                      : selectedThemeData.canvasColor.withOpacity(0.6),
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  type == 'MOVIE'
                      ? lang.movie
                      : type == 'SERIES'
                          ? lang.series
                          : 'Shorts',
                  style: TextStyle(
                    color: selectedType == type
                        ? selectedThemeData.primaryColor
                        : selectedThemeData.canvasColor,
                    fontWeight: selectedType == type
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  Future<void> getMovieList(DashboardProvider dashBoardProvider,
      String selectedType, List<String> langList) async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    log('User in getMovieList method ${user!.firstName} ');
    await dashBoardProvider.getDashboardData(selectedType, langList, user.id!);
  }

//get user baisc details after sign in
  Future<void> userDetailsPopUp(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
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
              key: _formKey,
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
    final _formKey = GlobalKey<FormState>();
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
          title: Text(
            lang.enterLocationDetails,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: userProvider.countryController,
                    isName: true,
                    label: lang.country,
                    hintText: lang.enterCountry,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.stateController,
                    isName: true,
                    label: lang.state,
                    hintText: lang.enterState,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.districtController,
                    isName: true,
                    label: lang.district,
                    hintText: lang.enterDistrict,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.cityController,
                    isName: true,
                    label: lang.taluka,
                    hintText: lang.enterTaluka,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
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
