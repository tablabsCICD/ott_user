class AppConstant {
  static const String appVersion = "1.0.2";
  static const int appBuildNumber = 7;
  static final String GOOGLE_KEY = "AIzaSyDbIESWMKX_4TqGEiFUhbu8-PUpLnVBPrc";
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_qds9tiF6d4FFtb',
  );
  static const String razorpayMerchantName = 'Filmytell';
  static const String razorpayLogoUrl = String.fromEnvironment(
    'https://filmytell-document.s3.ap-south-1.amazonaws.com/documents/filmytell-logo-1778238183653.jpeg',
    defaultValue: '',
  );
  static const playStoreLink =
      "https://play.google.com/store/apps/details?id=com.filmytell.ott";
  static const webAppLink = "https://filmytell.in";

  static const privacyPolicy =
      "https://filmytell-document.s3.ap-south-1.amazonaws.com/filmytell_privacy_policy.html";
  static const termsAndCondition =
      "https://filmytell-document.s3.ap-south-1.amazonaws.com/filmytell_privacy_policy.html";

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
