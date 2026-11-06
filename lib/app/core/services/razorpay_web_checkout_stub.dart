import 'package:ott/app/core/utils/app_l10n.dart';

Future<Map<String, dynamic>> openRazorpayWebCheckoutImpl(
  Map<String, Object?> options,
) async {
  return {
    'success': false,
    'message': appL10n().sysRazorpayWebCheckoutUnavailable,
  };
}
