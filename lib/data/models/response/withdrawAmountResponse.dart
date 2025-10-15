class WithdrawAmountresponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  WithdrawAmountresponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory WithdrawAmountresponse.fromJson(Map<String, dynamic> json) => WithdrawAmountresponse(
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
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

class Data {
  double? newBalance;
  String? message;

  Data({
    this.newBalance,
    this.message,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    newBalance: json["newBalance"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "newBalance": newBalance,
    "message": message,
  };
}
