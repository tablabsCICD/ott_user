import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
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
    // Falls back to English when the host app has no localization delegates.
    final lang = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));

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
                        lang.giftEnterGiftCardNumber,
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
                        hintText: lang.giftEnter16DigitNumber,
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
                              lang.cancel,
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
                                : Text(
                                    lang.giftRedeem,
                                    style: const TextStyle(color: Colors.white),
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
        final navigator = Navigator.of(context);
        Navigator.pop(context, true);
        // Gift link (WhatsApp) flow: open the gifted content's details once,
        // only after a confirmed successful claim.
        if (widget.isFromDeepLink) {
          unawaited(openGiftedContentDetails(navigator, result["data"]));
        }
      } else {
        final rawMsg = result["message"]?.toString().trim() ?? "";
        // Show exactly the backend's error message; the generic fallback is
        // used only when the response carried no message at all.
        final errorMessage = rawMsg.isNotEmpty
            ? rawMsg
            : resolveClaimErrorMessage(
                statusCode: result["statusCode"] as int?,
                error: result["error"],
                l10n: AppLocalizations.of(context),
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
      final errorMessage = resolveClaimErrorMessage(
        error: error,
        l10n: AppLocalizations.of(context),
      );
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
  AppLocalizations? l10n,
}) {
  // Frontend fallback texts (used only when the backend sent no usable
  // message). English when no localizations are supplied.
  final lang = l10n ?? lookupAppLocalizations(const Locale('en'));
  if (error != null) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socket') ||
        errStr.contains('network') ||
        errStr.contains('connection') ||
        errStr.contains('host lookup') ||
        errStr.contains('timed out') ||
        errStr.contains('clientexception')) {
      return lang.msgGiftClaimNetworkError;
    }
    return lang.msgGiftClaimFailed;
  }

  if (statusCode != null && statusCode >= 500) {
    return lang.msgGiftClaimFailed;
  }

  final msg = rawMessage?.trim() ?? '';
  final lower = msg.toLowerCase();

  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('host lookup') ||
      lower.contains('timed out') ||
      lower.contains('unable to claim')) {
    return lang.msgGiftClaimNetworkError;
  }

  if (lower.contains('already') ||
      lower.contains('claimed') ||
      lower.contains('redeemed') ||
      lower.contains('used')) {
    return lang.giftClaimAlreadyClaimed;
  }

  if (lower.contains('expire') ||
      lower.contains('validity') ||
      lower.contains('outdated')) {
    return lang.giftClaimExpired;
  }

  if (lower.contains('invalid') ||
      lower.contains('not found') ||
      lower.contains('not exist') ||
      lower.contains('does not exist') ||
      lower.contains('incorrect') ||
      lower.contains('wrong')) {
    return lang.giftClaimInvalidCode;
  }

  if (lower.contains('server error') ||
      lower.contains('internal server') ||
      lower.contains('something went wrong')) {
    return lang.msgGiftClaimFailed;
  }

  if (msg.isNotEmpty &&
      !lower.contains('failed to save gift') &&
      !lower.contains('failed to claim')) {
    return msg;
  }

  return lang.msgGiftClaimFailed;
}

/// A gift card code is redeemable only when, after normalization, it is
/// exactly 16 characters long (empty, shorter or longer codes are rejected).
bool isValidGiftCardCodeLength(String value) =>
    _normalizeCouponCode(value).length == 16;

String _normalizeCouponCode(String value) {
  return value.trim().replaceAll(' ', '').toUpperCase();
}

/// The gifted content found in a claim response: the full [content] when the
/// response embeds it, otherwise just its [id].
class GiftedContentRef {
  const GiftedContentRef({required this.id, this.content});

  final int id;
  final Content? content;
}

/// Finds the gifted content in the claim API's `data` without assuming one
/// exact shape. Checks, in order: an embedded `movie`/`content` object (at any
/// depth), a `contentId`/`movieId`, then an object that is itself content
/// (`id` plus `type`/`contentType`). Returns null when none is present.
GiftedContentRef? giftedContentFromClaimData(Object? data, [int depth = 0]) {
  if (data == null || depth > 4) return null;

  if (data is List) {
    for (final entry in data) {
      final found = giftedContentFromClaimData(entry, depth + 1);
      if (found != null) return found;
    }
    return null;
  }
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);

  for (final key in const ['movie', 'content']) {
    final nested = map[key];
    if (nested is Map) {
      final content = Content.fromJson(Map<String, dynamic>.from(nested));
      if ((content.id ?? 0) > 0) {
        return GiftedContentRef(id: content.id!, content: content);
      }
    }
  }

  for (final key in const ['contentId', 'movieId']) {
    final id = int.tryParse('${map[key] ?? ''}');
    if (id != null && id > 0) return GiftedContentRef(id: id);
  }

  final looksLikeContent = map['type'] != null || map['contentType'] != null;
  final ownId = int.tryParse('${map['id'] ?? ''}');
  if (looksLikeContent && ownId != null && ownId > 0) {
    return GiftedContentRef(id: ownId, content: Content.fromJson(map));
  }

  for (final value in map.values) {
    if (value is Map || value is List) {
      final found = giftedContentFromClaimData(value, depth + 1);
      if (found != null) return found;
    }
  }
  return null;
}

/// Opens the details screen of the content found in [claimData]: movie and
/// short film -> movie details, series and mini-series -> series details.
/// Does nothing when the response does not identify the content.
Future<void> openGiftedContentDetails(
  NavigatorState navigator,
  Object? claimData,
) async {
  final ref = giftedContentFromClaimData(claimData);
  if (ref == null || !navigator.mounted) return;

  var content = ref.content;
  if (content?.type == null || content!.type!.trim().isEmpty) {
    // Only the id is known: load the content to learn its type.
    final dashboard =
        Provider.of<DashboardProvider>(navigator.context, listen: false);
    content = await dashboard.getContentById(ref.id);
    if (content == null || !navigator.mounted) return;
  }

  final type = content.type;
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ContentType.isMovieLike(type)
          ? MovieDetailsPage(movieId: ref.id, contentType: type)
          : SeriesDetailsPage(seriesId: ref.id, content: content!),
    ),
  );
}
