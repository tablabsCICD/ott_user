class AppConstant {
  static const String appVersion = "1.0.14";
  static const int appBuildNumber = 30;
  static final String GOOGLE_KEY = "AIzaSyDbIESWMKX_4TqGEiFUhbu8-PUpLnVBPrc";
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_live_T7KP6YnJcCZgxP',
  );
  static const String razorpayMerchantName = 'Filmytell';
  static const String razorpayLogoUrl = String.fromEnvironment(
    'RAZORPAY_LOGO_URL',
    defaultValue:
        'https://filmytell-document.s3.ap-south-1.amazonaws.com/documents/favicon-1781181436031.png',
  );
  static const playStoreLink =
      "https://play.google.com/store/apps/details?id=com.filmytell.ott";
  static const filmytellPartnerPlayStoreLink =
      "https://play.google.com/store/apps/details?id=com.filmytell.partner";

  static const webAppLink = "https://filmytell.com";
  static const accountDeletionUrl = "https://filmytell.com/account-delete.html";

  static const privacyPolicy =
      "https://filmytell-document.s3.ap-south-1.amazonaws.com/documents/filmytell-privacy-policy-h-a-05-06-2026-1781181202883-1781269363236.pdf";
  static const termsAndCondition =
      "https://filmytell-document.s3.ap-south-1.amazonaws.com/documents/filmytell-terms-of-use-h-a-09-06-2026-1781269391191.pdf";

  static const productionHouseUrl =
      'https://filmytell.com/productionHouse/#/login/';

  static const userPortalUrl = 'https://filmytell.com/';

  static const promoterPortalUrl = 'https://filmytell.com/promoter/#/login/';

  static const adminPortalUrl = 'https://filmytell.com/ottAdmin/#/login/';

  final List<String> availableLanguages = [
    'Hindi',
    'English',
    'Bengali',
    'Marathi',
    'Telugu',
    'Tamil',
    'Gujarati',
    'Urdu',
    'Kannada',
    'Odia',
    'Malayalam',
    'Punjabi',
    'Assamese',
    'Rajasthani',
    'Bhojpuri',
    'Sindhi',
    'Konkani',
    'Maithili',
    'Santali',
    'Manipuri',
    'Kashmiri',
    'Dogri',
    'Tulu',
    'Mizo',
    'Bodo'
  ];
}
