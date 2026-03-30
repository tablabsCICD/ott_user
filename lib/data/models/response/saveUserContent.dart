import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/purchesContentListResponse.dart';

import '../user.dart';

class SavePurchaseContentResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  SavePurchaseContentResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory SavePurchaseContentResponse.fromJson(Map<String, dynamic> json) =>
      SavePurchaseContentResponse(
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
  Content? movie;
  UserContent? userContentPurchase;
  User? user;

  Data({
    this.movie,
    this.userContentPurchase,
    this.user,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        movie: json["movie"] == null ? null : Content.fromJson(json["movie"]),
        userContentPurchase: json["userContentPurchase"] == null
            ? null
            : UserContent.fromJson(json["userContentPurchase"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "movie": movie?.toJson(),
        "userContentPurchase": userContentPurchase?.toJson(),
        "user": user?.toJson(),
      };
}
