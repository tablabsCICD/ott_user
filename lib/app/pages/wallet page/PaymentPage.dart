import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ott/app/core/services/PaymentService.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';

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
  bool _hasReturnedResult = false;

  @override
  void initState() {
    super.initState();
    _startPaymentFlow();
  }

  Future<void> _startPaymentFlow() async {
    try {
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

      debugPrint(order.orderId);
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
    }
  }

  void _finish(PaymentResult result) {
    if (!mounted) {
      return;
    }
    if (_hasReturnedResult) {
      return;
    }
    _hasReturnedResult = true;

    setState(() {
      _isLoading = false;
      _status = result.message;
    });

    Navigator.pop(context, result.toMap());
  }

  void _cancelPayment() {
    _finish(
      PaymentResult(
        success: false,
        message: 'Payment cancelled.',
      ),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FocusTraversalGroup(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.primaryColor,
                          ),
                        )
                      else
                        Icon(
                          Icons.info_outline,
                          color: theme.primaryColor,
                          size: 42,
                        ),
                      const SizedBox(height: 18),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.canvasColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        autofocus: _isTvLikeSurface(context),
                        onPressed: _cancelPayment,
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel Payment'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(190, 48),
                          foregroundColor: theme.canvasColor,
                          side: BorderSide(
                            color: theme.canvasColor.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isTvLikeSurface(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isLargeLandscape =
      size.width >= 900 && size.width > size.height && size.shortestSide >= 540;

  return isLargeLandscape &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.android);
}
