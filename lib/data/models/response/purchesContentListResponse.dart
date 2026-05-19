import 'package:ott/data/models/user.dart';

import '../content.dart';

class PurchaseContentListResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  PurchaseContentListResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory PurchaseContentListResponse.fromJson(Map<String, dynamic> json) =>
      PurchaseContentListResponse(
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
  List<UserContent>? userContent;

  Data({
    this.userContent,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        userContent: json["userContent"] == null
            ? []
            : List<UserContent>.from(
                json["userContent"]!.map((x) => UserContent.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "userContent": userContent == null
            ? []
            : List<dynamic>.from(userContent!.map((x) => x.toJson())),
      };
}

class UserContent {
  int? id;
  double? contentPercentage;
  dynamic dateFrom;
  dynamic dateTo;
  String? refferedBy;
  double? price;
  bool? isGifted;
  int? userIdGiftFrom;
  int? userIdGiftTo;
  Content? movie;
  User? user;
  String? status;
  bool? active;
  int? remainingDays;

  UserContent(
      {this.id,
      this.contentPercentage,
      this.dateFrom,
      this.dateTo,
      this.refferedBy,
      this.price,
      this.isGifted,
      this.userIdGiftFrom,
      this.userIdGiftTo,
      this.movie,
      this.user,
      this.status,
      this.active,
      this.remainingDays});

  factory UserContent.fromJson(Map<String, dynamic> json) => UserContent(
      id: json["id"],
      contentPercentage: _asDouble(json["contentPercentage"]),
      dateFrom: json["dateFrom"],
      dateTo: json["dateTo"],
      refferedBy: json["refferedBy"],
      price: json["price"],
      isGifted: json["isGifted"],
      userIdGiftFrom: json["userIdGiftFrom"],
      userIdGiftTo: json["userIdGiftTo"],
      movie: json["movie"] == null ? null : Content.fromJson(json["movie"]),
      user: json["user"] == null ? null : User.fromJson(json["user"]),
      status: json["status"],
      active: json["active"],
      remainingDays: json["remainingDays"] ?? 0);

  Map<String, dynamic> toJson() => {
        "id": id,
        "contentPercentage": contentPercentage,
        "dateFrom": dateFrom,
        "dateTo": dateTo,
        "refferedBy": refferedBy,
        "price": price,
        "isGifted": isGifted,
        "userIdGiftFrom": userIdGiftFrom,
        "userIdGiftTo": userIdGiftTo,
        "movie": movie?.toJson(),
        "user": user?.toJson(),
        "status": status,
        "active": active,
        "remainingDays": remainingDays
      };
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
