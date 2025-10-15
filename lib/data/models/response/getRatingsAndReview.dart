class GetRatingsAndReview {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  GetRatingsAndReview({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory GetRatingsAndReview.fromJson(Map<String, dynamic> json) => GetRatingsAndReview(
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
  ReviewRating? reviewRating;

  Data({
    this.reviewRating,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    reviewRating: json["reviewRating"] == null ? null : ReviewRating.fromJson(json["reviewRating"]),
  );

  Map<String, dynamic> toJson() => {
    "reviewRating": reviewRating?.toJson(),
  };
}

class ReviewRating {
  List<Review>? reviews;
  int? ratingAvg;

  ReviewRating({
    this.reviews,
    this.ratingAvg,
  });

  factory ReviewRating.fromJson(Map<String, dynamic> json) => ReviewRating(
    reviews: json["reviews"] == null ? [] : List<Review>.from(json["reviews"]!.map((x) => Review.fromJson(x))),
    ratingAvg: json["ratingAvg"],
  );

  Map<String, dynamic> toJson() => {
    "reviews": reviews == null ? [] : List<dynamic>.from(reviews!.map((x) => x.toJson())),
    "ratingAvg": ratingAvg,
  };
}

class Review {
  int? createdAt;
  int? contentId;
  int? rating;
  String? comment;
  String? title;
  int? reviewId;
  int? userId;
  String? userProfile;
  String? username;

  Review({
    this.createdAt,
    this.contentId,
    this.rating,
    this.comment,
    this.title,
    this.reviewId,
    this.userId,
    this.userProfile,
    this.username,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    createdAt: json["createdAt"],
    contentId: json["contentId"],
    rating: json["rating"],
    comment: json["comment"],
    title: json["title"],
    reviewId: json["reviewId"],
    userId: json["userId"],
    userProfile: json["userProfile"],
    username: json["username"],
  );

  Map<String, dynamic> toJson() => {
    "createdAt": createdAt,
    "contentId": contentId,
    "rating": rating,
    "comment": comment,
    "title": title,
    "reviewId": reviewId,
    "userId": userId,
    "userProfile": userProfile,
    "username": username,
  };
}
