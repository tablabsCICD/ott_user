// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/pages/gifted%20movies%20page/GiftedMoviesPage.dart';
import 'package:ott/app/pages/wallet%20page/PaymentPage.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import '../../provider/themeProvider.dart';
import '../../provider/dashboardProvider.dart';
import '../../widgets/show_toast.dart';

class MovieBillingPage extends StatefulWidget {
  final Content movie;
  int giftCount;

  MovieBillingPage({
    super.key,
    required this.movie,
    this.giftCount = 0,
  });

  @override
  State<MovieBillingPage> createState() => _MovieBillingPageState();
}

class _MovieBillingPageState extends State<MovieBillingPage> {
  double moviePrice = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.getBalance();
      await walletProvider.getTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;
    final horizontal = ResponsiveWidget.isDesktop(context) ? 200.0 : 16.0;

    moviePrice = double.tryParse(widget.movie.price.toString()) ?? 0.0;
    final totalCoins =
        moviePrice * (widget.giftCount == 0 ? 1 : widget.giftCount);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// -------- Extended Curved Header --------
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
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
                          Icon(
                            Icons.account_balance_wallet,
                            size: 80,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "₹ ${walletProvider.walletBalance.toStringAsFixed(0)}",
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

          /// -------- Payment Card --------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
            sliver: SliverToBoxAdapter(
              child: Consumer<WalletProvider>(
                builder: (_, provider, __) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.movie.title ?? "",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          widget.giftCount == 0
                              ? Text(
                                  "Price: ₹ ${moviePrice.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 16),
                                )
                              : Text(
                                  "₹ ${moviePrice.toStringAsFixed(0)} × ${widget.giftCount} Gifts",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                          const SizedBox(height: 6),
                          Text(
                            "Total: ₹ ${totalCoins.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// Wallet Status
                          Card(
                            color: provider.walletBalance >= totalCoins
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image.asset(ImageConstant.coin, width: 22),
                                  //const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Wallet: ₹ ${provider.walletBalance.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            provider.walletBalance >= totalCoins
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

                          provider.walletBalance >= totalCoins
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    _showConfirmationDialog(
                                      provider,
                                      totalCoins,
                                      widget.movie.id!,
                                      widget.giftCount,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _showRechargeDialog(context),
                                ),

                          const SizedBox(height: 10),

                          /// Gift Card Link
                          Center(
                            child: InkWell(
                              onTap: _showGiftDialog,
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(color: theme.canvasColor),
                                  children: [
                                    const TextSpan(text: 'Have a '),
                                    TextSpan(
                                      text: widget.movie.title ?? "",
                                      style:
                                          TextStyle(color: theme.primaryColor),
                                    ),
                                    const TextSpan(text: ' Gift Card?')
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// -------- History --------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
            sliver: SliverToBoxAdapter(child: _buildTransactionSection()),
          ),
        ],
      ),
    );
  }

  // ---------------- History ----------------
  Widget _buildTransactionSection() {
    return Consumer2<WalletProvider, ThemeProvider>(
      builder: (context, walletProvider, themeProvider, _) {
        final transactions = walletProvider.filteredTransactionHistory;
        final theme = themeProvider.getTheme;

        return Card(
          color: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Transaction History",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: transactions.isEmpty
                        ? const Center(
                            child: Text("No transactions yet",
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => Divider(
                                color: theme.cardColor.withOpacity(0.2)),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              final isCredit =
                                  tx.action?.toLowerCase() == "credit";
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  tx.date ?? 0);

                              return ListTile(
                                // leading:
                                //     Image.asset(ImageConstant.coin, width: 22),
                                title: Text(tx.status ?? "NA",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    "${tx.reason ?? ''}\n${DateFormat('dd MMM yyyy • hh:mm a').format(date)}"),
                                isThreeLine: true,
                                trailing: Text(
                                  "₹ ${isCredit ? "+" : "-"}${tx.amount?.toStringAsFixed(0) ?? "--"}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? Colors.green : Colors.red,
                                  ),
                                ),
                              );
                            },
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

  // ---------------- Gift Dialog ----------------
  void _showGiftDialog() {
    final theme = Theme.of(context);
    final couponCodeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
              child: Stack(
                children: [
                  Positioned(
                    top: 1,
                    left: 1,
                    right: 1,
                    bottom: 1,
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
                      const Text("Enter Gift Card Number"),
                      const SizedBox(height: 6),
                      CustomTextField(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        isDigits: true,
                        controller: couponCodeController,
                        hintText: "Enter 16 Digit Number",
                        textInputType: TextInputType.text,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final provider = Provider.of<GiftProvider>(
                                  context,
                                  listen: false);

                              if (couponCodeController.text.trim().length !=
                                  16) {
                                CustomToast.show(
                                  context,
                                  "Coupon code is invalid",
                                  isSuccess: false,
                                );
                                return;
                              }

                              final result = await provider.useGiftByCoupon(
                                  couponCodeController.text.trim());

                              if (result["success"] == true) {
                                CustomToast.show(
                                  context,
                                  "Coupon applied successfully",
                                  isSuccess: true,
                                );
                                Navigator.pop(context, true);
                              } else {
                                CustomToast.show(
                                  context,
                                  "Failed to apply coupon",
                                  isSuccess: false,
                                );
                              }
                            },
                            child: const Text("Redeem"),
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
    );
  }

  // ---------------- Confirmation ----------------
  void _showConfirmationDialog(
    WalletProvider provider,
    double coins,
    int movieID,
    int giftCount,
  ) {
    final pageContext = context;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer3<WalletProvider, GiftProvider,
                PurchaseContentProvider>(
              builder: (_, walletProvider, giftProvider, purchaseProvider, __) {
                final isBusy = isProcessing ||
                    walletProvider.isDeductingBalance ||
                    giftProvider.isSavingGift ||
                    purchaseProvider.isSavingContent;
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Confirm Purchase"),
                  content: const Text("Do you want to confirm the purchase?"),
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
                              setState(() => isProcessing = true);
                              Navigator.pop(dialogContext);

                              try {
                                final walletResult =
                                    await provider.deductBalance(
                                  coins,
                                  movieID,
                                );
                                if (walletResult['success'] != true) {
                                  throw Exception(
                                    walletResult['message']?.toString() ??
                                        'Wallet deduction failed.',
                                  );
                                }

                                if (giftCount > 0) {
                                  final giftResult =
                                      await Provider.of<GiftProvider>(
                                    pageContext,
                                    listen: false,
                                  ).saveUserGift(widget.movie, giftCount);
                                  if (giftResult['success'] != true) {
                                    throw Exception(
                                      giftResult['message']?.toString() ??
                                          'Gift purchase failed.',
                                    );
                                  }
                                } else {
                                  final purchaseResult = await Provider.of<
                                      PurchaseContentProvider>(
                                    pageContext,
                                    listen: false,
                                  ).saveUserContent(widget.movie);
                                  if (purchaseResult['success'] != true) {
                                    throw Exception(
                                      purchaseResult['message']?.toString() ??
                                          'Unable to grant movie access.',
                                    );
                                  }
                                }

                                Provider.of<DashboardProvider>(
                                  pageContext,
                                  listen: false,
                                ).getContentById(widget.movie.id!).catchError((
                                  error,
                                ) {
                                  debugPrint(
                                    'Dashboard refresh failed after purchase: $error',
                                  );
                                });

                                if (!mounted) return;
                                CustomToast.show(
                                  pageContext,
                                  "Payment successful! Enjoy your content 🎬",
                                  isSuccess: true,
                                );

                                if (giftCount > 0) {
                                  Navigator.pushReplacement(
                                    pageContext,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            GiftedMoviesPage()),
                                  );
                                } else {
                                  Navigator.pop(pageContext, true);
                                }
                              } catch (error) {
                                if (!mounted) return;
                                CustomToast.show(
                                  pageContext,
                                  error.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                  isSuccess: false,
                                );
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

  // ---------------- Recharge ----------------
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
              builder: (_, provider, __) {
                final isBusy = isProcessing || provider.isAddingBalance;

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Recharge Wallet"),
                  content: TextField(
                    controller: provider.amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter amount",
                      border: OutlineInputBorder(),
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
                                      provider.amountController.text) ??
                                  0;

                              if (amount <= 0) {
                                CustomToast.show(
                                  pageContext,
                                  "Enter a valid amount",
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
                                final addResult =
                                    await provider.onPaymentVerified();

                                if (!mounted) return;
                                if (addResult['success'] == true) {
                                  CustomToast.show(
                                    pageContext,
                                    "Wallet recharged successfully.",
                                    isSuccess: true,
                                  );
                                } else {
                                  final msg =
                                      addResult['message']?.toString() ??
                                          "Recharge failed. Please try again.";
                                  CustomToast.show(
                                    pageContext,
                                    msg,
                                    isSuccess: false,
                                  );
                                }
                              } else {
                                CustomToast.show(
                                  pageContext,
                                  "Payment Failed ❌",
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
}
