class GetWalletAmountResponse {
  String? message;
  Wallet? data;
  int? statusCode;
  bool? success;

  GetWalletAmountResponse(
      {this.message, this.data, this.statusCode, this.success});

  GetWalletAmountResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? new Wallet.fromJson(json['data']) : null;
    statusCode = json['statusCode'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['statusCode'] = this.statusCode;
    data['success'] = this.success;
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
    balance = json['balance'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['walletId'] = this.walletId;
    data['balance'] = this.balance;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
