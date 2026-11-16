import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/wallet%20page/PaymentPage.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../provider/themeProvider.dart';
import '../../widgets/show_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class SeriesBillingPage extends StatefulWidget {
  final int seriesId;
  final int? seasonId;
  final int? episodeId;
  final double amount;
  final bool isSeason;
  final String? seriesTitle;
  final String? itemTitle;
  final String? rentalDuration;

  const SeriesBillingPage({
    super.key,
    required this.seriesId,
    required this.amount,
    required this.isSeason,
    this.seriesTitle,
    this.itemTitle,
    this.rentalDuration,
    this.seasonId,
    this.episodeId,
  });

  @override
  State<SeriesBillingPage> createState() => _SeriesBillingPageState();
}

class _SeriesBillingPageState extends State<SeriesBillingPage> {
  static const double _minimumRechargeAmount = 100;
  static const double _maximumRechargeAmount = 100000;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      await wallet.getBalance();
      await wallet.getTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;
    final horizontal = ResponsiveWidget.isDesktop(context)
        ? 200.0
        : ResponsiveWidget.isTablet(context)
            ? 80.0
            : 16.0;
    final totalCoins = widget.amount;

    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildTv(context, totalCoins);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // -------- Wallet Header --------
          SliverAppBar(
            automaticallyImplyLeading:
                !(kIsWeb || ResponsiveWidget.isTv(context)),
            pinned: true,
            expandedHeight: 230,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Center(
                child: Container(
                  width: ResponsiveWidget.isMobile(context)
                      ? double.infinity
                      : 500,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: ResponsiveWidget.isDesktop(context)
                        ? BorderRadius.circular(60)
                        : const BorderRadius.only(
                            bottomLeft: Radius.circular(70),
                            bottomRight: Radius.circular(70),
                          ),
                  ),
                  child: Consumer<WalletProvider>(
                    builder: (_, walletProvider, __) {
                      return Column(
                        children: [
                          const Spacer(),
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 80,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "₹ ${walletProvider.walletBalance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Available Balance",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // -------- Payment Card --------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            sliver: SliverToBoxAdapter(
              child: Consumer<WalletProvider>(
                builder: (_, provider, __) {
                  final hasBalance = provider.walletBalance >= totalCoins;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isSeason
                                ? "Season Purchase"
                                : "Episode Purchase",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Amount: ₹ ${totalCoins.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Wallet Status
                          Card(
                            color: hasBalance
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Wallet: ₹ ${provider.walletBalance.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: hasBalance
                                            ? Colors.green
                                            : theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          hasBalance
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.check,
                                      color: Colors.white),
                                  label: const Text(
                                    "Proceed to Pay",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    _showConfirmationDialog(
                                      context,
                                    );
                                  },
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.white),
                                  label: const Text(
                                    "Recharge Wallet",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _showRechargeDialog(context),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final pageContext = context;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<SeriesProvider>(
              builder: (_, provider, __) {
                final isBusy = isProcessing || provider.isPurchasing;

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Confirm Purchase"),
                  content: SizedBox(
                    width: ResponsiveWidget.isTabletOrTv(dialogContext)
                        ? 460
                        : null,
                    child: const Text("Do you want to confirm the purchase?"),
                  ),
                  actions: [
                    TextButton(
                      // Android TV: start on Cancel so a held OK can't
                      // confirm a purchase by accident.
                      autofocus: ResponsiveWidget.isAndroidTv(dialogContext),
                      onPressed:
                          isBusy ? null : () => Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor),
                      onPressed: isBusy
                          ? null
                          : () async {
                              setState(() => isProcessing = true);

                              SeriesPurchaseResult result;
                              if (widget.isSeason) {
                                result = await provider.purchaseSeason(
                                  widget.seasonId!,
                                  widget.seriesId,
                                );
                              } else {
                                result = await provider.purchaseEpisode(
                                  widget.episodeId!,
                                  widget.seriesId,
                                );
                              }

                              if (!mounted) return;
                              Navigator.pop(dialogContext);

                              if (result.success) {
                                /*  await _handlePostPurchaseInvoice(
                                  pageContext,
                                  result,
                                ); */
                                if (!mounted) return;
                                Navigator.pop(pageContext, true);
                              } else {
                                final msg = result.message.isNotEmpty
                                    ? result.message
                                    : (provider.error ??
                                        "Purchase failed. Please try again.");
                                CustomToast.show(pageContext, msg,
                                    isSuccess: false);
                              }
                            },
                      child: Text(
                        isBusy ? "Processing..." : "Confirm & Pay",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final pageContext = context;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<WalletProvider>(
              builder: (_, walletProvider, __) {
                final isBusy = isProcessing || walletProvider.isAddingBalance;

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Recharge Wallet"),
                  content: SizedBox(
                    width: ResponsiveWidget.isTabletOrTv(dialogContext)
                        ? 460
                        : null,
                    child: TextField(
                      controller: walletProvider.amountController,
                      autofocus: ResponsiveWidget.isTabletOrTv(dialogContext),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          FocusScope.of(dialogContext).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: "Enter amount",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isBusy ? null : () => Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor),
                      onPressed: isBusy
                          ? null
                          : () async {
                              final amount = double.tryParse(
                                      walletProvider.amountController.text) ??
                                  0;

                              if (amount <= 0) {
                                CustomToast.show(
                                  pageContext,
                                  "Enter a valid amount",
                                  isSuccess: false,
                                );
                                return;
                              }
                              if (amount < _minimumRechargeAmount) {
                                CustomToast.show(
                                  pageContext,
                                  "Minimum recharge amount is Rs ${_minimumRechargeAmount.toStringAsFixed(0)}",
                                  isSuccess: false,
                                );
                                return;
                              }
                              if (amount > _maximumRechargeAmount) {
                                CustomToast.show(
                                  pageContext,
                                  "Maximum recharge amount is Rs ${_maximumRechargeAmount.toStringAsFixed(0)}",
                                  isSuccess: false,
                                );
                                return;
                              }

                              setState(() => isProcessing = true);
                              Navigator.pop(dialogContext);

                              final result = await Navigator.push(
                                pageContext,
                                MaterialPageRoute(
                                  builder: (_) => PaymentPage(amount: amount),
                                ),
                              );

                              if (!mounted) return;
                              if (result is Map && result['success'] == true) {
                                _showWalletReflectLoader(pageContext);
                                final addResult =
                                    await walletProvider
                                        .onPaymentVerified(
                                          expectedAmount: amount,
                                        )
                                        .whenComplete(() {
                                  if (mounted) {
                                    Navigator.of(pageContext,
                                            rootNavigator: true)
                                        .pop();
                                  }
                                });

                                if (!mounted) return;
                                final msg = addResult['message']?.toString() ??
                                    "Recharge failed. Please try again.";
                                CustomToast.show(
                                  pageContext,
                                  msg,
                                  isSuccess: addResult['success'] == true,
                                );
                              } else {
                                CustomToast.show(
                                  pageContext,
                                  result is Map
                                      ? result['message']?.toString() ??
                                          "Payment failed. Please try again."
                                      : "Payment failed. Please try again.",
                                  isSuccess: false,
                                );
                              }
                            },
                      child: Text(
                        isBusy ? "Processing..." : "Proceed to Pay",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showWalletReflectLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text("Updating wallet balance...")),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePostPurchaseInvoice(
    BuildContext pageContext,
    SeriesPurchaseResult result,
  ) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final invoiceUrl = result.invoiceUrl?.trim() ?? '';
        final hasInvoiceUrl = invoiceUrl.isNotEmpty;
        final purchasedItem = widget.itemTitle ??
            (widget.isSeason
                    ? 'Season ${result.seasonId ?? ''}'
                    : 'Episode ${result.episodeId ?? ''}')
                .trim();

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Purchase successful',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              result.message,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInvoiceRow(
                          'Series',
                          widget.seriesTitle ?? 'Series',
                        ),
                        _buildInvoiceRow(
                          'Item',
                          purchasedItem.isEmpty
                              ? (widget.isSeason
                                  ? 'Season Purchase'
                                  : 'Episode Purchase')
                              : purchasedItem,
                        ),
                        _buildInvoiceRow(
                          'Coins Deducted',
                          '${result.coinsDeducted ?? widget.amount.toInt()}',
                        ),
                        _buildInvoiceRow(
                          'New Balance',
                          '${result.newBalance ?? 'N/A'}',
                        ),
                        _buildInvoiceRow(
                          'Invoice',
                          hasInvoiceUrl ? 'Available' : 'Not available',
                          isLast: !hasInvoiceUrl,
                        ),
                        if (hasInvoiceUrl)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              onPressed: () async {
                                final Uri url = Uri.parse(invoiceUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text("View Invoice"),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (hasInvoiceUrl)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await SharePlus.instance.share(
                            ShareParams(
                              title: 'Purchase Invoice',
                              subject: 'Purchase Invoice',
                              text:
                                  'Here is your invoice for ${widget.seriesTitle ?? 'Series'}.\n$invoiceUrl',
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Share Invoice',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (hasInvoiceUrl) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Android TV ----------------

  /// Android TV checkout: what is being rented on the left, order summary,
  /// wallet status and the primary action on the right. Uses the same
  /// amount ([widget.amount]) and the same handlers as the other layouts
  /// ([_showConfirmationDialog], [_showRechargeDialog]).
  Widget _buildTv(BuildContext context, double totalCoins) {
    final theme = Theme.of(context);
    final purchaseLabel =
        widget.isSeason ? "Season Purchase" : "Episode Purchase";
    final seriesTitle = (widget.seriesTitle ?? '').trim();
    final itemTitle = (widget.itemTitle ?? '').trim();
    final rentalDuration = (widget.rentalDuration ?? '').trim();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvDesign.pageGutter,
            16,
            TvDesign.pageGutter,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Checkout', style: TvDesign.pageTitle(theme)),
              const SizedBox(height: 2),
              Text(purchaseLabel, style: TvDesign.caption(theme)),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------- What you're renting --------
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: _tvPanel(
                          theme,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: TvDesign.imageAspectRatio,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.primaryColor
                                            .withValues(alpha: 0.55),
                                        theme.cardColor,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      widget.isSeason
                                          ? Icons.video_library_outlined
                                          : Icons.live_tv_outlined,
                                      size: 40,
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seriesTitle.isNotEmpty
                                          ? seriesTitle
                                          : purchaseLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TvDesign.sectionTitle(theme),
                                    ),
                                    if (itemTitle.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        itemTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.canvasColor
                                              .withValues(alpha: 0.85),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _tvTag(theme, purchaseLabel),
                                        if (rentalDuration.isNotEmpty)
                                          _tvTag(
                                            theme,
                                            "Rent duration: $rentalDuration",
                                            icon: Icons.schedule,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // -------- Order summary + pay --------
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Consumer<WalletProvider>(
                          builder: (_, provider, __) {
                            final hasBalance =
                                provider.walletBalance >= totalCoins;
                            final statusColor =
                                hasBalance ? Colors.green : theme.primaryColor;

                            return _tvPanel(
                              theme,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Order summary',
                                    style: TvDesign.sectionTitle(theme),
                                  ),
                                  const SizedBox(height: 10),
                                  _tvSummaryRow(theme, 'Item', purchaseLabel),
                                  const SizedBox(height: 8),
                                  _tvSummaryRow(
                                    theme,
                                    'Amount',
                                    "₹ ${totalCoins.toStringAsFixed(0)}",
                                    emphasize: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        TvDesign.cardRadius,
                                      ),
                                      border: Border.all(
                                        color: statusColor
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Wallet: ₹ ${provider.walletBalance.toStringAsFixed(2)}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // One button whose action follows the
                                  // balance (as on mobile); kept as a single
                                  // widget so focus survives a balance refresh.
                                  SizedBox(
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      autofocus: true,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(
                                        hasBalance
                                            ? Icons.check
                                            : Icons.add_circle,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        hasBalance
                                            ? "Proceed to Pay"
                                            : "Recharge Wallet",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: hasBalance
                                          ? () => _showConfirmationDialog(
                                                context,
                                              )
                                          : () => _showRechargeDialog(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tvPanel(
    ThemeData theme, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(TvDesign.panelRadius),
        border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _tvTag(ThemeData theme, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.primaryColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.canvasColor.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tvSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.canvasColor.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? theme.primaryColor : theme.canvasColor,
            fontSize: emphasize ? 18 : 12.5,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
