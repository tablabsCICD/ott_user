import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<Map<String, dynamic>> openRazorpayWebCheckoutImpl(
  Map<String, Object?> options,
) async {
  final jsOptions = options.jsify();
  final jsPromise = globalContext.callMethodVarArgs<JSPromise<JSAny?>>(
    'openRazorpayCheckout'.toJS,
    [jsOptions],
  );
  final jsResult = await jsPromise.toDart;

  if (jsResult == null) {
    return {
      'success': false,
      'message': 'Unexpected empty response from Razorpay web checkout.',
    };
  }

  final dartResult = jsResult.dartify();
  if (dartResult is Map) {
    return Map<String, dynamic>.from(dartResult);
  }

  return {
    'success': false,
    'message': 'Unexpected response from Razorpay web checkout.',
  };
}
