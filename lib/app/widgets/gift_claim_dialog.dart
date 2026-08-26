import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

Future<bool?> showGiftClaimDialog(
  BuildContext context, {
  String? initialCouponCode,
}) {
  final theme = Theme.of(context);
  final couponCodeController = TextEditingController(
    text: _normalizeCouponCode(initialCouponCode ?? ''),
  );
  final couponFocusNode = FocusNode(debugLabel: 'gift-card-input');

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: ResponsiveWidget.isMobile(dialogContext)
                ? double.infinity
                : 400,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Icon(
                    LucideIcons.gift,
                    size: 200,
                    color: theme.canvasColor.withOpacity(0.1),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      focusNode: couponFocusNode,
                      isDigits: false,
                      controller: couponCodeController,
                      autofocus: ResponsiveWidget.isTabletOrTv(dialogContext),
                      textInputAction: TextInputAction.done,
                      hintText: "Enter 16 Digit Number",
                      textInputType: TextInputType.text,
                      capitalization: TextCapitalization.characters,
                      readOnly: false,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OttTvFocus(
                          borderRadius: 8,
                          onTap: () => Navigator.pop(dialogContext),
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OttTvFocus(
                          borderRadius: 12,
                          onTap: () async {
                            final couponCode = _normalizeCouponCode(
                              couponCodeController.text,
                            );

                            if (couponCode.isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter a coupon code"),
                                ),
                              );
                              return;
                            }

                            if (couponCode.length != 16) {
                              CustomToast.show(
                                dialogContext,
                                "Coupon code is invalid, try again.",
                                isSuccess: false,
                              );
                              return;
                            }

                            try {
                              final provider = Provider.of<GiftProvider>(
                                dialogContext,
                                listen: false,
                              );
                              final result = await provider.useGiftByCoupon(
                                couponCode,
                              );

                              if (result["success"] == true) {
                                CustomToast.show(
                                  dialogContext,
                                  result["message"].toString(),
                                  isSuccess: true,
                                );
                                Navigator.pop(dialogContext, true);
                              } else {
                                CustomToast.show(
                                  dialogContext,
                                  result["message"].toString(),
                                  isSuccess: false,
                                );
                              }
                            } catch (_) {
                              CustomToast.show(
                                dialogContext,
                                "Something went wrong",
                                isSuccess: false,
                              );
                            }
                          },
                          child: ElevatedButton(
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
                            onPressed: () async {
                              final couponCode = _normalizeCouponCode(
                                couponCodeController.text,
                              );

                              if (couponCode.isEmpty) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please enter a coupon code"),
                                  ),
                                );
                                return;
                              }

                              if (couponCode.length != 16) {
                                CustomToast.show(
                                  dialogContext,
                                  "Coupon code is invalid, try again.",
                                  isSuccess: false,
                                );
                                return;
                              }

                              try {
                                final provider = Provider.of<GiftProvider>(
                                  dialogContext,
                                  listen: false,
                                );
                                final result = await provider.useGiftByCoupon(
                                  couponCode,
                                );

                                if (result["success"] == true) {
                                  CustomToast.show(
                                    dialogContext,
                                    result["message"].toString(),
                                    isSuccess: true,
                                  );
                                  Navigator.pop(dialogContext, true);
                                } else {
                                  CustomToast.show(
                                    dialogContext,
                                    result["message"].toString(),
                                    isSuccess: false,
                                  );
                                }
                              } catch (_) {
                                CustomToast.show(
                                  dialogContext,
                                  "Something went wrong",
                                  isSuccess: false,
                                );
                              }
                            },
                            child: const Text(
                              "Redeem",
                              style: TextStyle(color: Colors.white),
                            ),
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
      );
    },
  ).whenComplete(couponCodeController.dispose);
}

String _normalizeCouponCode(String value) {
  return value.trim().replaceAll(' ', '').toUpperCase();
}
