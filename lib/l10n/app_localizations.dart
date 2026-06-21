import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Filmytell'**
  String get appTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number'**
  String get enterMobileNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @otpSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// No description provided for @loginSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully'**
  String get loginSuccessfully;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover, Watch, Experience...'**
  String get homeTitle;

  /// No description provided for @movie.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get movie;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Details'**
  String get enterDetails;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @enterBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Enter birth date'**
  String get enterBirthDate;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enterFirstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enterLastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterEmail;

  /// No description provided for @referralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCodeOptional;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get enterReferralCode;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enterLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Location Details'**
  String get enterLocationDetails;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @enterCountry.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid country'**
  String get enterCountry;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @enterState.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid state'**
  String get enterState;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @enterDistrict.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid district'**
  String get enterDistrict;

  /// No description provided for @taluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka'**
  String get taluka;

  /// No description provided for @enterTaluka.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid taluka'**
  String get enterTaluka;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchContent.
  ///
  /// In en, this message translates to:
  /// **'Search Content'**
  String get searchContent;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get filterOptions;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @selectGenre.
  ///
  /// In en, this message translates to:
  /// **'Select Genre'**
  String get selectGenre;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @minimumRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// No description provided for @selectRating.
  ///
  /// In en, this message translates to:
  /// **'Select Rating'**
  String get selectRating;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @noContentFound.
  ///
  /// In en, this message translates to:
  /// **'No content found'**
  String get noContentFound;

  /// No description provided for @watchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @notifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get notifyMe;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @readyToStreamYourfavorites.
  ///
  /// In en, this message translates to:
  /// **'Ready to stream your favorites'**
  String get readyToStreamYourfavorites;

  /// No description provided for @addBalance.
  ///
  /// In en, this message translates to:
  /// **'Add Balance'**
  String get addBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @rechargeWallet.
  ///
  /// In en, this message translates to:
  /// **'Recharge Wallet'**
  String get rechargeWallet;

  /// No description provided for @enterAmountMin10.
  ///
  /// In en, this message translates to:
  /// **'Enter amount (Min ₹10)'**
  String get enterAmountMin10;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @minimumRechargeAmountIs10.
  ///
  /// In en, this message translates to:
  /// **'Minimum recharge amount is ₹10'**
  String get minimumRechargeAmountIs10;

  /// No description provided for @walletRechargedWith.
  ///
  /// In en, this message translates to:
  /// **'Wallet recharged with'**
  String get walletRechargedWith;

  /// No description provided for @recharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get recharge;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @enterYourQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter your query'**
  String get enterYourQuery;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get attachImage;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Preferred Language'**
  String get selectPreferredLanguage;

  /// No description provided for @director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get director;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @runtime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtime;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @audioFormat.
  ///
  /// In en, this message translates to:
  /// **'Audio Formats'**
  String get audioFormat;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get subtitle;

  /// No description provided for @ageRating.
  ///
  /// In en, this message translates to:
  /// **'Age Rating'**
  String get ageRating;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @watchTrailer.
  ///
  /// In en, this message translates to:
  /// **'Watch Trailer'**
  String get watchTrailer;

  /// No description provided for @watchMovie.
  ///
  /// In en, this message translates to:
  /// **'Watch Movie'**
  String get watchMovie;

  /// No description provided for @watchSeries.
  ///
  /// In en, this message translates to:
  /// **'Watch Series'**
  String get watchSeries;

  /// No description provided for @mediaHouse.
  ///
  /// In en, this message translates to:
  /// **'Media House'**
  String get mediaHouse;

  /// No description provided for @rentDuration.
  ///
  /// In en, this message translates to:
  /// **'Rent Duration'**
  String get rentDuration;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @myCredits.
  ///
  /// In en, this message translates to:
  /// **'My Credits'**
  String get myCredits;

  /// No description provided for @gifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get gifts;

  /// No description provided for @giftedMovies.
  ///
  /// In en, this message translates to:
  /// **'Gifted Movies'**
  String get giftedMovies;

  /// No description provided for @claimGiftCard.
  ///
  /// In en, this message translates to:
  /// **'Claim Gift Card'**
  String get claimGiftCard;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @feedbackAndInformation.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Information'**
  String get feedbackAndInformation;

  /// No description provided for @termsPoliciesLiscenses.
  ///
  /// In en, this message translates to:
  /// **'Terms, Policies and Liscenses'**
  String get termsPoliciesLiscenses;

  /// No description provided for @aboutFilmytell.
  ///
  /// In en, this message translates to:
  /// **'About Filmytell'**
  String get aboutFilmytell;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @purchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get purchaseHistory;

  /// No description provided for @giftedByYou.
  ///
  /// In en, this message translates to:
  /// **'Gifted Movies By You'**
  String get giftedByYou;

  /// No description provided for @receivedGiftedMovies.
  ///
  /// In en, this message translates to:
  /// **'Received Gifted Movies'**
  String get receivedGiftedMovies;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @minSeries.
  ///
  /// In en, this message translates to:
  /// **'Mini Series'**
  String get minSeries;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @filmytellPresents.
  ///
  /// In en, this message translates to:
  /// **'FILMYTELL PRESENTS'**
  String get filmytellPresents;

  /// No description provided for @filmytellOriginals.
  ///
  /// In en, this message translates to:
  /// **'Filmytell Originals'**
  String get filmytellOriginals;

  /// No description provided for @premiumStoriesDefault.
  ///
  /// In en, this message translates to:
  /// **'Discover premium Indian movies, series, and stories crafted for every screen.'**
  String get premiumStoriesDefault;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch Now'**
  String get watchNow;

  /// No description provided for @playTrailer.
  ///
  /// In en, this message translates to:
  /// **'Play Trailer'**
  String get playTrailer;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More Details'**
  String get moreDetails;

  /// No description provided for @trendingOnFilmytell.
  ///
  /// In en, this message translates to:
  /// **'Trending on FilmyTell'**
  String get trendingOnFilmytell;

  /// No description provided for @trendingIn.
  ///
  /// In en, this message translates to:
  /// **'Trending in'**
  String get trendingIn;

  /// No description provided for @watchPremiumMoviesSeries.
  ///
  /// In en, this message translates to:
  /// **'Watch premium movies and series on FilmyTell.'**
  String get watchPremiumMoviesSeries;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @latestContent.
  ///
  /// In en, this message translates to:
  /// **'Latest Content'**
  String get latestContent;

  /// No description provided for @howFilmytellWorks.
  ///
  /// In en, this message translates to:
  /// **'HOW FILMYTELL WORKS'**
  String get howFilmytellWorks;

  /// No description provided for @viewersEntertainmentTitle.
  ///
  /// In en, this message translates to:
  /// **'For Entertainment Lovers'**
  String get viewersEntertainmentTitle;

  /// No description provided for @viewersEntertainmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Buy or gift the movies and series you choose. No subscription needed. Download content to watch offline.'**
  String get viewersEntertainmentDescription;

  /// No description provided for @createAccountMobileOtp.
  ///
  /// In en, this message translates to:
  /// **'Create Account With Mobile OTP'**
  String get createAccountMobileOtp;

  /// No description provided for @browseMoviesAndSeries.
  ///
  /// In en, this message translates to:
  /// **'Browse Movies and Series'**
  String get browseMoviesAndSeries;

  /// No description provided for @payOnlyContentChoose.
  ///
  /// In en, this message translates to:
  /// **'Pay Only For The Content You Choose'**
  String get payOnlyContentChoose;

  /// No description provided for @giftMoviesFriendsFamily.
  ///
  /// In en, this message translates to:
  /// **'Gift Movies To Friends & Family'**
  String get giftMoviesFriendsFamily;

  /// No description provided for @buildWatchlistContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Build Watchlist & Continue Watching'**
  String get buildWatchlistContinueWatching;

  /// No description provided for @watchAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Watch Across Mobile, Web & TV'**
  String get watchAcrossDevices;

  /// No description provided for @payPerMovie.
  ///
  /// In en, this message translates to:
  /// **'Pay Per Movie'**
  String get payPerMovie;

  /// No description provided for @movieGifting.
  ///
  /// In en, this message translates to:
  /// **'Movie Gifting'**
  String get movieGifting;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @multiDeviceAccess.
  ///
  /// In en, this message translates to:
  /// **'Multi-device Access'**
  String get multiDeviceAccess;

  /// No description provided for @regionalContent.
  ///
  /// In en, this message translates to:
  /// **'Regional Content'**
  String get regionalContent;

  /// No description provided for @securePlayback.
  ///
  /// In en, this message translates to:
  /// **'Secure Playback'**
  String get securePlayback;

  /// No description provided for @exploreContent.
  ///
  /// In en, this message translates to:
  /// **'Explore Content'**
  String get exploreContent;

  /// No description provided for @productionHouseWorks.
  ///
  /// In en, this message translates to:
  /// **'HOW PRODUCTION HOUSE WORKS'**
  String get productionHouseWorks;

  /// No description provided for @productionHousesTitle.
  ///
  /// In en, this message translates to:
  /// **'For Production House'**
  String get productionHousesTitle;

  /// No description provided for @productionHouseDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload, manage and monetize your content.'**
  String get productionHouseDescription;

  /// No description provided for @contentManagement.
  ///
  /// In en, this message translates to:
  /// **'Content Management'**
  String get contentManagement;

  /// No description provided for @revenueTracking.
  ///
  /// In en, this message translates to:
  /// **'Revenue Tracking'**
  String get revenueTracking;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @approvalWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Approval Workflow'**
  String get approvalWorkflow;

  /// No description provided for @releaseScheduling.
  ///
  /// In en, this message translates to:
  /// **'Release Scheduling'**
  String get releaseScheduling;

  /// No description provided for @secureDistribution.
  ///
  /// In en, this message translates to:
  /// **'Secure Distribution'**
  String get secureDistribution;

  /// No description provided for @registerProductionHouse.
  ///
  /// In en, this message translates to:
  /// **'Register Production House'**
  String get registerProductionHouse;

  /// No description provided for @completeVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete Verification'**
  String get completeVerification;

  /// No description provided for @uploadMoviesSeries.
  ///
  /// In en, this message translates to:
  /// **'Upload Movies and Series'**
  String get uploadMoviesSeries;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit For Approval'**
  String get submitForApproval;

  /// No description provided for @trackRevenuePerformance.
  ///
  /// In en, this message translates to:
  /// **'Track Revenue & Performance'**
  String get trackRevenuePerformance;

  /// No description provided for @reachGlobalAudience.
  ///
  /// In en, this message translates to:
  /// **'Reach Global Audience'**
  String get reachGlobalAudience;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @mobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// No description provided for @enterAtLeast10Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 10 digits'**
  String get enterAtLeast10Digits;

  /// No description provided for @enterValidIndianMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Indian mobile number'**
  String get enterValidIndianMobile;

  /// No description provided for @noQueryProvided.
  ///
  /// In en, this message translates to:
  /// **'No query provided.'**
  String get noQueryProvided;

  /// No description provided for @productionEnquiryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Production House Enquiry'**
  String get productionEnquiryTitle;

  /// No description provided for @userMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'User Mobile Number'**
  String get userMobileNumber;

  /// No description provided for @query.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get query;

  /// No description provided for @redirectingWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to WhatsApp...'**
  String get redirectingWhatsapp;

  /// No description provided for @unableOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Unable to open WhatsApp. Please try again.'**
  String get unableOpenWhatsapp;

  /// No description provided for @haveQuestionHelp.
  ///
  /// In en, this message translates to:
  /// **'Have a question? We\'ll help you get started.'**
  String get haveQuestionHelp;

  /// No description provided for @messageQueryOptional.
  ///
  /// In en, this message translates to:
  /// **'Tell us your requirement or any doubt (Optional)'**
  String get messageQueryOptional;

  /// No description provided for @sendProductionEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Send production enquiry'**
  String get sendProductionEnquiry;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get opening;

  /// No description provided for @sendEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Send Enquiry'**
  String get sendEnquiry;

  /// No description provided for @watchAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Watch Anywhere'**
  String get watchAnywhere;

  /// No description provided for @availableDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Filmytell is available across your favorite screens.'**
  String get availableDevicesDescription;

  /// No description provided for @startWatching.
  ///
  /// In en, this message translates to:
  /// **'Start Watching'**
  String get startWatching;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'READY TO START'**
  String get readyToStart;

  /// No description provided for @startJourneyToday.
  ///
  /// In en, this message translates to:
  /// **'Start Your Filmytell Journey Today'**
  String get startJourneyToday;

  /// No description provided for @chooseHowUseFilmytell.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use Filmytell.'**
  String get chooseHowUseFilmytell;

  /// No description provided for @watchContent.
  ///
  /// In en, this message translates to:
  /// **'Watch Content'**
  String get watchContent;

  /// No description provided for @streamPremiumMoviesSeries.
  ///
  /// In en, this message translates to:
  /// **'Watch premium movies, series and mini series.'**
  String get streamPremiumMoviesSeries;

  /// No description provided for @userPortal.
  ///
  /// In en, this message translates to:
  /// **'User Portal'**
  String get userPortal;

  /// No description provided for @publishContent.
  ///
  /// In en, this message translates to:
  /// **'Publish Content'**
  String get publishContent;

  /// No description provided for @publishContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload, manage and monetize your releases.'**
  String get publishContentDescription;

  /// No description provided for @productionHousePortal.
  ///
  /// In en, this message translates to:
  /// **'Production House Portal'**
  String get productionHousePortal;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @portals.
  ///
  /// In en, this message translates to:
  /// **'Portals'**
  String get portals;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'@Filmytell. All Rights Reserved.'**
  String get allRightsReserved;

  /// No description provided for @giftAccess.
  ///
  /// In en, this message translates to:
  /// **'Gift access'**
  String get giftAccess;

  /// No description provided for @downloadOffline.
  ///
  /// In en, this message translates to:
  /// **'Download offline'**
  String get downloadOffline;

  /// No description provided for @unableOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get unableOpenLink;

  /// No description provided for @unableOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Unable to open document'**
  String get unableOpenDocument;

  /// No description provided for @trailerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trailer is not available'**
  String get trailerNotAvailable;

  /// No description provided for @chatWithUsWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp'**
  String get chatWithUsWhatsapp;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @filmytellByNumbers.
  ///
  /// In en, this message translates to:
  /// **'Filmytell By The Numbers'**
  String get filmytellByNumbers;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @moviesLabel.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get moviesLabel;

  /// No description provided for @seriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get seriesLabel;

  /// No description provided for @productionHouses.
  ///
  /// In en, this message translates to:
  /// **'Production House'**
  String get productionHouses;

  /// No description provided for @growing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get growing;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every Day'**
  String get everyDay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'as',
        'bn',
        'en',
        'gu',
        'hi',
        'kn',
        'ml',
        'mr',
        'ne',
        'or',
        'pa',
        'ta',
        'te',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
