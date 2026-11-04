import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

Future<bool?> showGiftClaimDialog(
  BuildContext context, {
  String? initialCouponCode,
  bool isFromDeepLink = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return GiftClaimDialog(
        initialCouponCode: initialCouponCode,
        isFromDeepLink: isFromDeepLink,
      );
    },
  );
}

class GiftClaimDialog extends StatefulWidget {
  final String? initialCouponCode;
  final bool isFromDeepLink;

  const GiftClaimDialog({
    super.key,
    this.initialCouponCode,
    this.isFromDeepLink = false,
  });

  @override
  State<GiftClaimDialog> createState() => _GiftClaimDialogState();
}

class _GiftClaimDialogState extends State<GiftClaimDialog> {
  late final TextEditingController _couponCodeController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _couponCodeController = TextEditingController(
      text: _normalizeCouponCode(widget.initialCouponCode ?? ''),
    );
    // Rebuild so the Redeem button enables/disables as the code is typed.
    _couponCodeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  bool get _isCodeValid =>
      isValidGiftCardCodeLength(_couponCodeController.text);

  @override
  void dispose() {
    _couponCodeController.removeListener(_onCodeChanged);
    _couponCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Block back-button dismissal while a redemption request is in flight.
      canPop: !_isClaiming,
      child: Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Icon(
                          LucideIcons.gift,
                          size: 200,
                          color: theme.canvasColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter Gift Card Number",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.canvasColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomTextField(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        isDigits: false,
                        controller: _couponCodeController,
                        autofocus: !widget.isFromDeepLink &&
                            ResponsiveWidget.isTabletOrTv(context),
                        textInputAction: TextInputAction.done,
                        hintText: "Enter 16 Digit Number",
                        textInputType: TextInputType.text,
                        capitalization: TextCapitalization.characters,
                        readOnly: widget.isFromDeepLink,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isClaiming
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: theme.canvasColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _isClaiming || !_isCodeValid
                                ? null
                                : _handleRedeem,
                            child: _isClaiming
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Redeem",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRedeem() async {
    if (_isClaiming) return;

    final couponCode = _normalizeCouponCode(_couponCodeController.text);

    // Never call the API unless the code is exactly 16 characters.
    if (!isValidGiftCardCodeLength(couponCode)) return;

    setState(() => _isClaiming = true);

    try {
      final provider = Provider.of<GiftProvider>(context, listen: false);
      final result = await provider.useGiftByCoupon(couponCode);
      if (!mounted) return;

      if (result["success"] == true) {
        await GiftDeepLinkService.instance.markGiftCodeClaimed(couponCode);
        if (!mounted) return;
        // Show exactly the backend's success message.
        final successMessage = result["message"]?.toString().trim() ?? "";
        if (successMessage.isNotEmpty) {
          CustomToast.show(context, successMessage, isSuccess: true);
        }
        Navigator.pop(context, true);
      } else {
        final rawMsg = result["message"]?.toString().trim() ?? "";
        // Show exactly the backend's error message; the generic fallback is
        // used only when the response carried no message at all.
        final errorMessage = rawMsg.isNotEmpty
            ? rawMsg
            : resolveClaimErrorMessage(
                statusCode: result["statusCode"] as int?,
                error: result["error"],
              );

        final lower = rawMsg.toLowerCase();
        if (lower.contains('already') ||
            lower.contains('redeemed') ||
            lower.contains('claimed') ||
            lower.contains('used')) {
          await GiftDeepLinkService.instance.markGiftCodeClaimed(couponCode);
        }
        if (!mounted) return;
        CustomToast.show(
          context,
          errorMessage,
          isSuccess: false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      final errorMessage = resolveClaimErrorMessage(error: error);
      CustomToast.show(
        context,
        errorMessage,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }
}

String resolveClaimErrorMessage({
  dynamic error,
  String? rawMessage,
  int? statusCode,
}) {
  if (error != null) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socket') ||
        errStr.contains('network') ||
        errStr.contains('connection') ||
        errStr.contains('host lookup') ||
        errStr.contains('timed out') ||
        errStr.contains('clientexception')) {
      return "Unable to claim the gift card. Please check your internet connection and try again.";
    }
    return "Something went wrong while claiming the gift card. Please try again later.";
  }

  if (statusCode != null && statusCode >= 500) {
    return "Something went wrong while claiming the gift card. Please try again later.";
  }

  final msg = rawMessage?.trim() ?? '';
  final lower = msg.toLowerCase();

  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('host lookup') ||
      lower.contains('timed out') ||
      lower.contains('unable to claim')) {
    return "Unable to claim the gift card. Please check your internet connection and try again.";
  }

  if (lower.contains('already') ||
      lower.contains('claimed') ||
      lower.contains('redeemed') ||
      lower.contains('used')) {
    return "This gift card has already been claimed.";
  }

  if (lower.contains('expire') ||
      lower.contains('validity') ||
      lower.contains('outdated')) {
    return "This gift card has expired.";
  }

  if (lower.contains('invalid') ||
      lower.contains('not found') ||
      lower.contains('not exist') ||
      lower.contains('does not exist') ||
      lower.contains('incorrect') ||
      lower.contains('wrong')) {
    return "Invalid gift card code. Please check and try again.";
  }

  if (lower.contains('server error') ||
      lower.contains('internal server') ||
      lower.contains('something went wrong')) {
    return "Something went wrong while claiming the gift card. Please try again later.";
  }

  if (msg.isNotEmpty &&
      !lower.contains('failed to save gift') &&
      !lower.contains('failed to claim')) {
    return msg;
  }

  return "Something went wrong while claiming the gift card. Please try again later.";
}

/// A gift card code is redeemable only when, after normalization, it is
/// exactly 16 characters long (empty, shorter or longer codes are rejected).
bool isValidGiftCardCodeLength(String value) =>
    _normalizeCouponCode(value).length == 16;

String _normalizeCouponCode(String value) {
  return value.trim().replaceAll(' ', '').toUpperCase();
}
