import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../widgets/show_toast.dart';

class WalletPage extends StatefulWidget {
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.getBalance();
        await walletProvider.getTransactionHistory();
      } catch (e, s) {
        debugPrint("WalletPage Error: $e\n$s");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).getTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: ResponsiveWidget.isDesktop(context) ? 200 : 16),
              child:
                  // isMobile
                  //     ?
                  Column(
                children: [
                  _buildBalanceCard(context),
                  const SizedBox(height: 10),
                  Divider(
                    color: theme.canvasColor,
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildTransactionSection()),
                ],
              )
              // : Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Expanded(
              //           flex: 4,
              //           child: Column(
              //             children: [
              //               _buildBalanceAnalyticsCard(context),
              //               _buildBalanceCard(context),
              //             ],
              //           )),
              //       const SizedBox(width: 20),
              //       Expanded(flex: 6, child: _buildTransactionSection()),
              //     ],
              //   ),
              );
        },
      ),
    );
  }

  /// ------------ Balance Card ------------
  Widget _buildBalanceCard(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final theme = Theme.of(context);
    final balance = walletProvider.walletBalance;
    final lang = AppLocalizations.of(context)!;

    final formattedBalance = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 1,
    ).format(balance);

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: theme.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Positioned(
                right: 1,
                top: 5,
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 80, color: Colors.white54),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.availableBalance,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedBalance,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(lang.readyToStreamYourfavorites,
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showRechargeDialog(context),
                          label: Text(
                            lang.addBalance,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }

  /// ------------ Transactions Section ------------
  Widget _buildTransactionSection() {
    return Consumer2<WalletProvider, ThemeProvider>(
      builder: (context, walletProvider, themeProvider, _) {
        final transactions = walletProvider.filteredTransactionHistory;
        final theme = themeProvider.getTheme;
        final lang = AppLocalizations.of(context)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.transactionHistory,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFilterBar(context, walletProvider),
              ],
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.receipt_long,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("No transactions found",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border.all(width: 1, color: theme.cardColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => Divider(
                          color: theme.cardColor.withOpacity(0.3),
                          thickness: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isCredit =
                              tx.status?.toLowerCase() == "amount creadited";
                          final date =
                              DateTime.fromMillisecondsSinceEpoch(tx.date ?? 0);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isCredit
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isCredit ? Colors.green : Colors.red,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx.status ?? "NA",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.canvasColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tx.reason ?? "",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: theme.canvasColor
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  DateFormat(
                                                          'dd MMM yyyy • hh:mm a')
                                                      .format(date),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.canvasColor
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '₹${tx.amount?.toStringAsFixed(2) ?? "--"}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isCredit
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Transaction ID: ${tx.id ?? "NA"}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.canvasColor
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
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
        );
      },
    );
  }

  /// ------------ Filter Bar ------------
  Widget _buildFilterBar(BuildContext context, WalletProvider walletProvider) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).getTheme;
    final lang = AppLocalizations.of(context)!;

    return Row(
      children: [
        OutlinedButton.icon(
          icon: Icon(
            Icons.date_range,
            color: theme.canvasColor,
          ),
          label: Text(
            _startDate == null || _endDate == null
                ? lang.selectDate
                : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
            style: TextStyle(
              color: theme.canvasColor,
            ),
          ),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _startDate = picked.start;
                _endDate = picked.end;
              });
              await walletProvider.filterDateWiseTransaction(
                  _startDate, _endDate);
            }
          },
        ),
        _startDate != null || _endDate != null
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  walletProvider.resetTransactionFilters();
                },
                icon: Icon(Icons.clear_sharp))
            : SizedBox(),
      ],
    );
  }

  /// ------------ Recharge Dialog ------------
  void _showRechargeDialog(BuildContext context) {
    final controller = TextEditingController();
    final lang = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.rechargeWallet),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: lang.enterAmountMin10,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel)),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount < 10) {
                CustomToast.show(context, lang.minimumRechargeAmountIs10,
                    isSuccess: false);
                return;
              }

              final walletProvider =
                  Provider.of<WalletProvider>(context, listen: false);
              walletProvider.addBalance(amount);
              Navigator.pop(context);
              CustomToast.show(context,
                  "${lang.walletRechargedWith} ${amount.toStringAsFixed(2)}",
                  isSuccess: true);
            },
            child: Text(lang.recharge),
          ),
        ],
      ),
    );
  }
}
