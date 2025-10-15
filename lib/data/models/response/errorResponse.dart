class ErrorResposne {
  String? message;
  dynamic data;
  int? statusCode;
  bool? success;

  ErrorResposne({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory ErrorResposne.fromJson(Map<String, dynamic> json) => ErrorResposne(
    message: json["message"],
    data: json["data"],
    statusCode: json["statusCode"],
    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data,
    "statusCode": statusCode,
    "success": success,
  };
}
