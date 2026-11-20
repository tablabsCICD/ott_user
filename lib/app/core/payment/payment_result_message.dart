import 'package:flutter/widgets.dart';
import 'package:ott/app/core/payment/models/payment_result.dart';
import 'package:ott/l10n/app_localizations.dart';

/// Message to show for a payment that did not succeed.
///
/// - Cancelled (gateway reported cancel, or the user backed out of the
///   payment screen so the result is null): shows the gateway's own reason if
///   it gave one, otherwise the localized "Payment cancelled." message.
/// - Failed: shows the gateway/backend message, or [fallback] if none.
String paymentFailureMessage(
  BuildContext context,
  Object? result, {
  required String fallback,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (result == null) return l10n.paymentCancelled;
  if (result is! Map) return fallback;

  final message = result['message']?.toString().trim() ?? '';
  final readable = PaymentResult.readableGatewayMessage(message);
  if (result['cancelled'] == true) {
    if (readable == null ||
        readable == PaymentResult.defaultCancelledMessage) {
      return l10n.paymentCancelled;
    }
    return readable;
  }
  return readable ?? fallback;
}
