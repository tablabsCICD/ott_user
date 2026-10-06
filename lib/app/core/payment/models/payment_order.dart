class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.receipt,
    this.checkoutUrl,
    this.sessionId,
    this.publishableKey,
    this.clientSecret,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String receipt;
  final String? checkoutUrl;
  final String? sessionId;
  final String? publishableKey;
  final String? clientSecret;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      orderId: (json['orderId'] ?? json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'INR').toString(),
      receipt: (json['receipt'] ?? '').toString(),
      checkoutUrl: json['checkoutUrl']?.toString() ?? json['url']?.toString(),
      sessionId: json['sessionId']?.toString() ?? json['session_id']?.toString(),
      publishableKey: json['publishableKey']?.toString(),
      clientSecret: json['clientSecret']?.toString() ?? json['client_secret']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'receipt': receipt,
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (sessionId != null) 'sessionId': sessionId,
      if (publishableKey != null) 'publishableKey': publishableKey,
      if (clientSecret != null) 'clientSecret': clientSecret,
    };
  }
}
