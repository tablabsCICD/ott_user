class ShortModel {
  final int id;
  final String title;
  final String posterUrl;
  final int totalParts;
  final String creatorName;
  final bool isTrending;
  final String category;
  final int viewCount;
  final int likeCount;

  ShortModel({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.totalParts,
    required this.creatorName,
    required this.isTrending,
    required this.category,
    required this.viewCount,
    required this.likeCount,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    return ShortModel(
      id: json["id"],
      title: json["title"] ?? "",
      posterUrl: json["posterUrl"] ?? "",
      totalParts: json["totalParts"] ?? 0,
      creatorName: json["creatorName"] ?? "",
      isTrending: json["isTrending"] ?? false,
      category: json["category"] ?? "",
      viewCount: json["viewCount"] ?? 0,
      likeCount: json["likeCount"] ?? 0,
    );
  }
}

class ShortDetailModel {
  final int id;
  final String title;
  final String description;
  final String poster;
  final int totalParts;
  final String creatorName;
  final List<ShortPart> parts;

  ShortDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.poster,
    required this.totalParts,
    required this.creatorName,
    required this.parts,
  });

  factory ShortDetailModel.fromJson(Map<String, dynamic> json) {
    return ShortDetailModel(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      poster: json["poster"] ?? "",
      totalParts: json["totalParts"],
      creatorName: json["creatorName"],
      parts: (json["parts"] as List).map((e) => ShortPart.fromJson(e)).toList(),
    );
  }
}

class ShortPart {
  final String partId;
  final int partNumber;
  final String title;
  final String videoUrl;
  final String thumbnail;
  final int durationSec;
  final bool locked;
  final bool purchased;

  ShortPart({
    required this.partId,
    required this.partNumber,
    required this.title,
    required this.videoUrl,
    required this.thumbnail,
    required this.durationSec,
    required this.locked,
    required this.purchased,
  });

  factory ShortPart.fromJson(Map<String, dynamic> json) {
    return ShortPart(
      partId: json["partId"].toString(),
      partNumber: json["partNumber"],
      title: json["title"],
      videoUrl: json["videoUrl"],
      thumbnail: json["thumbnail"],
      durationSec: json["durationSec"],
      locked: json["locked"] ?? false,
      purchased: json["purchased"] ?? false,
    );
  }
}
