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
  Movie? movie;
  UserContent? userContentPurchase;
  User? user;

  Data({
    this.movie,
    this.userContentPurchase,
    this.user,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        movie: json["movie"] == null ? null : Movie.fromJson(json["movie"]),
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

class Movie {
  int? id;
  String? title;
  String? description;
  int? runtime;
  DateTime? releaseDate;
  double? ratings;
  double? price;
  List<String>? languageList;
  List<String>? genreList;
  List<dynamic>? directorList;
  List<dynamic>? castList;
  int? views;
  double? totalRevenue;
  String? ageRating;
  List<String>? posterUrlList;
  String? trailerUrl;
  String? contentUrl;
  String? approvalStatus;
  String? type;
  String? sensorCertificate;
  Availability? availability;
  List<String>? audioFormatList;
  List<String>? subtitleLanguageList;
  bool? isDownloadable;
  bool? isFeatured;
  dynamic approvedDateTime;
  int? uploadDateTime;
  dynamic reason;
  int? ratingCount;
  String? rentlDuration;
  MediaHouse? mediaHouse;
  bool? active;

  Movie({
    this.id,
    this.title,
    this.description,
    this.runtime,
    this.releaseDate,
    this.ratings,
    this.price,
    this.languageList,
    this.genreList,
    this.directorList,
    this.castList,
    this.views,
    this.totalRevenue,
    this.ageRating,
    this.posterUrlList,
    this.trailerUrl,
    this.contentUrl,
    this.approvalStatus,
    this.type,
    this.sensorCertificate,
    this.availability,
    this.audioFormatList,
    this.subtitleLanguageList,
    this.isDownloadable,
    this.isFeatured,
    this.approvedDateTime,
    this.uploadDateTime,
    this.reason,
    this.ratingCount,
    this.rentlDuration,
    this.mediaHouse,
    this.active,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        runtime: json["runtime"],
        releaseDate: json["releaseDate"] == null
            ? null
            : DateTime.parse(json["releaseDate"]),
        ratings: json["ratings"],
        price: json["price"],
        languageList: json["languageList"] == null
            ? []
            : List<String>.from(json["languageList"]!.map((x) => x)),
        genreList: json["genreList"] == null
            ? []
            : List<String>.from(json["genreList"]!.map((x) => x)),
        directorList: json["directorList"] == null
            ? []
            : List<dynamic>.from(json["directorList"]!.map((x) => x)),
        castList: json["castList"] == null
            ? []
            : List<dynamic>.from(json["castList"]!.map((x) => x)),
        views: json["views"],
        totalRevenue: json["totalRevenue"],
        ageRating: json["ageRating"],
        posterUrlList: json["posterUrlList"] == null
            ? []
            : List<String>.from(json["posterUrlList"]!.map((x) => x)),
        trailerUrl: json["trailerURL"],
        contentUrl: json["contentURL"],
        approvalStatus: json["approvalStatus"],
        type: json["type"],
        sensorCertificate: json["sensorCertificate"],
        availability: json["availability"] == null
            ? null
            : Availability.fromJson(json["availability"]),
        audioFormatList: json["audioFormatList"] == null
            ? []
            : List<String>.from(json["audioFormatList"]!.map((x) => x)),
        subtitleLanguageList: json["subtitleLanguageList"] == null
            ? []
            : List<String>.from(json["subtitleLanguageList"]!.map((x) => x)),
        isDownloadable: json["isDownloadable"],
        isFeatured: json["isFeatured"],
        approvedDateTime: json["approvedDateTime"],
        uploadDateTime: json["uploadDateTime"],
        reason: json["reason"],
        ratingCount: json["ratingCount"],
        rentlDuration: json["rentlDuration"],
        mediaHouse: json["mediaHouse"] == null
            ? null
            : MediaHouse.fromJson(json["mediaHouse"]),
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "runtime": runtime,
        "releaseDate":
            "${releaseDate!.year.toString().padLeft(4, '0')}-${releaseDate!.month.toString().padLeft(2, '0')}-${releaseDate!.day.toString().padLeft(2, '0')}",
        "ratings": ratings,
        "price": price,
        "languageList": languageList == null
            ? []
            : List<dynamic>.from(languageList!.map((x) => x)),
        "genreList": genreList == null
            ? []
            : List<dynamic>.from(genreList!.map((x) => x)),
        "directorList": directorList == null
            ? []
            : List<dynamic>.from(directorList!.map((x) => x)),
        "castList":
            castList == null ? [] : List<dynamic>.from(castList!.map((x) => x)),
        "views": views,
        "totalRevenue": totalRevenue,
        "ageRating": ageRating,
        "posterUrlList": posterUrlList == null
            ? []
            : List<dynamic>.from(posterUrlList!.map((x) => x)),
        "trailerURL": trailerUrl,
        "contentURL": contentUrl,
        "approvalStatus": approvalStatus,
        "type": type,
        "sensorCertificate": sensorCertificate,
        "availability": availability?.toJson(),
        "audioFormatList": audioFormatList == null
            ? []
            : List<dynamic>.from(audioFormatList!.map((x) => x)),
        "subtitleLanguageList": subtitleLanguageList == null
            ? []
            : List<dynamic>.from(subtitleLanguageList!.map((x) => x)),
        "isDownloadable": isDownloadable,
        "isFeatured": isFeatured,
        "approvedDateTime": approvedDateTime,
        "uploadDateTime": uploadDateTime,
        "reason": reason,
        "ratingCount": ratingCount,
        "rentlDuration": rentlDuration,
        "mediaHouse": mediaHouse?.toJson(),
        "active": active,
      };
}

class Availability {
  List<dynamic>? regions;
  List<dynamic>? platforms;

  Availability({
    this.regions,
    this.platforms,
  });

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        regions: json["regions"] == null
            ? []
            : List<dynamic>.from(json["regions"]!.map((x) => x)),
        platforms: json["platforms"] == null
            ? []
            : List<dynamic>.from(json["platforms"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "regions":
            regions == null ? [] : List<dynamic>.from(regions!.map((x) => x)),
        "platforms": platforms == null
            ? []
            : List<dynamic>.from(platforms!.map((x) => x)),
      };
}

class MediaHouse {
  int? id;
  String? mediaHouseName;
  String? address;
  String? contactNumber;
  String? email;
  String? registrationCertificate;
  String? gstCertificates;
  String? adharCard;
  String? shopAct;
  String? panCard;
  int? createdDate;
  int? updatedDate;
  String? profileImage;
  String? otp;
  String? password;
  String? status;
  DateTime? joinDate;
  String? logo;
  String? totalReveneu;
  String? postCount;
  String? discription;
  User? user;
  Location? location;
  String? totalViews;
  bool? active;

  MediaHouse({
    this.id,
    this.mediaHouseName,
    this.address,
    this.contactNumber,
    this.email,
    this.registrationCertificate,
    this.gstCertificates,
    this.adharCard,
    this.shopAct,
    this.panCard,
    this.createdDate,
    this.updatedDate,
    this.profileImage,
    this.otp,
    this.password,
    this.status,
    this.joinDate,
    this.logo,
    this.totalReveneu,
    this.postCount,
    this.discription,
    this.user,
    this.location,
    this.totalViews,
    this.active,
  });

  factory MediaHouse.fromJson(Map<String, dynamic> json) => MediaHouse(
        id: json["id"],
        mediaHouseName: json["mediaHouseName"],
        address: json["address"],
        contactNumber: json["contactNumber"],
        email: json["email"],
        registrationCertificate: json["registrationCertificate"],
        gstCertificates: json["gstCertificates"],
        adharCard: json["adharCard"],
        shopAct: json["shopAct"],
        panCard: json["panCard"],
        createdDate: json["createdDate"],
        updatedDate: json["updatedDate"],
        profileImage: json["profileImage"],
        otp: json["otp"],
        password: json["password"],
        status: json["status"],
        joinDate:
            json["joinDate"] == null ? null : DateTime.parse(json["joinDate"]),
        logo: json["logo"],
        totalReveneu: json["totalReveneu"],
        postCount: json["postCount"],
        discription: json["discription"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
        totalViews: json["totalViews"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "mediaHouseName": mediaHouseName,
        "address": address,
        "contactNumber": contactNumber,
        "email": email,
        "registrationCertificate": registrationCertificate,
        "gstCertificates": gstCertificates,
        "adharCard": adharCard,
        "shopAct": shopAct,
        "panCard": panCard,
        "createdDate": createdDate,
        "updatedDate": updatedDate,
        "profileImage": profileImage,
        "otp": otp,
        "password": password,
        "status": status,
        "joinDate": joinDate?.toIso8601String(),
        "logo": logo,
        "totalReveneu": totalReveneu,
        "postCount": postCount,
        "discription": discription,
        "user": user?.toJson(),
        "location": location?.toJson(),
        "totalViews": totalViews,
        "active": active,
      };
}

class Location {
  int? id;
  String? country;
  String? state;
  String? district;
  String? taluka;
  String? city;
  String? area;
  String? pincode;
  String? officeBuilding;

  Location({
    this.id,
    this.country,
    this.state,
    this.district,
    this.taluka,
    this.city,
    this.area,
    this.pincode,
    this.officeBuilding,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json["id"],
        country: json["country"],
        state: json["state"],
        district: json["district"],
        taluka: json["taluka"],
        city: json["city"],
        area: json["area"],
        pincode: json["pincode"],
        officeBuilding: json["officeBuilding"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "country": country,
        "state": state,
        "district": district,
        "taluka": taluka,
        "city": city,
        "area": area,
        "pincode": pincode,
        "officeBuilding": officeBuilding,
      };
}
