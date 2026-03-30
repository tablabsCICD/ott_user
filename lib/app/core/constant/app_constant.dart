class AppConstant {
  static final String appVersion = "1.0.0"; // 1
  static final String GOOGLE_KEY = "AIzaSyAm332fBuy8QoCC6ZFv7pizIqdmaT-jz30";
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_qds9tiF6d4FFtb',
  );
  static const String razorpayMerchantName = 'FilmyTell';
  static const String razorpayLogoUrl = String.fromEnvironment(
    'RAZORPAY_LOGO_URL',
    defaultValue: '',
  );
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
