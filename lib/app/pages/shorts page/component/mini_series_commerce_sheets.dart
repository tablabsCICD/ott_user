import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/services/coupon_service.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/core/services/mini_series_commerce_service.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/mini_series_commerce_models.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the "Buy Full Mini Series" sheet. Resolves to true after the backend
/// confirms the purchase (or reports that everything is already owned).
Future<bool> showMiniSeriesFullPurchaseSheet(
  BuildContext context, {
  required int shortId,
  required String title,
}) async {
  final purchased = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MiniSeriesCommerceSheet(
      mode: _SheetMode.fullPurchase,
      shortId: shortId,
      title: title,
    ),
  );
  return purchased == true;
}

/// Opens the "Gift Mini Series" sheet. Resolves to true after the backend
/// confirms the gift.
Future<bool> showMiniSeriesGiftSheet(
  BuildContext context, {
  required int shortId,
  required String title,
}) async {
  final gifted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MiniSeriesCommerceSheet(
      mode: _SheetMode.gift,
      shortId: shortId,
      title: title,
    ),
  );
  return gifted == true;
}

enum _SheetMode { fullPurchase, gift }

class _MiniSeriesCommerceSheet extends StatefulWidget {
  const _MiniSeriesCommerceSheet({
    required this.mode,
    required this.shortId,
    required this.title,
  });

  final _SheetMode mode;
  final int shortId;
  final String title;


  @override
  State<_MiniSeriesCommerceSheet> createState() =>
      _MiniSeriesCommerceSheetState();
}

class _MiniSeriesCommerceSheetState extends State<_MiniSeriesCommerceSheet> {
  final MiniSeriesCommerceService _service = MiniSeriesCommerceService();
  final TextEditingController _countController =
      TextEditingController(text: '1');

  MiniSeriesPurchaseQuote? _quote;
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  String? _countError;

  /// Confirmed gift purchase (codes from the backend). When set, the sheet
  /// shows the gift codes instead of the purchase form.
  MiniSeriesGiftPurchaseResult? _giftResult;

  // One key per checkout attempt, so a retry after a network failure cannot
  // charge twice. Regenerated whenever the price/quantity being paid changes.
  String _idempotencyKey = CouponService.generateIdempotencyKey();

  bool get _isGift => widget.mode == _SheetMode.gift;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    context.read<WalletProvider>().getBalance();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final quote = await _service.fetchQuote(
        widget.shortId,
        forGift: _isGift,
        title: widget.title,
      );
      if (!mounted) return;
      if (_isGift) {
        _logGift('[MINI_SERIES_GIFT_DETAILS]', [
          'MINI SERIES ID: ${widget.shortId}',
          'GIFT UNIT PRICE: ${quote.giftPrice.toStringAsFixed(2)}',
          'MIN QUANTITY: ${quote.minGiftCount}',
          'MAX QUANTITY: ${quote.maxGiftCount ?? 'no max'}',
        ]);
      }
      setState(() {
        _quote = quote;
        _loading = false;
        _idempotencyKey = CouponService.generateIdempotencyKey();
        if (_isGift) {
          _countController.text = '${quote.minGiftCount}';
          _countError = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? get _giftCount => int.tryParse(_countController.text.trim());

  String? _validateGiftCount(AppLocalizations lang) {
    final quote = _quote;
    if (quote == null) return null;
    final count = _giftCount;
    final min = quote.minGiftCount < 1 ? 1 : quote.minGiftCount;
    final max = quote.maxGiftCount;
    final valid =
        count != null && count >= min && (max == null || count <= max);
    if (valid) return null;
    return max == null
        ? lang.miniSeriesGiftCountMin(min)
        : lang.miniSeriesGiftCountRange(min, max);
  }

  /// Amount that will be charged, from backend prices only.
  double? get _payableAmount {
    final quote = _quote;
    if (quote == null) return null;
    if (!_isGift) return quote.fullPurchasePrice;
    final count = _giftCount;
    if (count == null || count <= 0) return null;
    return quote.giftPrice * count;
  }

  /// Why Confirm & Pay is disabled, or null when it is enabled. This is the
  /// single source of truth for the button and for its debug log.
  ///
  /// Wallet balance does not disable the button: as in the existing part
  /// purchase flow, tapping with too little balance opens the recharge dialog.
  String? _disabledReason() {
    final quote = _quote;
    if (_loading) return 'DATA_LOADING';
    if (quote == null) return 'PRICING_NOT_LOADED: ${_loadError ?? 'unknown'}';
    if (widget.shortId <= 0) return 'INVALID_MINI_SERIES_ID';
    if (_submitting) return 'REQUEST_IN_PROGRESS';
    if (_isGift) {
      if (!quote.giftAvailable) return 'GIFT_NOT_AVAILABLE';
      if (quote.giftPrice <= 0) return 'INVALID_GIFT_PRICE';
      final lang = AppLocalizations.of(context)!;
      if (_validateGiftCount(lang) != null) {
        return 'INVALID_QUANTITY: ${_countController.text.trim()}';
      }
    } else {
      if (quote.alreadyOwnsAll) return 'ALREADY_OWNS_ALL_PARTS';
      if (!quote.fullPurchaseAvailable || quote.purchasablePartCount <= 0) {
        return 'NO_ELIGIBLE_PURCHASABLE_PARTS';
      }
    }
    final amount = _payableAmount;
    if (amount == null || amount <= 0) return 'INVALID_TOTAL_AMOUNT';
    return null;
  }

  void _logGift(String tag, List<String> lines) {
    if (!kDebugMode) return;
    for (final line in lines) {
      debugPrint('$tag $line', wrapWidth: 1024);
    }
  }

  String? _lastLoggedButtonState;

  void _logButtonState(double walletBalance, String? reason) {
    if (!kDebugMode) return;
    final quote = _quote;
    final amount = _payableAmount;
    final tag = _isGift
        ? '[MINI_SERIES_GIFT_BUTTON]'
        : '[MINI_SERIES_FULL_PURCHASE_BUTTON]';
    final lines = <String>[
      '========== CONFIRM & PAY BUTTON STATE ==========',
      'FLOW: ${_isGift ? 'MINI_SERIES_GIFT' : 'MINI_SERIES_FULL_PURCHASE'}',
      'MINI SERIES ID: ${widget.shortId}',
      if (_isGift) ...[
        'SELECTED QUANTITY: ${_countController.text.trim()}',
        'PRICE PER GIFT: ${quote?.giftPrice.toStringAsFixed(2) ?? '<not loaded>'}',
        'MIN QUANTITY: ${quote?.minGiftCount ?? '<not loaded>'}',
        'MAX QUANTITY: ${quote == null ? '<not loaded>' : quote.maxGiftCount ?? 'no max'}',
      ] else ...[
        'TOTAL PARTS: ${quote?.totalParts ?? '<not loaded>'}',
        'ELIGIBLE PURCHASABLE PARTS: ${quote?.purchasablePartCount ?? '<not loaded>'}',
        'ALREADY OWNED PARTS: ${quote?.ownedPartCount ?? '<not loaded>'}',
        'FREE PARTS: ${quote?.freePartCount ?? '<not loaded>'}',
      ],
      'TOTAL AMOUNT: ${amount?.toStringAsFixed(2) ?? '<none>'}',
      'WALLET BALANCE: ${walletBalance.toStringAsFixed(2)}',
      'WALLET SUFFICIENT: ${amount != null && walletBalance >= amount}',
      'IS DATA LOADED: ${!_loading && quote != null}',
      'IS CONTRACT VALID: ${quote != null}',
      'IS VALID: ${reason == null}',
      'IS LOADING: ${_loading || _submitting}',
      'BUTTON ENABLED: ${reason == null}',
      'DISABLED REASON: ${reason ?? '<none>'}',
      '===============================================',
    ];
    final signature = lines.join('|');
    if (signature == _lastLoggedButtonState) return;
    _lastLoggedButtonState = signature;
    for (final line in lines) {
      debugPrint('$tag $line', wrapWidth: 1024);
    }
  }

  Future<void> _submit() async {
    final quote = _quote;
    final amount = _payableAmount;
    if (quote == null || amount == null || _disabledReason() != null) {
      return;
    }
    final lang = AppLocalizations.of(context)!;

    if (_isGift) {
      final error = _validateGiftCount(lang);
      if (error != null) {
        setState(() => _countError = error);
        return;
      }
    }

    final wallet = context.read<WalletProvider>();
    setState(() => _submitting = true);
    await wallet.getBalance();
    if (!mounted) return;
    if (wallet.walletBalance < amount) {
      setState(() => _submitting = false);
      await _showInsufficientBalance();
      return;
    }

    final result = _isGift
        ? await _service.purchaseGift(
            shortId: widget.shortId,
            giftCount: _giftCount!,
            expectedTotal: amount,
            idempotencyKey: _idempotencyKey,
          )
        : await _service.purchaseFull(
            shortId: widget.shortId,
            expectedAmount: amount,
            idempotencyKey: _idempotencyKey,
          );
    if (!mounted) return;

    // Refresh the balance from the backend either way; never assume.
    await wallet.getBalance();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (_isGift && result.success) {
      final giftResult = MiniSeriesGiftPurchaseResult.fromJson(
        result.data,
        envelope: result.envelope,
      );
      _logGift('[MINI_SERIES_GIFT_PURCHASE]', [
        'CONFIRMED: transactionId=${giftResult.transactionId} '
            'codes=${giftResult.gifts.length} '
            'totalAmount=${giftResult.totalAmount.toStringAsFixed(2)} '
            'idempotentReplay=${giftResult.idempotentReplay}',
      ]);
      CustomToast.show(context, lang.miniSeriesGiftSuccess, isSuccess: true);
      setState(() => _giftResult = giftResult);
      return;
    }

    if (!_isGift && (result.success || result.isAlreadyOwned)) {
      CustomToast.show(
        context,
        result.isAlreadyOwned
            ? lang.miniSeriesAlreadyOwned
            : lang.miniSeriesPurchaseSuccess,
        isSuccess: true,
      );
      Navigator.pop(context, true);
      return;
    }

    // A response arrived, so this attempt is finished: the next tap is a new
    // purchase attempt with a new key. With no response (network failure)
    // the outcome is uncertain, so the same key is kept and a retry replays
    // the original purchase instead of paying twice.
    if (!result.isNetworkFailure) {
      _idempotencyKey = CouponService.generateIdempotencyKey();
    }

    if (_isGift) {
      final status = result.statusCode;
      if (status == 409) {
        CustomToast.show(context, lang.miniSeriesGiftConflict, isWarning: true);
        return;
      }
      if (status == 404) {
        CustomToast.show(
            context, '${lang.miniSeriesGiftUnavailable}\n${result.message}',
            isSuccess: false);
        return;
      }
      if (result.hasInsufficientBalanceData) {
        // Swagger MiniSeriesInsufficientBalanceData: requiredAmount and
        // availableBalance come from the backend, not from local maths.
        await _showInsufficientBalance(
          backendMessage: lang.miniSeriesGiftInsufficientBalance(
            (result.requiredAmount ?? 0).toStringAsFixed(2),
            (result.availableBalance ?? 0).toStringAsFixed(2),
          ),
        );
        return;
      }
      CustomToast.show(context, result.message, isSuccess: false);
      return;
    }

    if (result.isInsufficientBalance) {
      await _showInsufficientBalance();
      return;
    }
    if (result.isPriceChanged) {
      CustomToast.show(context, lang.miniSeriesPriceChanged, isWarning: true);
      await _loadQuote();
      return;
    }
    CustomToast.show(context, result.message, isSuccess: false);
  }

  Future<void> _showInsufficientBalance({String? backendMessage}) async {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.shortsInsufficientBalance,
            style: TextStyle(
                color: theme.primaryColor, fontWeight: FontWeight.bold)),
        content: Text(backendMessage ?? lang.walletInsufficientBalanceRecharge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // WalletPage owns recharge, including platform payment rules.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletPage()),
              );
            },
            child: Text(lang.recharge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isGift ? lang.miniSeriesGiftTitle : lang.miniSeriesBuyFull,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                if (_giftResult != null)
                  ..._giftResultView(_giftResult!, lang, theme)
                else
                  ..._body(lang, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(AppLocalizations lang, ThemeData theme) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final quote = _quote;
    if (quote == null) {
      return [
        Text(_loadError ?? lang.authSomethingWentWrong),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loadQuote,
            child: Text(lang.retry),
          ),
        ),
      ];
    }

    final unavailableMessage = _isGift
        ? (quote.giftAvailable ? null : lang.miniSeriesGiftNotAvailable)
        : quote.alreadyOwnsAll
            ? lang.miniSeriesAlreadyOwned
            : (quote.fullPurchaseAvailable
                ? null
                : lang.miniSeriesFullNotAvailable);

    return [
      if (_isGift)
        ..._giftDetails(quote, lang)
      else
        ..._fullDetails(quote, lang),
      const SizedBox(height: 16),
      Consumer<WalletProvider>(
        builder: (_, wallet, __) {
          final amount = _payableAmount;
          final enough = amount != null && wallet.walletBalance >= amount;
          return Text(
            lang.billingWalletAmount(wallet.walletBalance.toStringAsFixed(2)),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enough ? Colors.green : theme.primaryColor,
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      if (unavailableMessage != null)
        Consumer<WalletProvider>(builder: (_, wallet, __) {
          _logButtonState(wallet.walletBalance, _disabledReason());
          return Text(unavailableMessage,
              style: TextStyle(color: theme.primaryColor));
        })
      else
        Consumer<WalletProvider>(builder: (_, wallet, __) {
          final disabledReason = _disabledReason();
          _logButtonState(wallet.walletBalance, disabledReason);
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: disabledReason != null ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      lang.billingConfirmAndPay,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          );
        }),
    ];
  }

  List<Widget> _fullDetails(
      MiniSeriesPurchaseQuote quote, AppLocalizations lang) {
    final theme = Theme.of(context);
    final parts = [...quote.parts]
      ..sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return [
      Text(lang.miniSeriesTotalParts(quote.totalParts)),
      Text(lang.miniSeriesPurchasableParts(quote.purchasablePartCount)),
      if (quote.ownedPartCount > 0)
        Text(lang.miniSeriesOwnedParts(quote.ownedPartCount)),
      if (quote.freePartCount > 0)
        Text(lang.miniSeriesFreeParts(quote.freePartCount)),
      if (parts.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              for (final part in parts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Text(lang.miniSeriesPartLabel(part.partNumber))),
                      Text(
                        part.owned
                            ? lang.miniSeriesPartOwned
                            : part.free
                                ? lang.miniSeriesPartFree
                                : '₹${part.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: part.purchasable ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        lang.miniSeriesFullPrice(quote.fullPurchasePrice.toStringAsFixed(2)),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    ];
  }

  String _formatExpiry(DateTime? date) {
    if (date == null) return '-';
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.yMMMd(locale).add_jm().format(date);
    } catch (_) {
      return DateFormat.yMMMd().add_jm().format(date);
    }
  }

  Future<void> _copyGiftCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    CustomToast.show(context, AppLocalizations.of(context)!.copied,
        isSuccess: true);
  }

  Future<void> _shareGiftCode(String code) async {
    final lang = AppLocalizations.of(context)!;
    await SharePlus.instance.share(
      ShareParams(
        // Code plus the existing gift link (filmytell.com/gift/{code}), which
        // the app's gift deep-link flow opens in the claim dialog.
        text: '${lang.miniSeriesGiftShareText(widget.title, code)}\n'
            '${GiftDeepLinkService.buildGiftUrl(code)}',
      ),
    );
  }

  /// Confirmed purchase: one row per single-use code, with copy and share.
  List<Widget> _giftResultView(
    MiniSeriesGiftPurchaseResult result,
    AppLocalizations lang,
    ThemeData theme,
  ) {
    return [
      if (result.idempotentReplay) ...[
        Text(lang.miniSeriesGiftReplayNote,
            style: const TextStyle(color: Colors.amber)),
        const SizedBox(height: 12),
      ],
      Text(lang.miniSeriesGiftCodesTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(lang.miniSeriesGiftCodesHint, style: theme.textTheme.bodySmall),
      const SizedBox(height: 12),
      for (final gift in result.gifts)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      gift.giftCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(lang.miniSeriesGiftCodeStatus(gift.status),
                        style: theme.textTheme.bodySmall),
                    Text(
                      lang.miniSeriesGiftCodeExpiry(
                          _formatExpiry(gift.expiryDate ?? result.expiryDate)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: lang.giftCopyCouponCode,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyGiftCode(gift.giftCode),
              ),
              IconButton(
                tooltip: lang.cardShare,
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _shareGiftCode(gift.giftCode),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      Text(lang.miniSeriesGiftTotalPaid(result.totalAmount.toStringAsFixed(2)),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: theme.primaryColor)),
      if (result.transactionId.isNotEmpty)
        Text(lang.miniSeriesGiftTransaction(result.transactionId),
            style: theme.textTheme.bodySmall),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(lang.done,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    ];
  }

  List<Widget> _giftDetails(
      MiniSeriesPurchaseQuote quote, AppLocalizations lang) {
    final theme = Theme.of(context);
    final total = _payableAmount;
    return [
      Text(lang.miniSeriesGiftPricePerGift(quote.giftPrice.toStringAsFixed(2))),
      const SizedBox(height: 12),
      Text(lang.miniSeriesGiftHowMany),
      const SizedBox(height: 8),
      TextField(
        controller: _countController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: !_submitting,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          errorText: _countError,
        ),
        onChanged: (_) => setState(() {
          // Show the range error as the user types: an invalid quantity now
          // disables Confirm & Pay, so the reason must be visible.
          _countError = _validateGiftCount(lang);
          _logGift('[MINI_SERIES_GIFT_VALIDATION]', [
            'QUANTITY: ${_countController.text.trim()} | '
                'RANGE: ${quote.minGiftCount}..${quote.maxGiftCount ?? 'no max'} | '
                'TOTAL: ${_payableAmount?.toStringAsFixed(2) ?? '<none>'} | '
                'VALID: ${_countError == null}'
                '${_countError == null ? '' : ' | ERROR: $_countError'}',
          ]);
          // A different quantity is a different checkout attempt.
          _idempotencyKey = CouponService.generateIdempotencyKey();
        }),
      ),
      const SizedBox(height: 12),
      Text(
        lang.billingTotalAmount((total ?? 0).toStringAsFixed(2)),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    ];
  }
}
