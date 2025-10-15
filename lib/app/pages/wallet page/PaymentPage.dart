import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:ott/app/core/constant/image_constant.dart';

class PaymentPage extends StatefulWidget {
  final double amount;

  const PaymentPage({super.key, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _openCheckout();
  }

  void _openCheckout() {
    var options = {
      // ✅ Required fields
      'key': 'rzp_test_XXXXXX', // replace with your Test Key ID
      'amount': (widget.amount * 100).toInt(), // Razorpay expects paise
      'currency': 'INR',
      'name': 'Filmytell',
      'description': 'Wallet Recharge',

      // ✅ Must be a URL, NOT an asset constant
      'image': 'https://yourdomain.com/logo.png',

      // ✅ Use this only if creating orders from backend
      // 'order_id': 'order_DBJOWzybf0sJbb',

      // ✅ Prefill details
      'prefill': {
        'name': 'Test User',
        'email': 'test.user@example.com',
        'contact': '9876543210',
      },

      // ✅ Theme customization
      'theme': {
        'color': '#E50914',
      },

      // ✅ Retry handling
      'retry': {
        'enabled': true,
        'max_count': 3,
      },

      // ✅ Allowed methods
      'method': {
        'upi': true,
        'netbanking': true,
        'wallet': true,
        'card': true,
      },

      // ✅ Extra metadata
      'notes': {
        'user_id': '12345',
        'subscription_plan': 'Gold',
        'duration': '1 Month',
      },

      // ✅ External wallets
      'external': {
        'wallets': ['paytm', 'phonepe']
      },

      // ✅ Auto close checkout after 15 mins
      'timeout': 900,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Navigator.pop(context, false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(context, true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(context, false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
