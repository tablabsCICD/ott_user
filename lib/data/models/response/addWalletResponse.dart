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

  factory AddWalletAmountResponse.fromJson(Map<String, dynamic> json) => AddWalletAmountResponse(
    message: json["message"],
    data: json["data"] == null ? null : WalletObject.fromJson(json["data"]),
    statusCode: json["statusCode"],
    success: json["success"],
  );

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

  WalletObject({
    this.walletId,
    this.balance,
    this.transactionHistory,
    this.userId,
  });

  factory WalletObject.fromJson(Map<String, dynamic> json) => WalletObject(
    walletId: json["walletId"],
    balance: json["balance"],
    transactionHistory: json["transactionHistory"] == null ? [] : List<dynamic>.from(json["transactionHistory"]!.map((x) => x)),
    userId: json["userId"],
  );

  Map<String, dynamic> toJson() => {
    "walletId": walletId,
    "balance": balance,
    "transactionHistory": transactionHistory == null ? [] : List<dynamic>.from(transactionHistory!.map((x) => x)),
    "userId": userId,
  };
}
