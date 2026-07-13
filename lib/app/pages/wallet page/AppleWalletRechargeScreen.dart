// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ott/app/pages/wallet page/wallet_recharge_summary_dialog.dart';
import 'package:ott/app/core/services/AppleIapService.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class AppleWalletRechargeScreen extends StatefulWidget {
  const AppleWalletRechargeScreen({
    super.key,
    this.showAppBar = true,
    this.popOnSuccess = true,
  });

  final bool showAppBar;
  final bool popOnSuccess;

  @override
  State<AppleWalletRechargeScreen> createState() =>
      _AppleWalletRechargeScreenState();
}

class _AppleWalletRechargeScreenState extends State<AppleWalletRechargeScreen> {
  bool _initialized = false;
  bool _isRefreshingWallet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      context.read<AppleIapService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;

    return Consumer2<AppleIapService, WalletProvider>(
      builder: (context, iapService, walletProvider, _) {
        _handlePendingMessage(iapService, walletProvider);

        final content = RefreshIndicator(
          onRefresh: iapService.loadProducts,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveWidget.isDesktop(context) ? 200 : 16,
              widget.showAppBar ? 24 : 8,
              ResponsiveWidget.isDesktop(context) ? 200 : 16,
              24,
            ),
            shrinkWrap: !widget.showAppBar,
            physics: widget.showAppBar
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            children: [
              if (!widget.showAppBar) ...[
                const SizedBox(height: 8),
                Text(
                  'Apple Wallet Packages',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              _buildHeader(context, theme),
              const SizedBox(height: 18),
              if (iapService.isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!iapService.isAvailable || iapService.products.isEmpty)
                _buildUnavailableState(context, iapService)
              else
                _buildPackageGrid(context, iapService),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    iapService.isBusy ? null : iapService.restorePurchases,
                icon: iapService.isRestoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: const Text('Restore Purchases'),
              ),
            ],
          ),
        );
        final body = Stack(
          children: [
            content,
            if (iapService.isVerifying || _isRefreshingWallet)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              iapService.isVerifying
                                  ? 'Verifying Apple purchase...'
                                  : 'Refreshing wallet...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

        if (!widget.showAppBar) return body;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Recharge Wallet'),
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy wallet credits with Apple',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Credits are added to your Filmytell wallet after Apple confirms the purchase.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.canvasColor.withValues(alpha: 0.68),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid(
    BuildContext context,
    AppleIapService iapService,
  ) {
    final isWide = ResponsiveWidget.isDesktop(context) ||
        ResponsiveWidget.isTablet(context);
    final packageById = {
      for (final package in AppleIapService.packages)
        package.productId: package,
    };
    final cards = iapService.products.map((product) {
      final package = packageById[product.id]!;
      return _AppleWalletPackageCard(
        package: package,
        product: product,
        isBusy: iapService.isBusy,
        isActive: iapService.activeProductId == package.productId,
        onBuy: (product) => iapService.buyProduct(product),
      );
    }).toList();

    if (!isWide) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _buildUnavailableState(
    BuildContext context,
    AppleIapService iapService,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Wallet packages unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            iapService.errorMessage ??
                'Please try again after a moment or contact support.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: iapService.loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handlePendingMessage(
    AppleIapService iapService,
    WalletProvider walletProvider,
  ) {
    final message = iapService.pendingMessage;
    if (message == null || message.type == AppleIapDialogType.verification) {
      return;
    }

    iapService.consumeMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (message.type == AppleIapDialogType.success ||
          message.type == AppleIapDialogType.restored) {
        setState(() => _isRefreshingWallet = true);
        await walletProvider.refreshWalletData();
        if (mounted) setState(() => _isRefreshingWallet = false);
      }

      if (!mounted) return;
      if ((message.type == AppleIapDialogType.success ||
              message.type == AppleIapDialogType.restored) &&
          message.requestedAmount != null &&
          message.creditedAmount != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => WalletRechargeSummaryDialog(
            requestedAmount: message.requestedAmount!,
            creditedAmount: message.creditedAmount!,
            deductionAmount: message.deductionAmount,
            deductionPercentage: message.deductionPercentage,
            deductionLabel: 'Apple Charges',
            paymentGateway: message.paymentGateway,
            settlementType: message.settlementType,
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(message.title),
            content: Text(message.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      if ((message.type == AppleIapDialogType.success ||
              message.type == AppleIapDialogType.restored) &&
          widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      }
    });
  }
}

class _AppleWalletPackageCard extends StatelessWidget {
  const _AppleWalletPackageCard({
    required this.package,
    required this.product,
    required this.isBusy,
    required this.isActive,
    required this.onBuy,
  });

  final AppleWalletPackage package;
  final ProductDetails? product;
  final bool isBusy;
  final bool isActive;
  final ValueChanged<ProductDetails> onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = product == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u20B9${package.walletAmount}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product?.title ?? package.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product!.price,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.canvasColor.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 116,
            child: ElevatedButton(
              onPressed: isBusy || unavailable ? null : () => onBuy(product!),
              child: isActive
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(unavailable ? 'Unavailable' : 'Buy'),
            ),
          ),
        ],
      ),
    );
  }
}
