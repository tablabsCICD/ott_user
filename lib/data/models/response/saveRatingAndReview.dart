import 'getRatingsAndReview.dart';

class SaveRatingsAndReviewResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  SaveRatingsAndReviewResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory SaveRatingsAndReviewResponse.fromJson(Map<String, dynamic> json) => SaveRatingsAndReviewResponse(
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
  Review? user;

  Data({
    this.user,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    user: json["user"] == null ? null : Review.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
  };
}

