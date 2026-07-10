class AddWalletAmountResponse {
  String? message;
  WalletObject? data;
  int? statusCode;
  bool? success;

  AddWalletAmountResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory AddWalletAmountResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json["data"];
    final hasRootWalletData = json.containsKey("balance") ||
        json.containsKey("requestedAmount") ||
        json.containsKey("creditedAmount");

    return AddWalletAmountResponse(
      message: json["message"],
      data: dataJson is Map<String, dynamic>
          ? WalletObject.fromJson(dataJson)
          : hasRootWalletData
              ? WalletObject.fromJson(json)
              : null,
      statusCode: json["statusCode"],
      success: json["success"],
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data?.toJson(),
    "statusCode": statusCode,
    "success": success,
  };
}

class WalletObject {
  int? walletId;
  double? balance;
  List<dynamic>? transactionHistory;
  int? userId;
  double? requestedAmount;
  double? creditedAmount;
  double? deductionAmount;
  double? deductionPercentage;
  String? deductionReason;
  String? operatingSystem;
  String? paymentGateway;
  String? settlementType;
  String? status;
  String? action;

  WalletObject({
    this.walletId,
    this.balance,
    this.transactionHistory,
    this.userId,
    this.requestedAmount,
    this.creditedAmount,
    this.deductionAmount,
    this.deductionPercentage,
    this.deductionReason,
    this.operatingSystem,
    this.paymentGateway,
    this.settlementType,
    this.status,
    this.action,
  });

  factory WalletObject.fromJson(Map<String, dynamic> json) => WalletObject(
    walletId: json["walletId"],
    balance: _asDouble(json["balance"]),
    transactionHistory: json["transactionHistory"] == null ? [] : List<dynamic>.from(json["transactionHistory"]!.map((x) => x)),
    userId: json["userId"],
    requestedAmount: _asDouble(json["requestedAmount"]),
    creditedAmount: _asDouble(json["creditedAmount"]),
    deductionAmount: _asDouble(json["deductionAmount"]),
    deductionPercentage: _asDouble(json["deductionPercentage"]),
    deductionReason: json["deductionReason"]?.toString(),
    operatingSystem: json["operatingSystem"]?.toString(),
    paymentGateway: json["paymentGateway"]?.toString(),
    settlementType: json["settlementType"]?.toString(),
    status: json["status"]?.toString(),
    action: json["action"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "walletId": walletId,
    "balance": balance,
    "transactionHistory": transactionHistory == null ? [] : List<dynamic>.from(transactionHistory!.map((x) => x)),
    "userId": userId,
    "requestedAmount": requestedAmount,
    "creditedAmount": creditedAmount,
    "deductionAmount": deductionAmount,
    "deductionPercentage": deductionPercentage,
    "deductionReason": deductionReason,
    "operatingSystem": operatingSystem,
    "paymentGateway": paymentGateway,
    "settlementType": settlementType,
    "status": status,
    "action": action,
  };
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
