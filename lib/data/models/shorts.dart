import 'package:ott/data/models/content.dart';

// The backend may send numbers as int (20), double (20.0) or text ("20").
// A strict `as int` / int field assignment throws on 20.0 and fails the whole
// mini series list, so every number goes through these helpers.
int _toInt(dynamic value, [int fallback = 0]) => _toIntOrNull(value) ?? fallback;

int? _toIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class MiniSeriesPage {
  final List<ShortModel> content;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  const MiniSeriesPage(
      {required this.content,
      required this.page,
      required this.size,
      required this.totalPages,
      required this.totalElements});

  factory MiniSeriesPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List? ?? const [];
    return MiniSeriesPage(
      content: rawContent
          .whereType<Map<String, dynamic>>()
          .map(ShortModel.fromJson)
          .toList(),
      page: _toIntOrNull(json['number']) ?? _toInt(json['page']),
      size: _toIntOrNull(json['size']) ?? rawContent.length,
      totalPages: _toInt(json['totalPages']),
      totalElements: _toIntOrNull(json['totalElements']) ?? rawContent.length,
    );
  }
}

class ShortModel {
  final int id;
  final String title;
  final String description;
  final String posterUrl;
  final int totalParts;
  final double coinsPerPart;
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
      id: _toInt(json["id"]),
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      posterUrl: json["posterUrl"] ?? "",
      totalParts: _toInt(json["totalParts"]),
      coinsPerPart: _toDouble(json["coinsPerPart"]),
      creatorName: json["creatorName"] ?? "",
      viewCount: _toInt(json["viewCount"]),
      likeCount: _toInt(json["likeCount"]),
      isTrending: json["isTrending"] ?? false,
      category: json["category"] ?? "",
      mediaHouseId: _toIntOrNull(json["mediaHouseId"]),
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
  final double coinsPerPart;
  final String creatorName;
  final int viewCount;
  final int likeCount;
  final bool isTrending;
  final String category;
  final List<dynamic> tags;
  final List<ShortPart> parts;

  /// True when the user owns the whole mini series through a claimed gift.
  /// Backend-provided; every non-free part is then playable without payment.
  final bool hasFullSeriesGiftAccess;

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
    this.hasFullSeriesGiftAccess = false,
  });

  factory ShortDetailModel.fromJson(Map<String, dynamic> json) {
    return ShortDetailModel(
      id: _toInt(json["id"]),
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      poster: json["poster"] ?? "",
      totalParts: _toInt(json["totalParts"]),
      coinsPerPart: _toDouble(json["coinsPerPart"]),
      creatorName: json["creatorName"] ?? "",
      viewCount: _toInt(json["viewCount"]),
      likeCount: _toInt(json["likeCount"]),
      isTrending: json["isTrending"] ?? false,
      category: json["category"] ?? "",
      tags: json["tags"] ?? [],
      parts: (json["parts"] as List? ?? [])
          .map((e) => ShortPart.fromJson(e))
          .toList(),
      hasFullSeriesGiftAccess: json["hasFullSeriesGiftAccess"] == true,
    );
  }
}

class ShortPart {
  final String partId;
  final int partNumber;
  final String title;
  final double coins;
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
      partNumber: _toInt(json["partNumber"]),
      title: json["title"] ?? "",
      coins: _toDouble(json["coins"]),
      isLocked: json["isLocked"] ?? json["locked"] ?? false,
      isPurchased: json["isPurchased"] ?? json["purchased"] ?? false,
      videoUrl: json["videoUrl"] ?? "",
      thumbnail: json["thumbnail"] ?? "",
      durationSec: _toInt(json["durationSec"]),
      views: _toInt(json["views"]),
      likes: _toInt(json["likes"]),
      nextPartId: json["nextPartId"]?.toString(),
      autoPlayNext: json["autoPlayNext"] ?? false,
      isFreePreview: json["isFreePreview"] ?? json["freePreview"] ?? false,
      isLiked: json["isLiked"] ?? json["liked"] ?? false,
    );
  }
}

extension ShortModelShareContent on ShortModel {
  Content toShareContent() {
    return Content(
      id: id,
      title: title,
      description: description,
      price: coinsPerPart.toDouble(),
      languageList: languageList,
      posterUrlList: posterUrl.isNotEmpty ? <String>[posterUrl] : <String>[],
      type: 'short',
      mediaHouseId: mediaHouseId,
      rentlDuration: rentlDuration,
      views: viewCount,
    );
  }
}

extension ShortDetailModelShareContent on ShortDetailModel {
  Content toShareContent() {
    return Content(
      id: id,
      title: title,
      description: description,
      price: coinsPerPart.toDouble(),
      posterUrlList: poster.isNotEmpty ? <String>[poster] : <String>[],
      type: 'short',
      views: viewCount,
    );
  }
}
