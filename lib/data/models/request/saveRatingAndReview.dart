class SaveRatingsAndReview {
  String? comment;
  int? contentId;
  String? createdAt;
  double? rating;
  int? reviewId;
  String? title;
  int? userId;

  SaveRatingsAndReview({
    this.comment,
    this.contentId,
    this.createdAt,
    this.rating,
    this.reviewId,
    this.title,
    this.userId,
  });

  factory SaveRatingsAndReview.fromJson(Map<String, dynamic> json) => SaveRatingsAndReview(
    comment: json["comment"],
    contentId: json["contentId"],
    createdAt: json["createdAt"] ,
    rating: json["rating"],
    reviewId: json["reviewId"],
    title: json["title"],
    userId: json["userId"],
  );

  Map<String, dynamic> toJson() => {
    "comment": comment,
    "contentId": contentId,
    "createdAt": createdAt,
    "rating": rating,
    "reviewId": reviewId,
    "title": title,
    "userId": userId,
  };
}
