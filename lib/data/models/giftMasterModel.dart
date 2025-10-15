import 'package:ott/data/models/content.dart';

class GiftMasterModel {
  String? couponCode;
  bool? active;
  int? giftMasterId;
  int? giftOwnerId;
  String? giftOwnerName;
  String? giftOwnerEmail;
  String? giftOwnerMobile;
  String? giftOwnerImage;
  int? totalGiftCount;
  int? remainingGiftCount;
  double? totalPaid;
  int? createdDate;
  List<GiftUser>? user;
  Content? movie;

  GiftMasterModel({
    this.couponCode,
    this.active,
    this.giftMasterId,
    this.giftOwnerId,
    this.giftOwnerName,
    this.giftOwnerEmail,
    this.giftOwnerMobile,
    this.giftOwnerImage,
    this.totalGiftCount,
    this.remainingGiftCount,
    this.totalPaid,
    this.createdDate,
    this.user,
    this.movie,
  });

  factory GiftMasterModel.fromJson(Map<String, dynamic> json) =>
      GiftMasterModel(
        couponCode: json["couponCode"],
        active: json["active"],
        giftMasterId: json["giftMasterId"],
        giftOwnerId: json["giftOwnerId"],
        giftOwnerName: json["giftOwnerName"],
        giftOwnerEmail: json["giftOwnerEmail"],
        giftOwnerMobile: json["giftOwnerMobile"],
        giftOwnerImage: json["giftOwnerImage"],
        totalGiftCount: json["totalGiftCount"],
        remainingGiftCount: json["remainingGiftCount"],
        totalPaid: json["totalPaid"],
        createdDate: json["createdDate"],
        user: (json["user"] is List)
            ? (json["user"] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => GiftUser.fromJson(e))
                .toList()
            : null,
        movie: json["movie"] == null ? null : Content.fromJson(json["movie"]),
      );

  Map<String, dynamic> toJson() => {
        "couponCode": couponCode,
        "active": active,
        "giftMasterId": giftMasterId,
        "giftOwnerId": giftOwnerId,
        "giftOwnerName": giftOwnerName,
        "giftOwnerEmail": giftOwnerEmail,
        "giftOwnerMobile": giftOwnerMobile,
        "giftOwnerImage": giftOwnerImage,
        "totalGiftCount": totalGiftCount,
        "remainingGiftCount": remainingGiftCount,
        "totalPaid": totalPaid,
        "createdDate": createdDate,
        "user": user,
        "movie": movie?.toJson(),
      };
}

class GiftUser {
  final String? image;
  final String? name;
  final String? mobile;
  final int? userId;
  final String? email;
  GiftUser({this.image, this.name, this.mobile, this.userId, this.email});
  factory GiftUser.fromJson(Map<String, dynamic> json) => GiftUser(
        image: json["image"],
        name: json["name"],
        mobile: json["mobile"],
        userId: json["userId"],
        email: json["email"],
      );
}
