import 'package:flutter/material.dart';
import 'package:ott/app/pages/wallet%20page/PaymentPage.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import '../../provider/ThemeProvider.dart';
import '../../widgets/show_toast.dart';

class SeriesBillingPage extends StatefulWidget {
  final int seriesId;
  final int? seasonId;
  final int? episodeId;
  final double amount;
  final bool isSeason;

  const SeriesBillingPage({
    super.key,
    required this.seriesId,
    required this.amount,
    required this.isSeason,
    this.seasonId,
    this.episodeId,
  });

  @override
  State<SeriesBillingPage> createState() => _SeriesBillingPageState();
}

class _SeriesBillingPageState extends State<SeriesBillingPage> {
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
    final horizontal = ResponsiveWidget.isDesktop(context) ? 200.0 : 16.0;
    final totalCoins = widget.amount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // -------- Wallet Header --------
          SliverAppBar(
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
                                      "Wallet: ₹ ${provider.walletBalance.toStringAsFixed(0)}",
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
                                      totalCoins,
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
                                  onPressed: () =>
                                      _showRechargeDialog(context, provider),
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

  void _showConfirmationDialog(BuildContext context, double coins) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Purchase"),
          content: const Text("Do you want to confirm the purchase?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
              onPressed: () async {
                final provider = context.read<SeriesProvider>();

                bool ok = false;

                if (widget.isSeason) {
                  ok = await provider.purchaseSeason(
                    widget.seasonId!,
                    widget.seriesId,
                  );
                } else {
                  ok = await provider.purchaseEpisode(
                    widget.episodeId!,
                    widget.seriesId,
                  );
                }
                Navigator.pop(context);

                //if (!mounted) return;
                if (ok) {
                  Navigator.pop(context, true); // just return success
                } else {
                  final msg =
                      provider.error ?? "Purchase failed. Please try again.";
                  CustomToast.show(context, msg, isSuccess: false);
                }
              },
              child: const Text("Confirm & Pay",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRechargeDialog(BuildContext context, WalletProvider wallet) {
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
            controller: wallet.amountController,
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
                    double.tryParse(wallet.amountController.text) ?? 0;

                if (amount > 0) {
                  Navigator.pop(context);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(amount: amount),
                    ),
                  );

                  if (result == true) {
                    await wallet.addBalance(amount);
                    CustomToast.show(
                      context,
                      "Wallet recharged successfully.",
                      isSuccess: true,
                    );
                  } else {
                    CustomToast.show(
                      context,
                      "Payment Failed ❌",
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
