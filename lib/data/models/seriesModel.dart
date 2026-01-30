class SeriesEntity {
  final int id;
  final String title;
  final String description;
  final String posterUrl;
  final List<SeasonEntity> seasons;

  SeriesEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.seasons,
  });
}

class SeasonEntity {
  final int seasonId;
  final int seasonNumber;
  final String title;
  final String description;
  final int releaseDate;

  double price;
  bool isSeasonPurchased;
  List<EpisodeEntity> episodes;

  SeasonEntity({
    required this.seasonId,
    required this.seasonNumber,
    required this.title,
    required this.description,
    required this.releaseDate,
    required this.price,
    required this.isSeasonPurchased,
    required this.episodes,
  });
}

class EpisodeEntity {
  final int episodeId;
  final int episodeNumber;
  final String title;
  final String description;
  final int runtime;
  final int releaseDate;
  final String posterUrl;
  final String? videoUrl;

  double price;
  bool isFree;
  bool isPurchased;
  bool isLocked;

  EpisodeEntity({
    required this.episodeId,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.runtime,
    required this.releaseDate,
    required this.posterUrl,
    required this.videoUrl,
    required this.price,
    required this.isFree,
    required this.isPurchased,
    required this.isLocked,
  });
}
