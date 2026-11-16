import 'package:flutter/material.dart';
import 'package:ott/app/core/services/PaymentService.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.amount,
    this.description = 'Add Money to Wallet',
    this.plan = 0,
  });

  final double amount;
  final String description;
  final int plan;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  String _status = 'Preparing secure checkout...';
  bool _checkoutStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ResponsiveWidget.isMobile(context)) {
        _startPaymentFlow();
      } else {
        setState(() {
          _isLoading = false;
          _status = 'Ready to open secure Razorpay checkout.';
        });
      }
    });
  }

  Future<void> _startPaymentFlow() async {
    if (_checkoutStarted) return;
    _checkoutStarted = true;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _status = 'Preparing secure checkout...';
        });
      }

      if (!PaymentService.isSupportedPlatform) {
        _finish(
          PaymentResult(
            success: false,
            message:
                'Razorpay checkout is only available on web, Android, and iOS.',
          ),
        );
        return;
      }

      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user?.id == null) {
        _finish(
          const PaymentResult(
            success: false,
            message: 'Please log in again to continue payment.',
          ),
        );
        return;
      }

      final userCountry = (user?.location?.country ?? '').trim();
      final country = userCountry.isNotEmpty
          ? userCountry
          : WidgetsBinding.instance.platformDispatcher.locale.countryCode;

      // Matches the gateway PaymentService will actually use (Razorpay for
      // everyone while Stripe is disabled).
      final isRazorpay = PaymentGatewaySelector.selectGateway(country: country) ==
          PaymentGatewayType.razorpay;

      setState(() {
        _status = isRazorpay
            ? 'Creating Razorpay order...'
            : 'Creating Stripe checkout session...';
      });

      final order = await _paymentService.createOrder(
        amount: widget.amount,
        userId: user!.id!,
        country: country,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = isRazorpay
            ? 'Opening Razorpay checkout...'
            : 'Opening Stripe checkout...';
      });

      final result = await _paymentService.openCheckout(
        order: order,
        amount: widget.amount,
        description: widget.description,
        plan: widget.plan,
        country: country,
      );

      _finish(result);
    } catch (error) {
      _finish(
        PaymentResult(
          success: false,
          message: error.toString(),
        ),
      );
    } finally {
      _checkoutStarted = false;
    }
  }

  void _finish(PaymentResult result) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _status = result.message;
    });

    Navigator.pop(context, result.toMap());
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _cancelPayment() {
    Navigator.pop(
      context,
      PaymentResult(
        success: false,
        message: 'Payment cancelled.',
      ).toMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isAndroidTv(context)) return _buildTv(context);

    final isTvLayout = ResponsiveWidget.isTabletOrTv(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isTvLayout ? theme.scaffoldBackgroundColor : null,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isTvLayout ? 48 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTvLayout ? 560 : 360),
            child: Card(
              color: isTvLayout ? theme.cardColor : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTvLayout ? 24 : 12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isTvLayout ? 32 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: theme.primaryColor,
                      size: isTvLayout ? 52 : 36,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      CircularProgressIndicator(color: theme.primaryColor),
                    if (_isLoading) const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: isTvLayout ? 20 : null,
                        fontWeight: isTvLayout ? FontWeight.w600 : null,
                      ),
                    ),
                    if (isTvLayout && !_isLoading) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OttTvFocus(
                            autofocus: true,
                            onTap: _startPaymentFlow,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(220, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _startPaymentFlow,
                              icon: const Icon(Icons.payment_rounded),
                              label: const Text('Open Checkout'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OttTvFocus(
                            onTap: _cancelPayment,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(150, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _cancelPayment,
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Android TV ----------------

  String get _tvAmountLabel => widget.amount % 1 == 0
      ? widget.amount.toStringAsFixed(0)
      : widget.amount.toStringAsFixed(2);

  /// Android TV: compact, centred secure-checkout panel on the 540 px canvas.
  /// Same state and handlers as the other layouts ([_startPaymentFlow],
  /// [_cancelPayment]); only the presentation differs.
  Widget _buildTv(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.canvasColor.withValues(alpha: 0.62);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TvDesign.pageGutter),
          child: Container(
            width: 400,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(TvDesign.panelRadius),
              border: Border.all(
                color: theme.canvasColor.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure checkout',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TvDesign.sectionTitle(theme),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TvDesign.caption(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(TvDesign.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Amount',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₹ $_tvAmountLabel',
                        style: TextStyle(
                          color: theme.canvasColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_isLoading) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        _status,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.canvasColor.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isLoading) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            autofocus: true,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _startPaymentFlow,
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: const Text(
                              'Open Checkout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.canvasColor,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _cancelPayment,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
