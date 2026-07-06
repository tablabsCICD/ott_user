class WalletHistory {
  String? message;
  List<Transactions>? data;
  int? statusCode;
  bool? success;

  WalletHistory({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory WalletHistory.fromJson(Map<String, dynamic> json) {
    final dataJson = json["data"];
    final transactionsJson =
        dataJson is Map<String, dynamic> ? dataJson["transactions"] : dataJson;

    return WalletHistory(
      message: json["message"],
      data: transactionsJson is List
          ? List<Transactions>.from(
              transactionsJson.map(
                (x) => Transactions.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      statusCode: json["statusCode"],
      success: json["success"],
    );
  }

  Map<String, dynamic> toJson() => {
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "statusCode": statusCode,
        "success": success,
      };
}

class Transactions {
  int? id;
  double? amount;
  String? status;
  int? userId;
  String? userName;
  int? date;
  dynamic reason;
  dynamic movieStartDate;
  dynamic movieEndDate;
  String? action;

  Transactions({
    this.id,
    this.amount,
    this.status,
    this.userId,
    this.userName,
    this.date,
    this.reason,
    this.movieStartDate,
    this.movieEndDate,
    this.action,
  });

  factory Transactions.fromJson(Map<String, dynamic> json) => Transactions(
        id: json["id"],
        amount: _asDouble(json["amount"]),
        status: json["status"],
        userId: json["userId"],
        userName: json["userName"],
        date: _asEpochMillis(json["date"] ?? json["transactionDate"]),
        reason: json["reason"],
        movieStartDate: json["movieStartDate"],
        movieEndDate: json["movieEndDate"],
        action: json["action"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "amount": amount,
        "status": status,
        "userId": userId,
        "userName": userName,
        "date": date,
        "reason": reason,
        "movieStartDate": movieStartDate,
        "movieEndDate": movieEndDate,
        "action": action,
      };
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _asEpochMillis(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsedNumber = int.tryParse(value.toString());
  if (parsedNumber != null) return parsedNumber;

  return DateTime.tryParse(value.toString())?.millisecondsSinceEpoch;
}
