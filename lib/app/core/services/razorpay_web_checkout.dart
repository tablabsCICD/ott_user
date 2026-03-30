import 'razorpay_web_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_web_checkout_web.dart';

Future<Map<String, dynamic>> openRazorpayWebCheckout(
  Map<String, Object?> options,
) {
  return openRazorpayWebCheckoutImpl(options);
}
