import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/pages/wallet page/AppleWalletRechargeScreen.dart';
import 'package:ott/app/pages/wallet page/PaymentPage.dart';
import 'package:ott/app/pages/wallet page/wallet_recharge_summary_dialog.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/data/models/response/addWalletResponse.dart';
import 'package:ott/data/models/response/walletHistory.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

import '../../widgets/show_toast.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  static const double _minimumRechargeAmount = 100;
  static const double _maximumRechargeAmount = 100000;

  bool get _isIosWallet =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = Provider.of<WalletProvider>(context, listen: false);
      await p.getBalance();
      await p.getTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).getTheme;
    final horizontal = ResponsiveWidget.isDesktop(context)
        ? 200.0
        : ResponsiveWidget.isTablet(context)
            ? 80.0
            : 16.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          /// -------- Extended AppBar with Wallet --------
          SliverAppBar(
            automaticallyImplyLeading:
                !(kIsWeb || ResponsiveWidget.isTv(context)),
            pinned: true,
            expandedHeight: 280,
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            // actions: [
            //   _buildFilterBar(context),
            // ],
            actionsPadding: EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                children: [
                  Container(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  Center(
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

                              const SizedBox(height: 6),

                              /// Balance
                              Text(
                                "₹ ${walletProvider.walletBalance.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Text(
                                "Available Balance",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// CTA
                              _tvFocus(
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: theme.primaryColor,
                                    minimumSize:
                                        ResponsiveWidget.isTabletOrTv(context)
                                            ? const Size(220, 52)
                                            : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _handleRechargeTap,
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    "Recharge Wallet",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: _handleRechargeTap,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isIosWallet)
            const SliverToBoxAdapter(
              child: AppleWalletRechargeScreen(
                showAppBar: false,
                popOnSuccess: false,
              ),
            ),

          /// -------- Header + Filter --------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transaction History",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  //_buildFilterBar(context),
                ],
              ),
            ),
          ),

          /// -------- History List --------
          Consumer<WalletProvider>(
            builder: (_, p, __) {
              final list = p.filteredTransactionHistory;

              if (list.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No transactions")),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final tx = list[i];
                    final isCredit = tx.action?.toLowerCase() == "credit";
                    final requestedAmount = tx.requestedAmount ?? tx.amount;
                    final creditedAmount = tx.creditedAmount ?? tx.amount;
                    final deductionAmount = tx.deductionAmount ?? 0;
                    final hasDeduction = deductionAmount > 0;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            foregroundColor:
                                isCredit ? Colors.green : Colors.red,
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _walletHistoryTitle(tx),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.canvasColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy • hh:mm a')
                                          .format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            tx.date ?? 0),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.canvasColor.withOpacity(0.6),
                                      ),
                                    ),
                                    // Text(
                                    //   ' • ',
                                    //   style: TextStyle(
                                    //     fontSize: 12,
                                    //     color:
                                    //         theme.canvasColor.withOpacity(0.6),
                                    //   ),
                                    // ),
                                    // Text(
                                    //   tx.action ?? '',
                                    //   style: TextStyle(
                                    //     fontSize: 12,
                                    //     color:
                                    //         theme.canvasColor.withOpacity(0.6),
                                    //   ),
                                    // )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 6,
                                  children: [
                                    if (requestedAmount != null)
                                      _HistoryMetric(
                                        label: 'Requested',
                                        value: _formatMoney(requestedAmount),
                                      ),
                                    if (hasDeduction)
                                      _HistoryMetric(
                                        label: 'Apple Deduction',
                                        value:
                                            _formatMoney(deductionAmount),
                                      ),
                                    if (creditedAmount != null)
                                      _HistoryMetric(
                                        label: hasDeduction
                                            ? 'Wallet Credited'
                                            : 'Credited',
                                        value: _formatMoney(creditedAmount),
                                      ),
                                    if ((tx.settlementType ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _HistoryMetric(
                                        label: 'Settlement',
                                        value:
                                            _formatLabel(tx.settlementType!),
                                      ),
                                    if ((tx.paymentGateway ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _HistoryMetric(
                                        label: 'Gateway',
                                        value:
                                            _formatLabel(tx.paymentGateway!),
                                      ),
                                    if ((tx.operatingSystem ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _HistoryMetric(
                                        label: 'OS',
                                        value:
                                            _formatLabel(tx.operatingSystem!),
                                      ),
                                  ],
                                ),
                                if ((tx.deductionReason ?? tx.reason ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    (tx.deductionReason ?? tx.reason)
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          theme.canvasColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            "${isCredit ? "+" : "-"}${(creditedAmount ?? tx.amount ?? 0).toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // Widget _buildFilterBar(BuildContext context) {
  //   return OutlinedButton.icon(
  //     icon: const Icon(
  //       Icons.date_range,
  //       size: 18,
  //       color: Colors.white,
  //     ),
  //     label: Text(
  //       _startDate == null || _endDate == null
  //           ? "Select Date"
  //           : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
  //       style: TextStyle(
  //         color: Colors.white,
  //       ),
  //     ),
  //     onPressed: () async {
  //       final picked = await showDateRangePicker(
  //         context: context,
  //         firstDate: DateTime(2020),
  //         lastDate: DateTime.now(),
  //       );
  //       if (picked != null) {
  //         setState(() {
  //           _startDate = picked.start;
  //           _endDate = picked.end;
  //         });
  //         Provider.of<WalletProvider>(context, listen: false)
  //             .filterDateWiseTransaction(_startDate, _endDate);
  //       }
  //     },
  //   );
  // }

  Future<void> _handleRechargeTap() async {
    if (_isIosWallet) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AppleWalletRechargeScreen(),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        final provider = Provider.of<WalletProvider>(context, listen: false);
        await provider.refreshWalletData();
      }
      return;
    }

    _showBuyDialog();
  }

  void _showBuyDialog() {
    final controller = TextEditingController();
    final pageContext = context;

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
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text("Recharge Wallet"),
                  content: SizedBox(
                    width: ResponsiveWidget.isTabletOrTv(dialogContext)
                        ? 460
                        : null,
                    child: TextField(
                      controller: controller,
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
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () => _submitRecharge(
                                provider: provider,
                                controller: controller,
                                dialogContext: dialogContext,
                                pageContext: pageContext,
                                setProcessing: (value) {
                                  setState(() => isProcessing = value);
                                },
                              ),
                      child: Text(isBusy ? "Processing..." : "Proceed to pay"),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _tvFocus(
    Widget child, {
    required VoidCallback onTap,
    bool autofocus = false,
  }) {
    if (ResponsiveWidget.isMobile(context)) return child;
    return OttTvFocus(
      autofocus: autofocus,
      onTap: onTap,
      child: child,
    );
  }

  Future<void> _submitRecharge({
    required WalletProvider provider,
    required TextEditingController controller,
    required BuildContext dialogContext,
    required BuildContext pageContext,
    required ValueChanged<bool> setProcessing,
  }) async {
    final amt = double.tryParse(controller.text);
    if (amt == null) {
      CustomToast.show(
        pageContext,
        "Enter a valid amount",
        isSuccess: false,
      );
      return;
    }
    if (amt < _minimumRechargeAmount) {
      CustomToast.show(
        pageContext,
        "Minimum recharge amount is Rs ${_minimumRechargeAmount.toStringAsFixed(0)}",
        isSuccess: false,
      );
      return;
    }
    if (amt > _maximumRechargeAmount) {
      CustomToast.show(
        pageContext,
        "Maximum recharge amount is Rs ${_maximumRechargeAmount.toStringAsFixed(0)}",
        isSuccess: false,
      );
      return;
    }

    setProcessing(true);
    Navigator.pop(dialogContext);

    final paymentResult = await Navigator.push(
      pageContext,
      MaterialPageRoute(
        builder: (_) => PaymentPage(amount: amt),
      ),
    );

    if (!mounted) return;
    if (paymentResult is Map && paymentResult['success'] == true) {
      _showWalletReflectLoader(pageContext);
      final result = await provider
          .onPaymentVerified(
        expectedAmount: amt,
      )
          .whenComplete(() {
        if (mounted) {
          Navigator.of(pageContext, rootNavigator: true).pop();
        }
      });
      if (!mounted) return;
      if (result['success'] == true) {
        await _showWalletRechargeSuccess(
          requestedAmount: amt,
          walletResponse: result['walletResponse'] is AddWalletAmountResponse
              ? result['walletResponse'] as AddWalletAmountResponse
              : null,
        );
        if (!mounted) return;
      }
      CustomToast.show(
        pageContext,
        result['message']?.toString() ?? "Wallet recharged successfully.",
        isSuccess: result['success'] == true,
      );
    } else {
      CustomToast.show(
        pageContext,
        paymentResult is Map
            ? paymentResult['message']?.toString() ??
                "Recharge failed. Please try again."
            : "Recharge failed. Please try again.",
        isSuccess: false,
      );
    }
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

  String _walletHistoryTitle(Transactions tx) {
    if ((tx.action ?? '').toLowerCase() == 'credit') {
      return 'Wallet Recharge';
    }
    final status = tx.status?.trim();
    return status == null || status.isEmpty ? 'Wallet Transaction' : status;
  }

  String _formatMoney(double value) {
    final decimals = value.truncateToDouble() == value ? 0 : 2;
    return '\u20B9${value.toStringAsFixed(decimals)}';
  }

  String _formatLabel(String value) {
    final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
    if (normalized.isEmpty) return value;
    return normalized
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _showWalletRechargeSuccess({
    required double requestedAmount,
    AddWalletAmountResponse? walletResponse,
  }) {
    final data = walletResponse?.data;
    final creditedAmount = data?.creditedAmount ?? requestedAmount;
    final deductionAmount = data?.deductionAmount;
    final deductionPercentage = data?.deductionPercentage;

    return showDialog<void>(
      context: context,
      builder: (_) => WalletRechargeSummaryDialog(
        requestedAmount: data?.requestedAmount ?? requestedAmount,
        creditedAmount: creditedAmount,
        deductionAmount: deductionAmount,
        deductionPercentage: deductionPercentage,
        deductionLabel: (deductionAmount ?? 0) > 0
            ? data?.deductionReason ?? 'Apple Deduction'
            : null,
        paymentGateway: data?.paymentGateway,
        settlementType: data?.settlementType,
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.canvasColor.withOpacity(0.54),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: theme.canvasColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
