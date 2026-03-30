// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

Future<Map<String, dynamic>> openRazorpayWebCheckoutImpl(
  Map<String, Object?> options,
) async {
  final globalContext = js_util.globalThis as Object;
  final jsOptions = js_util.jsify(options) as Object;
  final jsResult = await js_util.promiseToFuture<Object?>(
    js_util.callMethod<Object>(
      globalContext,
      'openRazorpayCheckout',
      [jsOptions],
    ),
  );

  if (jsResult == null) {
    return {
      'success': false,
      'message': 'Unexpected empty response from Razorpay web checkout.',
    };
  }

  final dartResult = js_util.dartify(jsResult);
  if (dartResult is Map) {
    return Map<String, dynamic>.from(dartResult);
  }

  return {
    'success': false,
    'message': 'Unexpected response from Razorpay web checkout.',
  };
}
