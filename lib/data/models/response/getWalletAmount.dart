class GetWalletAmountResponse {
  String? message;
  Wallet? data;
  int? statusCode;
  bool? success;

  GetWalletAmountResponse(
      {this.message, this.data, this.statusCode, this.success});

  GetWalletAmountResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? Wallet.fromJson(json['data']) : null;
    statusCode = json['statusCode'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['statusCode'] = statusCode;
    data['success'] = success;
    return data;
  }
}

class Wallet {
  int? walletId;
  double? balance;
  int? updatedAt;

  Wallet({this.walletId, this.balance, this.updatedAt});

  Wallet.fromJson(Map<String, dynamic> json) {
    walletId = json['walletId'];
    balance = _asDouble(json['balance']);
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['walletId'] = walletId;
    data['balance'] = balance;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
