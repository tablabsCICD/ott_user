import 'package:ott/data/models/seriesModel.dart';

int _asInt(dynamic val, [int fallback = 0]) {
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class SeriesDetailsResponse {
  final SeriesUserData data;

  SeriesDetailsResponse({required this.data});

  factory SeriesDetailsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
    return SeriesDetailsResponse(
      data: SeriesUserData.fromJson(dataMap),
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
    final rawSeasons = json['seasons'];
    final seasonsList = rawSeasons is List ? rawSeasons : const [];
    return SeriesUserData(
      seriesId: _asInt(json['seriesId']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
      seasons: seasonsList
          .whereType<Map>()
          .map((e) => SeasonResponse.fromJson(Map<String, dynamic>.from(e)))
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
    final rawEpisodes = json['episodes'];
    final episodesList = rawEpisodes is List ? rawEpisodes : const [];
    return SeasonResponse(
      seasonId: _asInt(json['seasonId']),
      seasonNumber: _asInt(json['seasonNumber'], 1),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      releaseDate: _asInt(json['releaseDate']),
      isSeasonPurchased: json['isSeasonPurchased'] == true,
      price: json['price'] is num ? json['price'] as num : num.tryParse('${json['price']}'),
      episodes: episodesList
          .whereType<Map>()
          .map((e) => EpisodeResponse.fromJson(Map<String, dynamic>.from(e)))
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
      episodeId: _asInt(json['episodeId']),
      episodeNumber: _asInt(json['episodeNumber'], 1),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      runtime: _asInt(json['runtime']),
      releaseDate: _asInt(json['releaseDate']),
      isFree: json['isFree'] == true || json['free'] == true,
      posterUrl: json['posterUrl']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString(),
      isPurchased: json['isPurchased'] == true || json['episodePurchased'] == true,
      isLocked: json['isLocked'] == true || json['locked'] == true,
      price: json['price'] is num ? json['price'] as num : num.tryParse('${json['price']}'),
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
