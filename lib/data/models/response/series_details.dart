class SeriesDetailsResponse {
  final List<SeasonBundle> seasons;
  final Series series;

  SeriesDetailsResponse({
    required this.seasons,
    required this.series,
  });

  factory SeriesDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SeriesDetailsResponse(
      seasons: (json['seasons'] as List)
          .map((e) => SeasonBundle.fromJson(e))
          .toList(),
      series: Series.fromJson(json['series']),
    );
  }
}

class SeasonBundle {
  final Season season;
  final List<Episode> episodes;

  SeasonBundle({
    required this.season,
    required this.episodes,
  });

  factory SeasonBundle.fromJson(Map<String, dynamic> json) {
    return SeasonBundle(
      season: Season.fromJson(json['season']),
      episodes:
          (json['episodes'] as List).map((e) => Episode.fromJson(e)).toList(),
    );
  }
}

class Season {
  final int id;
  final String title;
  final String description;
  final String? posterUrl;
  final int seasonNumber;
  final int releaseDate;
  final bool active;

  Season({
    required this.id,
    required this.title,
    required this.description,
    this.posterUrl,
    required this.seasonNumber,
    required this.releaseDate,
    required this.active,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      seasonNumber: json['seasonNumber'],
      releaseDate: json['releaseDate'],
      active: json['active'],
    );
  }
}

class Episode {
  final int id;
  final int episodeNumber;
  final String title;
  final String description;
  final String videoUrl;
  final String posterUrl;
  final int runtime;
  final int releaseDate;
  final bool free;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.posterUrl,
    required this.runtime,
    required this.releaseDate,
    required this.free,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      episodeNumber: json['episodeNumber'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      posterUrl: json['posterUrl'],
      runtime: json['runtime'],
      releaseDate: json['releaseDate'],
      free: json['free'],
    );
  }
}

class Series {
  final int id;
  final String title;
  final String description;
  final double ratings;
  final int ratingCount;
  final num price;
  final List<String> genreList;
  final List<String> directorList;
  final List<String> castList;
  final List<String> posterUrlList;
  final String trailerURL;
  final String type;
  final String? ageRating;

  Series({
    required this.id,
    required this.title,
    required this.description,
    required this.ratings,
    required this.ratingCount,
    required this.price,
    required this.genreList,
    required this.directorList,
    required this.castList,
    required this.posterUrlList,
    required this.trailerURL,
    required this.type,
    this.ageRating,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ratings: (json['ratings'] as num).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      price: json['price'],
      genreList: List<String>.from(json['genreList']),
      directorList: List<String>.from(json['directorList']),
      castList: List<String>.from(json['castList']),
      posterUrlList: List<String>.from(json['posterUrlList']),
      trailerURL: json['trailerURL'],
      type: json['type'],
      ageRating: json['ageRating'],
    );
  }
}
