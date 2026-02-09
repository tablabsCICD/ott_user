import 'package:ott/data/models/content.dart';

class ShortModel {
  final int id;
  final String title;
  final String description;
  final String posterUrl;
  final int totalParts;
  final int coinsPerPart;
  final String creatorName;
  final int viewCount;
  final int likeCount;
  final bool isTrending;
  final String category;
  final int? mediaHouseId;
  String rentlDuration;
  List<LanguageList> languageList;

  ShortModel({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.totalParts,
    required this.coinsPerPart,
    required this.creatorName,
    required this.viewCount,
    required this.likeCount,
    required this.isTrending,
    required this.category,
    this.mediaHouseId,
    required this.rentlDuration,
    required this.languageList,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    return ShortModel(
      id: json["id"] ?? 0,
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      posterUrl: json["posterUrl"] ?? "",
      totalParts: json["totalParts"] ?? 0,
      coinsPerPart: json["coinsPerPart"] ?? 0,
      creatorName: json["creatorName"] ?? "",
      viewCount: json["viewCount"] ?? 0,
      likeCount: json["likeCount"] ?? 0,
      isTrending: json["isTrending"] ?? false,
      category: json["category"] ?? "",
      mediaHouseId: json["mediaHouseId"],
      rentlDuration: json["rentlDuration"] ?? "",
      languageList: (json["languageList"] as List? ?? [])
          .map((e) => LanguageList.fromJson(e))
          .toList(),
    );
  }
}

class ShortDetailModel {
  final int id;
  final String title;
  final String description;
  final String poster;
  final int totalParts;
  final int coinsPerPart;
  final String creatorName;
  final int viewCount;
  final int likeCount;
  final bool isTrending;
  final String category;
  final List<dynamic> tags;
  final List<ShortPart> parts;

  ShortDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.poster,
    required this.totalParts,
    required this.coinsPerPart,
    required this.creatorName,
    required this.viewCount,
    required this.likeCount,
    required this.isTrending,
    required this.category,
    required this.tags,
    required this.parts,
  });

  factory ShortDetailModel.fromJson(Map<String, dynamic> json) {
    return ShortDetailModel(
      id: json["id"] ?? 0,
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      poster: json["poster"] ?? "",
      totalParts: json["totalParts"] ?? 0,
      coinsPerPart: json["coinsPerPart"] ?? 0,
      creatorName: json["creatorName"] ?? "",
      viewCount: json["viewCount"] ?? 0,
      likeCount: json["likeCount"] ?? 0,
      isTrending: json["isTrending"] ?? false,
      category: json["category"] ?? "",
      tags: json["tags"] ?? [],
      parts: (json["parts"] as List? ?? [])
          .map((e) => ShortPart.fromJson(e))
          .toList(),
    );
  }
}

class ShortPart {
  final String partId;
  final int partNumber;
  final String title;
  final int coins;
  bool isLocked;
  bool isPurchased;
  final String videoUrl;
  final String thumbnail;
  final int durationSec;
  int views;
  int likes;
  final String? nextPartId;
  final bool autoPlayNext;
  bool isFreePreview;
  bool isLiked;

  ShortPart({
    required this.partId,
    required this.partNumber,
    required this.title,
    required this.coins,
    required this.isLocked,
    required this.isPurchased,
    required this.videoUrl,
    required this.thumbnail,
    required this.durationSec,
    required this.views,
    required this.likes,
    this.nextPartId,
    required this.autoPlayNext,
    required this.isFreePreview,
    required this.isLiked,
  });

  factory ShortPart.fromJson(Map<String, dynamic> json) {
    return ShortPart(
      partId: json["partId"].toString(),
      partNumber: json["partNumber"] ?? 0,
      title: json["title"] ?? "",
      coins: json["coins"] ?? 0,
      isLocked: json["isLocked"] ?? json["locked"] ?? false,
      isPurchased: json["isPurchased"] ?? json["purchased"] ?? false,
      videoUrl: json["videoUrl"] ?? "",
      thumbnail: json["thumbnail"] ?? "",
      durationSec: json["durationSec"] ?? 0,
      views: json["views"] ?? 0,
      likes: json["likes"] ?? 0,
      nextPartId: json["nextPartId"]?.toString(),
      autoPlayNext: json["autoPlayNext"] ?? false,
      isFreePreview: json["isFreePreview"] ?? json["freePreview"] ?? false,
      isLiked: json["isLiked"] ?? json["liked"] ?? false,
    );
  }
}
