import 'package:ott/data/models/content.dart';

class GiftRecordModel {
  int? totalGiftCount;
  int? createdDate;
  int? giftOwnerId;
  Content? movie;
  double? totalPaid;
  int? id;
  bool? isActive;
  int? remainingGiftCount;
  String? couponCode;

  GiftRecordModel({
    this.totalGiftCount,
    this.createdDate,
    this.giftOwnerId,
    this.movie,
    this.totalPaid,
    this.id,
    this.isActive,
    this.remainingGiftCount,
    this.couponCode,
  });

  factory GiftRecordModel.fromJson(Map<String, dynamic> json) =>
      GiftRecordModel(
        totalGiftCount: json["totalGiftCount"],
        createdDate: json["createdDate"],
        giftOwnerId: json["giftOwnerId"],
        movie: json["movie"] == null ? null : Content.fromJson(json["movie"]),
        totalPaid: json["totalPaid"],
        id: json["id"],
        isActive: json["isActive"],
        remainingGiftCount: json["remainingGiftCount"],
        couponCode: json["couponCode"],
      );

  Map<String, dynamic> toJson() => {
        "totalGiftCount": totalGiftCount,
        "createdDate": createdDate,
        "giftOwnerId": giftOwnerId,
        "movie": movie?.toJson(),
        "totalPaid": totalPaid,
        "id": id,
        "isActive": isActive,
        "remainingGiftCount": remainingGiftCount,
        "couponCode": couponCode,
      };
}
