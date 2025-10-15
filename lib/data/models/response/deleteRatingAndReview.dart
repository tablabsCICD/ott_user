class DeleteRatingsAndReview {
  String? message;
  dynamic data;
  int? statusCode;
  bool? success;

  DeleteRatingsAndReview({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory DeleteRatingsAndReview.fromJson(Map<String, dynamic> json) => DeleteRatingsAndReview(
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
