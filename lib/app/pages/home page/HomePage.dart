import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/pages/search%20page/SearchPage.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
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
import '../../provider/language_provider.dart';
import '../../provider/userProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedType = "MOVIE";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserData();
    setState(() {
      isLoading = false;
    });
    confirmDetails(context);
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
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(selectedThemeData, context),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? HomeShimmer()
            : Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildFilterButtons(context, dashboardProvider),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: dashboardProvider.dashboardData.length,
                        itemBuilder: (context, index) {
                          DashboardData dashboardData =
                              dashboardProvider.dashboardData[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${dashboardData.language} - ${dashboardData.category}",
                                style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: ResponsiveWidget.isMobile(context)
                                        ? 18
                                        : 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              (dashboardData.movies == null ||
                                      dashboardData.movies!.isEmpty)
                                  ? SizedBox.shrink()
                                  : SizedBox(
                                      height: 350,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            dashboardData.movies?.length ?? 0,
                                        // Safely handle null case
                                        itemBuilder: (context, index) {
                                          final movie = dashboardData.movies?[
                                              index]; // Null-safe access
                                          if (movie == null) {
                                            return SizedBox(); // Handle null movie gracefully
                                          }
                                          return MovieCard(movie: movie);
                                        },
                                      )),
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData selectedThemeData, BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return AppBar(
      centerTitle: false, // ResponsiveWidget.isDesktop(context) ? true : false,
      forceMaterialTransparency:
          ResponsiveWidget.isDesktop(context) ? true : false,
      toolbarHeight: 60,
      title: ResponsiveWidget.isDesktop(context)
          ? Text(
              "  ${lang.homeTitle}",
              style: TextStyle(
                  color: selectedThemeData.canvasColor,
                  fontWeight: FontWeight.bold),
            )
          : Padding(
              padding: EdgeInsets.only(
                  top: 1,
                  bottom: 1,
                  left: ResponsiveWidget.isTablet(context) ? 30 : 5),
              child: SizedBox(
                width: 40,
                child: Hero(
                  tag: "logo",
                  child: Image.asset(ImageConstant.logo2),
                ),
              ),
            ),
      actions: [
        LanguageDropdown(),
        IconButton(
          icon: Icon(Icons.search,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.search,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.notifications_active,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.notification,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationPage(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.language_sharp,
              color: ResponsiveWidget.isDesktop(context)
                  ? selectedThemeData.canvasColor
                  : Colors.white),
          tooltip: lang.selectPreferredLanguage,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeLanguage(),
            ),
          ),
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
              InkWell(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.account_balance_wallet,
                          color: ResponsiveWidget.isDesktop(context)
                              ? selectedThemeData.canvasColor
                              : Colors.white),
                      tooltip: "₹${walletProvider.walletBalance}",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WalletPage()),
                      ),
                    ),
                  ],
                ),
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
                      radius: 15,
                      backgroundImage:
                          NetworkImage(userProvider.userObj.profilePhoto ?? ""),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        SizedBox(
          width: 16,
        )
      ],
      backgroundColor: ResponsiveWidget.isDesktop(context)
          ? selectedThemeData.scaffoldBackgroundColor
          : selectedThemeData.primaryColor,
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
                  type == 'MOVIE' ? lang.movie : lang.series,
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
