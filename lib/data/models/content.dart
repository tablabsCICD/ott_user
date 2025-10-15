class Content {
  int? id;
  String? title;
  String? description;
  int? runtime;
  dynamic releaseDate;
  double? ratings;
  double? price;
  List<LanguageList>? languageList;
  List<String>? castList;
  List<String>? genreList;
  List<String>? directorList;
  int? views;
  double? totalRevenue;
  String? ageRating;
  List<String>? posterUrlList;
  String? trailerUrl;
  String? contentUrl;
  String? approvalStatus;
  String? type;
  String? sensorCertificate;
  bool? isFeatured;
  Availability? availability;
  List<String>? audioFormatList;
  List<String>? subtitleLanguageList;
  bool? isDownloadable;
  int? uploadDateTime;
  int? approvedDateTime;
  String? mediaHouseName;
  int? mediaHouseId;
  int? ratingCount;
  String? rentlDuration;
  bool? isRental;

  Content(
      {this.id,
      this.title,
      this.description,
      this.runtime,
      this.releaseDate,
      this.ratings,
      this.price,
      this.languageList,
      this.castList,
      this.genreList,
      this.directorList,
      this.views,
      this.totalRevenue,
      this.ageRating,
      this.posterUrlList,
      this.trailerUrl,
      this.contentUrl,
      this.approvalStatus,
      this.type,
      this.sensorCertificate,
      this.isFeatured,
      this.availability,
      this.audioFormatList,
      this.subtitleLanguageList,
      this.isDownloadable,
      this.uploadDateTime,
      this.approvedDateTime,
      this.mediaHouseName,
      this.mediaHouseId,
      this.ratingCount,
      this.rentlDuration,
      this.isRental});

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        runtime: json["runtime"],
        releaseDate: json["releaseDate"],
        ratings: json["ratings"]?.toDouble(),
        price: json["price"]?.toDouble(),
        languageList: json["languageList"] == null
            ? []
            : List<LanguageList>.from(
                json["languageList"]!.map((x) => LanguageList.fromJson(x))),
        castList: json["castList"] == null
            ? []
            : List<String>.from(json["castList"]!.map((x) => x)),
        genreList: json["genreList"] == null
            ? []
            : List<String>.from(json["genreList"]!.map((x) => x)),
        directorList: json["directorList"] == null
            ? []
            : List<String>.from(json["directorList"]!.map((x) => x)),
        views: json["views"],
        totalRevenue: json["totalRevenue"]?.toDouble(),
        ageRating: json["ageRating"],
        posterUrlList: json["posterUrlList"] == null
            ? []
            : List<String>.from(json["posterUrlList"]!.map((x) => x)),
        trailerUrl: json["trailerUrl"],
        contentUrl: json["contentUrl"],
        approvalStatus: json["approvalStatus"],
        type: json["type"],
        sensorCertificate: json["sensorCertificate"],
        isFeatured: json["isFeatured"],
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
        uploadDateTime: json["uploadDateTime"],
        approvedDateTime: json["approvedDateTime"],
        mediaHouseName: json["mediaHouseName"],
        mediaHouseId: json["mediaHouseId"],
        ratingCount: json["ratingCount"],
        rentlDuration: json["rentlDuration"],
        isRental: json["isRental"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "runtime": runtime,
        "releaseDate": releaseDate,
        "ratings": ratings,
        "price": price,
        "languageList": languageList == null
            ? []
            : List<dynamic>.from(languageList!.map((x) => x.toJson())),
        "castList":
            castList == null ? [] : List<dynamic>.from(castList!.map((x) => x)),
        "genreList": genreList == null
            ? []
            : List<dynamic>.from(genreList!.map((x) => x)),
        "directorList": directorList == null
            ? []
            : List<dynamic>.from(directorList!.map((x) => x)),
        "views": views,
        "totalRevenue": totalRevenue,
        "ageRating": ageRating,
        "posterUrlList": posterUrlList == null
            ? []
            : List<dynamic>.from(posterUrlList!.map((x) => x)),
        "trailerUrl": trailerUrl,
        "contentUrl": contentUrl,
        "approvalStatus": approvalStatus,
        "type": type,
        "sensorCertificate": sensorCertificate,
        "isFeatured": isFeatured,
        "availability": availability?.toJson(),
        "audioFormatList": audioFormatList == null
            ? []
            : List<dynamic>.from(audioFormatList!.map((x) => x)),
        "subtitleLanguageList": subtitleLanguageList == null
            ? []
            : List<dynamic>.from(subtitleLanguageList!.map((x) => x)),
        "isDownloadable": isDownloadable,
        "uploadDateTime": uploadDateTime,
        "approvedDateTime": approvedDateTime,
        "mediaHouseName": mediaHouseName,
        "mediaHouseId": mediaHouseId,
        "ratingCount": ratingCount,
        "rentlDuration": rentlDuration,
        "isRental": isRental
      };
}

class Availability {
  List<String>? regions;
  List<String>? platforms;

  Availability({
    this.regions,
    this.platforms,
  });

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        regions: json["regions"] == null
            ? []
            : List<String>.from(json["regions"]!.map((x) => x)),
        platforms: json["platforms"] == null
            ? []
            : List<String>.from(json["platforms"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "regions":
            regions == null ? [] : List<dynamic>.from(regions!.map((x) => x)),
        "platforms": platforms == null
            ? []
            : List<dynamic>.from(platforms!.map((x) => x)),
      };
}

class LanguageList {
  String? language;
  String? fileUrl;

  LanguageList({
    this.language,
    this.fileUrl,
  });

  factory LanguageList.fromJson(Map<String, dynamic> json) => LanguageList(
        language: json["language"],
        fileUrl: json["fileUrl"],
      );

  Map<String, dynamic> toJson() => {
        "language": language,
        "fileUrl": fileUrl,
      };
}
