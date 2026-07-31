import 'package:flutter/material.dart';
import 'package:ott/app/core/services/PaymentService.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
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
                'Razorpay checkout is only available on web and Android.',
          ),
        );
        return;
      }

      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user?.id == null) {
        _finish(
          PaymentResult(
            success: false,
            message: 'Please log in again to continue payment.',
          ),
        );
        return;
      }

      setState(() {
        _status = 'Creating Razorpay order...';
      });

      final order = await _paymentService.createOrder(
        amount: widget.amount,
        userId: user!.id!,
      );


      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Opening Razorpay checkout...';
      });

      final result = await _paymentService.openCheckout(
        order: order,
        amount: widget.amount,
        description: widget.description,
        plan: widget.plan,
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

  @override
  Widget build(BuildContext context) {
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
                            onTap: () => Navigator.pop(
                              context,
                              PaymentResult(
                                success: false,
                                message: 'Payment cancelled.',
                              ).toMap(),
                            ),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(150, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(
                                context,
                                PaymentResult(
                                  success: false,
                                  message: 'Payment cancelled.',
                                ).toMap(),
                              ),
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
}
