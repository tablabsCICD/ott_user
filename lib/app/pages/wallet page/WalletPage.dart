import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/pages/wallet page/PaymentPage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
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
  final FocusNode _rechargeButtonFocusNode =
      FocusNode(debugLabel: 'wallet-recharge');
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _metricFocusNodes =
      List.generate(4, (i) => FocusNode(debugLabel: 'wallet-metric-$i'));
  final Map<int, FocusNode> _transactionFocusNodes = {};
  final Map<int, FocusNode> _withdrawFocusNodes = {};

  static const double _minimumRechargeAmount = 10;
  static const double _maximumRechargeAmount = 100000;

  FocusNode _getTransactionFocusNode(int index) {
    return _transactionFocusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: 'wallet-tx-$index'),
    );
  }

  FocusNode _getWithdrawFocusNode(int index) {
    return _withdrawFocusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: 'wallet-withdraw-$index'),
    );
  }

  @override
  void dispose() {
    _rechargeButtonFocusNode.dispose();
    _scrollController.dispose();
    for (final node in _metricFocusNodes) {
      node.dispose();
    }
    for (final node in _transactionFocusNodes.values) {
      node.dispose();
    }
    for (final node in _withdrawFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

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
        controller: _scrollController,
        cacheExtent: 3500,
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
            actionsPadding: const EdgeInsets.symmetric(
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

                              const Icon(
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
                                  onPressed: _showBuyDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    "Recharge Wallet",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: _showBuyDialog,
                                focusNode: _rechargeButtonFocusNode,
                                onKeyEvent: (node, event) {
                                  if (event is! KeyDownEvent) {
                                    return KeyEventResult.ignored;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowDown) {
                                    _metricFocusNodes[0].requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft) {
                                    final moved = node.focusInDirection(
                                        TraversalDirection.left);
                                    if (moved) return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
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

          Consumer<WalletProvider>(
            builder: (_, p, __) => _buildWalletSummarySliver(theme, p),
          ),

          /// -------- Header + Filter --------
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
            sliver: const SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                    final txNode = _getTransactionFocusNode(i);

                    return _tvTransactionFocus(
                      tx,
                      _plainTransactionTile(theme, tx),
                      focusNode: txNode,
                      alignment: 0.35,
                      onMoveDown: () {
                        if (i + 1 < list.length) {
                          _getTransactionFocusNode(i + 1).requestFocus();
                        } else {
                          final withdrawList = p.filteredTransactionHistory
                              .where((tx) =>
                                  tx.action?.toLowerCase() != "credit")
                              .toList();
                          if (withdrawList.isNotEmpty) {
                            _getWithdrawFocusNode(0).requestFocus();
                          }
                        }
                      },
                      onMoveUp: () {
                        if (i - 1 >= 0) {
                          _getTransactionFocusNode(i - 1).requestFocus();
                        } else {
                          _metricFocusNodes[0].requestFocus();
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 8),
            sliver: const SliverToBoxAdapter(
              child: Text(
                "Withdraw History",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Consumer<WalletProvider>(
            builder: (_, p, __) => _buildWithdrawHistorySliver(
              theme,
              p,
              horizontal,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _showBuyDialog() {
    final controller = TextEditingController(text: "100");
    final amountFocusNode = FocusNode(debugLabel: 'wallet-recharge-amount');
    final proceedFocusNode = FocusNode(debugLabel: 'wallet-proceed-btn');
    final cancelFocusNode = FocusNode(debugLabel: 'wallet-cancel-btn');
    final pageContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<WalletProvider>(
              builder: (_, provider, __) {
                final isBusy = isProcessing || provider.isAddingBalance;

                return Dialog(
                  backgroundColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: ResponsiveWidget.isTabletOrTv(dialogContext)
                        ? 480
                        : 340,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: theme.primaryColor,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Recharge Wallet",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.canvasColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: controller,
                          focusNode: amountFocusNode,
                          autofocus:
                              !ResponsiveWidget.isTv(dialogContext),
                          hintText: "Enter amount",
                          textInputType: TextInputType.number,
                          isDigits: true,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              proceedFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [100, 200, 500, 1000].map((val) {
                            final isSelected = controller.text == "$val";
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: OttTvFocus(
                                  borderRadius: 10,
                                  onTap: () {
                                    controller.text = "$val";
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.primaryColor
                                              .withValues(alpha: 0.18)
                                          : theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.primaryColor
                                            : theme.canvasColor
                                                .withValues(alpha: 0.15),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "₹$val",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected
                                            ? theme.primaryColor
                                            : theme.canvasColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OttTvFocus(
                              focusNode: cancelFocusNode,
                              borderRadius: 12,
                              onTap: isBusy
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isBusy
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 14),
                            OttTvFocus(
                              focusNode: proceedFocusNode,
                              autofocus:
                                  ResponsiveWidget.isTv(dialogContext),
                              borderRadius: 12,
                              onTap: isBusy
                                  ? null
                                  : () => _submitRecharge(
                                        provider: provider,
                                        controller: controller,
                                        dialogContext: dialogContext,
                                        pageContext: pageContext,
                                        setProcessing: (value) {
                                          setState(
                                              () => isProcessing = value);
                                        },
                                      ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isBusy
                                    ? null
                                    : () => _submitRecharge(
                                          provider: provider,
                                          controller: controller,
                                          dialogContext: dialogContext,
                                          pageContext: pageContext,
                                          setProcessing: (value) {
                                            setState(
                                                () => isProcessing = value);
                                          },
                                        ),
                                child: Text(
                                  isBusy
                                      ? "Processing..."
                                      : "Proceed to pay",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      amountFocusNode.dispose();
      proceedFocusNode.dispose();
      cancelFocusNode.dispose();
      controller.dispose();
    });
  }

  Widget _tvFocus(
    Widget child, {
    required VoidCallback onTap,
    bool autofocus = false,
    FocusNode? focusNode,
    FocusOnKeyEventCallback? onKeyEvent,
  }) {
    if (ResponsiveWidget.isMobile(context)) return child;
    return OttTvFocus(
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      onKeyEvent: onKeyEvent,
      scale: 1.06,
      child: child,
    );
  }

  SliverToBoxAdapter _buildWalletSummarySliver(
    ThemeData theme,
    WalletProvider provider,
  ) {
    final transactions = provider.filteredTransactionHistory;
    final totalRevenue = transactions
        .where((tx) => tx.action?.toLowerCase() == "credit")
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
    final pendingAmount = transactions
        .where((tx) => (tx.status ?? '').toLowerCase().contains('pending'))
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
    final withdrawAmount = transactions
        .where((tx) => tx.action?.toLowerCase() != "credit")
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));

    final cards = [
      _WalletMetric(
        label: 'Wallet Balance',
        value: _money(provider.walletBalance),
        icon: Icons.account_balance_wallet,
      ),
      _WalletMetric(
        label: 'Total Revenue',
        value: _money(totalRevenue),
        icon: Icons.trending_up,
      ),
      _WalletMetric(
        label: 'Pending Amount',
        value: _money(pendingAmount),
        icon: Icons.schedule,
      ),
      _WalletMetric(
        label: 'Withdraw History',
        value: _money(withdrawAmount),
        icon: Icons.history,
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveWidget.isDesktop(context)
              ? 200
              : ResponsiveWidget.isTablet(context)
                  ? 80
                  : 16,
          vertical: 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 4 ? 2.25 : 2.6,
              ),
              itemBuilder: (context, index) {
                final item = cards[index];
                return OttTvFocus(
                  focusNode: _metricFocusNodes[index],
                  borderRadius: 14,
                  scale: 1.04,
                  alignment: 0.25,
                  semanticLabel: '${item.label} ${item.value}',
                  onTap: () {},
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      if (index < 2 && columns == 2) {
                        _metricFocusNodes[index + 2].requestFocus();
                        return KeyEventResult.handled;
                      }
                      final list = provider.filteredTransactionHistory;
                      if (list.isNotEmpty) {
                        _getTransactionFocusNode(0).requestFocus();
                        return KeyEventResult.handled;
                      }
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (index >= 2 && columns == 2) {
                        _metricFocusNodes[index - 2].requestFocus();
                        return KeyEventResult.handled;
                      }
                      _rechargeButtonFocusNode.requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                        (index % columns == 0)) {
                      final moved =
                          node.focusInDirection(TraversalDirection.left);
                      if (moved) return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.canvasColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, color: theme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.canvasColor
                                      .withValues(alpha: 0.68),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.canvasColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawHistorySliver(
    ThemeData theme,
    WalletProvider provider,
    double horizontal,
  ) {
    final withdrawList = provider.filteredTransactionHistory
        .where((tx) => tx.action?.toLowerCase() != "credit")
        .toList();

    if (withdrawList.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        sliver: const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No withdraw transactions"),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      sliver: SliverList.separated(
        itemCount: withdrawList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final withdrawNode = _getWithdrawFocusNode(i);
          return _tvTransactionFocus(
            withdrawList[i],
            _plainTransactionTile(theme, withdrawList[i]),
            focusNode: withdrawNode,
            alignment: 0.35,
            onMoveDown: () {
              if (i + 1 < withdrawList.length) {
                _getWithdrawFocusNode(i + 1).requestFocus();
              }
            },
            onMoveUp: () {
              if (i - 1 >= 0) {
                _getWithdrawFocusNode(i - 1).requestFocus();
              } else {
                final txList = provider.filteredTransactionHistory;
                if (txList.isNotEmpty) {
                  _getTransactionFocusNode(txList.length - 1).requestFocus();
                } else {
                  _metricFocusNodes[0].requestFocus();
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _tvTransactionFocus(
    Transactions tx,
    Widget child, {
    FocusNode? focusNode,
    double? alignment,
    VoidCallback? onMoveDown,
    VoidCallback? onMoveUp,
  }) {
    if (ResponsiveWidget.isMobile(context)) return child;
    return OttTvFocus(
      focusNode: focusNode,
      borderRadius: 14,
      scale: 1.02,
      alignment: alignment,
      semanticLabel: '${tx.status ?? 'Transaction'} ${tx.amount ?? 0}',
      onTap: () {},
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
            onMoveDown != null) {
          onMoveDown();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            onMoveUp != null) {
          onMoveUp();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          final moved = node.focusInDirection(TraversalDirection.left);
          if (moved) return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  Widget _plainTransactionTile(ThemeData theme, Transactions tx) {
    final isCredit = tx.action?.toLowerCase() == "credit";
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
            foregroundColor: isCredit ? Colors.green : Colors.red,
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
                  tx.status ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.canvasColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(tx.date ?? 0),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.reason?.toString() ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isCredit ? "+" : "-"}${tx.amount?.toStringAsFixed(0) ?? "0"}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) => '₹ ${value.toStringAsFixed(0)}';

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
}

class _WalletMetric {
  const _WalletMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
