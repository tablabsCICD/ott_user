import 'dart:developer';

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
import '../../provider/ThemeProvider.dart';
import '../../provider/dashboardProvider.dart';
import '../../widgets/show_toast.dart';

class BillingPage extends StatefulWidget {
  final Content movie;
  int giftCount;

  BillingPage({
    super.key,
    required this.movie,
    this.giftCount = 0,
  });

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  double moviePrice = 0.0;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.getBalance();
    await walletProvider.getTransactionHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    moviePrice = double.tryParse(widget.movie.price.toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ResponsiveWidget.isDesktop(context)
                ? _buildDesktopLayout(context, provider)
                : _buildMobileLayout(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WalletProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(flex: 4, child: _buildPaymentWidget(provider)),
        const SizedBox(width: 20),
        Flexible(flex: 6, child: _buildTransactionSection()),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, WalletProvider provider) {
    return Column(
      children: [
        _buildPaymentWidget(provider),
        const SizedBox(height: 20),
        Expanded(child: _buildTransactionSection()),
      ],
    );
  }

  Widget _buildPaymentWidget(WalletProvider provider) {
    double totalPrice =
        moviePrice * (widget.giftCount == 0 ? 1 : widget.giftCount);
    final theme = Theme.of(context);
    TextEditingController couponCodeController = TextEditingController();
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.movie.title ?? "",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            widget.giftCount == 0
                ? Text("Movie Price: ₹${moviePrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18))
                : Text(
                    "₹${moviePrice.toStringAsFixed(2)} × ${widget.giftCount} Gifts",
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              "Total: ₹${totalPrice.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: provider.walletBalance >= totalPrice
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: provider.walletBalance >= totalPrice
                            ? Colors.green
                            : theme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Wallet Balance: ₹${provider.walletBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: provider.walletBalance >= totalPrice
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
            provider.walletBalance >= totalPrice
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: Icon(
                      Icons.payment,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Pay Now",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      _showConfirmationDialog(
                        provider,
                        totalPrice,
                        widget.movie.id!,
                        widget.giftCount,
                      );
                    })
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: Icon(Icons.add_circle, color: Colors.white),
                    label: Text(
                      "Recharge Wallet",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _showRechargeDialog(
                      context,
                      provider,
                    ),
                  ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              width: ResponsiveWidget.isMobile(context)
                                  ? double.infinity
                                  : 400,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Description
                                      Text(
                                        "Enter Gift Card Number",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.canvasColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Input field
                                      CustomTextField(
                                        backgroundColor:
                                            theme.scaffoldBackgroundColor,
                                        isDigits: true,
                                        controller: couponCodeController,
                                        hintText: "Enter 16 Digit Number",
                                        textInputType: TextInputType.text,
                                      ),
                                      const SizedBox(height: 24),

                                      // Action buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                  color: Colors.grey[300]),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final provider =
                                                  Provider.of<GiftProvider>(
                                                      context,
                                                      listen: false);

                                              if (couponCodeController.text
                                                  .trim()
                                                  .isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Please enter a coupon code")),
                                                );
                                                return;
                                              }

                                              try {
                                                final result = await provider
                                                    .useGiftByCoupon(
                                                        couponCodeController
                                                            .text
                                                            .trim());
                                                if (couponCodeController
                                                            .text.length >
                                                        16 ||
                                                    couponCodeController
                                                            .text.length <
                                                        16) {
                                                  CustomToast.show(
                                                    context,
                                                    "Coupon code is invalid, try again.",
                                                    isSuccess: false,
                                                  );
                                                  return;
                                                }
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
                                              } catch (e) {
                                                CustomToast.show(
                                                  context,
                                                  "Something went wrong",
                                                  isSuccess: false,
                                                );
                                              }
                                            },
                                            child: const Text(
                                              "Redeem",
                                              style: TextStyle(
                                                  color: Colors.white),
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
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: theme.canvasColor,
                      ),
                      children: [
                        TextSpan(text: 'Have a '),
                        TextSpan(
                          text: '${widget.movie.title}',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ),
                        ),
                        TextSpan(text: ' Gift Card?')
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Transaction History",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.receipt_long,
                                  size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("No transactions yet",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: theme.cardColor.withOpacity(0.2)),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isCredit =
                                tx.status?.toLowerCase() == "amount creadited";
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                tx.date ?? 0);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                tx.status ?? "NA",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                  "${tx.reason ?? ''}\n${DateFormat('dd MMM yyyy • hh:mm a').format(date)}"),
                              isThreeLine: true,
                              trailing: Text(
                                '₹${tx.amount?.toStringAsFixed(2) ?? "--"}',
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
        );
      },
    );
  }

  void _showConfirmationDialog(
    WalletProvider provider,
    double moviePrice,
    int movieID,
    int giftCount,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Confirm Purchase",
            style: TextStyle(color: theme.canvasColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Do you want to confirm the purchase?",
                  style: TextStyle(color: theme.canvasColor)),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: theme.canvasColor)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
              onPressed: () async {
                provider.deductBalance(moviePrice, movieID);
                (giftCount > 0)
                    ? await Provider.of<GiftProvider>(context, listen: false)
                        .saveUserGift(widget.movie, giftCount)
                    : await Provider.of<PurchaseContentProvider>(context,
                            listen: false)
                        .saveUserContent(widget.movie);
                CustomToast.show(
                  context,
                  "Payment successful! Enjoy your movie 🎬",
                  isSuccess: true,
                );
                await Provider.of<DashboardProvider>(context, listen: false)
                    .getContentById(widget.movie.id!);
                Navigator.pop(context);
                giftCount > 0
                    ? (Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GiftedMoviesPage())))
                    : Navigator.pop(context);
              },
              child: const Text(
                "Confirm & Pay",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRechargeDialog(
      BuildContext context, WalletProvider walletProvider) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Recharge Wallet"),
          content: TextField(
            controller: walletProvider.amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Enter amount",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
              onPressed: () async {
                final amount =
                    double.tryParse(walletProvider.amountController.text) ?? 0;

                if (amount > 0) {
                  Navigator.pop(context); // close dialog before navigation

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(amount: amount),
                    ),
                  );

                  if (result == true) {
                    // Razorpay payment success
                    walletProvider.addBalance(amount);
                    CustomToast.show(
                      context,
                      "Wallet recharged with ₹${amount.toStringAsFixed(2)}",
                      isSuccess: true,
                    );
                  } else if (result == false) {
                    // Payment failed
                    CustomToast.show(
                      context,
                      "Payment Failed ❌ Try again",
                      isSuccess: false,
                    );
                  }
                }
              },
              child: const Text("Proceed to Pay"),
            ),
          ],
        );
      },
    );
  }
}
