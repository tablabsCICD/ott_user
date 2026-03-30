import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
