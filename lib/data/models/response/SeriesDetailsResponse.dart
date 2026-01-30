import 'package:ott/data/models/seriesModel.dart';

class SeriesDetailsResponse {
  final SeriesUserData data;

  SeriesDetailsResponse({required this.data});

  factory SeriesDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SeriesDetailsResponse(
      data: SeriesUserData.fromJson(json['data']),
    );
  }

  SeriesEntity toEntity() => data.toEntity();
}

class SeriesUserData {
  final int seriesId;
  final String title;
  final String description;
  final String posterUrl;
  final List<SeasonResponse> seasons;

  SeriesUserData({
    required this.seriesId,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.seasons,
  });

  factory SeriesUserData.fromJson(Map<String, dynamic> json) {
    return SeriesUserData(
      seriesId: json['seriesId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      seasons: (json['seasons'] as List)
          .map((e) => SeasonResponse.fromJson(e))
          .toList(),
    );
  }

  SeriesEntity toEntity() {
    return SeriesEntity(
      id: seriesId,
      title: title,
      description: description,
      posterUrl: posterUrl,
      seasons: seasons.map((e) => e.toEntity()).toList(),
    );
  }
}

class SeasonResponse {
  final int seasonId;
  final int seasonNumber;
  final String title;
  final String description;
  final int releaseDate;
  final bool isSeasonPurchased;
  final num? price;
  final List<EpisodeResponse> episodes;

  SeasonResponse({
    required this.seasonId,
    required this.seasonNumber,
    required this.title,
    required this.description,
    required this.releaseDate,
    required this.isSeasonPurchased,
    required this.price,
    required this.episodes,
  });

  factory SeasonResponse.fromJson(Map<String, dynamic> json) {
    return SeasonResponse(
      seasonId: json['seasonId'],
      seasonNumber: json['seasonNumber'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      releaseDate: json['releaseDate'],
      isSeasonPurchased: json['isSeasonPurchased'] ?? false,
      price: json['price'],
      episodes: (json['episodes'] as List)
          .map((e) => EpisodeResponse.fromJson(e))
          .toList(),
    );
  }

  SeasonEntity toEntity() {
    return SeasonEntity(
      seasonId: seasonId,
      seasonNumber: seasonNumber,
      title: title,
      description: description,
      releaseDate: releaseDate,
      price: (price ?? 0).toDouble(),
      isSeasonPurchased: isSeasonPurchased,
      episodes: episodes.map((e) => e.toEntity()).toList(),
    );
  }
}

class EpisodeResponse {
  final int episodeId;
  final int episodeNumber;
  final String title;
  final String description;
  final int runtime;
  final int releaseDate;
  final bool isFree;
  final String posterUrl;
  final String? videoUrl;
  final bool isPurchased;
  final bool isLocked;
  final num? price;

  EpisodeResponse({
    required this.episodeId,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.runtime,
    required this.releaseDate,
    required this.isFree,
    required this.posterUrl,
    required this.videoUrl,
    required this.isPurchased,
    required this.isLocked,
    required this.price,
  });

  factory EpisodeResponse.fromJson(Map<String, dynamic> json) {
    return EpisodeResponse(
      episodeId: json['episodeId'],
      episodeNumber: json['episodeNumber'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      runtime: json['runtime'],
      releaseDate: json['releaseDate'],
      isFree: json['isFree'] ?? json['free'] ?? false,
      posterUrl: json['posterUrl'] ?? '',
      videoUrl: json['videoUrl'],
      isPurchased: json['isPurchased'] ?? json['episodePurchased'] ?? false,
      isLocked: json['isLocked'] ?? json['locked'] ?? true,
      price: json['price'],
    );
  }

  EpisodeEntity toEntity() {
    return EpisodeEntity(
      episodeId: episodeId,
      episodeNumber: episodeNumber,
      title: title,
      description: description,
      runtime: runtime,
      releaseDate: releaseDate,
      posterUrl: posterUrl,
      videoUrl: videoUrl,
      price: (price ?? 0).toDouble(),
      isFree: isFree,
      isPurchased: isPurchased,
      isLocked: isLocked,
    );
  }
}
