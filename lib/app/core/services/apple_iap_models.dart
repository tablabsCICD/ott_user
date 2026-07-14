class ApplePurchaseVerificationRequest {
  const ApplePurchaseVerificationRequest({
    required this.productId,
    required this.purchaseId,
    required this.transactionId,
    required this.verificationData,
    required this.verificationSource,
    required this.userId,
    required this.deviceId,
    this.originalTransactionId,
    this.transactionDate,
  });

  final String productId;
  final String purchaseId;
  final String transactionId;
  final String? originalTransactionId;
  final String verificationData;
  final String verificationSource;
  final String? transactionDate;
  final int userId;
  final String deviceId;

  Map<String, dynamic> toJson() => {
        'platform': 'ios',
        'productId': productId,
        'purchaseId': purchaseId,
        'transactionId': transactionId,
        'transaction_id': transactionId,
        if (originalTransactionId != null)
          'originalTransactionId': originalTransactionId,
        'verificationData': verificationData,
        'verificationSource': verificationSource,
        if (transactionDate != null) 'transactionDate': transactionDate,
        // The backend must authenticate this identity from the JWT. This value
        // is correlation metadata only and must never select the credited user.
        'userId': userId,
        'deviceId': deviceId,
      };
}

class ApplePurchaseVerificationResult {
  const ApplePurchaseVerificationResult({
    required this.success,
    required this.verified,
    required this.alreadyProcessed,
    required this.message,
    required this.transactionId,
    required this.productId,
    this.code,
    this.environment,
    this.walletBalance,
    this.creditedAmount,
    this.requestedAmount,
    this.deductionAmount,
    this.deductionPercentage,
    this.deductionReason,
    this.operatingSystem,
    this.paymentGateway,
    this.settlementType,
  });

  final bool success;
  final bool verified;
  final bool alreadyProcessed;
  final String message;
  final String? code;
  final String? environment;
  final double? walletBalance;
  final double? creditedAmount;
  final double? requestedAmount;
  final double? deductionAmount;
  final double? deductionPercentage;
  final String? deductionReason;
  final String? operatingSystem;
  final String? paymentGateway;
  final String? settlementType;
  final String transactionId;
  final String productId;

  factory ApplePurchaseVerificationResult.fromJson(
    Map<String, dynamic> body,
  ) {
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    dynamic value(String key) => body[key] ?? data[key];

    return ApplePurchaseVerificationResult(
      success: value('success') == true,
      verified: value('verified') == true,
      alreadyProcessed: value('alreadyProcessed') == true,
      message: value('message')?.toString() ??
          'The App Store transaction could not be verified.',
      code: value('code')?.toString(),
      environment: value('environment')?.toString(),
      walletBalance: _asDouble(value('walletBalance') ?? value('balance')),
      creditedAmount: _asDouble(value('creditedAmount')),
      requestedAmount: _asDouble(value('requestedAmount')),
      deductionAmount: _asDouble(value('deductionAmount')),
      deductionPercentage: _asDouble(value('deductionPercentage')),
      deductionReason: value('deductionReason')?.toString(),
      operatingSystem: value('operatingSystem')?.toString(),
      paymentGateway: value('paymentGateway')?.toString(),
      settlementType: value('settlementType')?.toString(),
      transactionId:
          (value('transactionId') ?? value('transaction_id') ?? '').toString(),
      productId: value('productId')?.toString() ?? '',
    );
  }
}

class ApplePurchaseVerificationException implements Exception {
  const ApplePurchaseVerificationException({
    required this.message,
    this.code = 'APPLE_TRANSACTION_INVALID',
    this.statusCode,
  });

  final String message;
  final String code;
  final int? statusCode;

  bool get isTemporary => const {
        'APPLE_SERVER_UNAVAILABLE',
        'APPLE_API_TIMEOUT',
        'NETWORK_ERROR',
        'WALLET_CREDIT_FAILED',
      }.contains(code);

  @override
  String toString() => message;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
