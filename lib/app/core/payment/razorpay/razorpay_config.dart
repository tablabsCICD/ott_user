import 'package:ott/app/core/constant/app_constant.dart';

class RazorpayConfig {
  RazorpayConfig._();

  static String get keyId => AppConstant.razorpayKeyId.trim();
  static String get merchantName => AppConstant.razorpayMerchantName.trim();
  static String get logoUrl => AppConstant.razorpayLogoUrl.trim();
  static const String defaultCurrency = 'INR';
}
