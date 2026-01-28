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
  final num amount;
  final int releaseDate;
  final int? viewCount;
  final int contentId;
  final bool active;

  Season({
    required this.id,
    required this.title,
    required this.description,
    this.posterUrl,
    required this.seasonNumber,
    required this.amount,
    required this.releaseDate,
    this.viewCount,
    required this.contentId,
    required this.active,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      seasonNumber: json['seasonNumber'],
      amount: json['amount'],
      releaseDate: json['releaseDate'],
      viewCount: json['viewCount'],
      contentId: json['contentId'],
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
  final int seasonId;
  final num amount;
  final int? viewCount;
  final String partName;
  final bool free;
  final bool active;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.posterUrl,
    required this.runtime,
    required this.releaseDate,
    required this.seasonId,
    required this.amount,
    this.viewCount,
    required this.partName,
    required this.free,
    required this.active,
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
      seasonId: json['seasonId'],
      amount: json['amount'],
      viewCount: json['viewCount'],
      partName: json['partName'],
      free: json['free'],
      active: json['active'],
    );
  }
}

class Series {
  final int id;
  final String title;
  final String description;
  final int runtime;
  final String releaseDate;
  final double ratings;
  final int ratingCount;
  final num price;

  final List<LanguageItem> languageList;
  final List<String> genreList;
  final List<String> directorList;
  final List<String> castList;
  final List<String> posterUrlList;

  final int views;
  final num totalRevenue;
  final String? ageRating;

  final String trailerURL;
  final String? contentURL;
  final String approvalStatus;
  final String type;
  final String sensorCertificate;

  final Availability availability;
  final List<String> audioFormatList;
  final List<String> subtitleLanguageList;

  final bool isDownloadable;
  final bool isFeatured;

  final int approvedDateTime;
  final int uploadDateTime;

  final String? reason;
  final String rentlDuration;

  final bool active;

  Series({
    required this.id,
    required this.title,
    required this.description,
    required this.runtime,
    required this.releaseDate,
    required this.ratings,
    required this.ratingCount,
    required this.price,
    required this.languageList,
    required this.genreList,
    required this.directorList,
    required this.castList,
    required this.posterUrlList,
    required this.views,
    required this.totalRevenue,
    this.ageRating,
    required this.trailerURL,
    this.contentURL,
    required this.approvalStatus,
    required this.type,
    required this.sensorCertificate,
    required this.availability,
    required this.audioFormatList,
    required this.subtitleLanguageList,
    required this.isDownloadable,
    required this.isFeatured,
    required this.approvedDateTime,
    required this.uploadDateTime,
    this.reason,
    required this.rentlDuration,
    required this.active,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      runtime: json['runtime'],
      releaseDate: json['releaseDate'],
      ratings: (json['ratings'] as num).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      price: json['price'],
      languageList: (json['languageList'] as List)
          .map((e) => LanguageItem.fromJson(e))
          .toList(),
      genreList: List<String>.from(json['genreList']),
      directorList: List<String>.from(json['directorList']),
      castList: List<String>.from(json['castList']),
      posterUrlList: List<String>.from(json['posterUrlList']),
      views: json['views'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      ageRating: json['ageRating'],
      trailerURL: json['trailerURL'],
      contentURL: json['contentURL'],
      approvalStatus: json['approvalStatus'],
      type: json['type'],
      sensorCertificate: json['sensorCertificate'],
      availability: Availability.fromJson(json['availability']),
      audioFormatList: List<String>.from(json['audioFormatList']),
      subtitleLanguageList: List<String>.from(json['subtitleLanguageList']),
      isDownloadable: json['isDownloadable'],
      isFeatured: json['isFeatured'],
      approvedDateTime: json['approvedDateTime'],
      uploadDateTime: json['uploadDateTime'],
      reason: json['reason'],
      rentlDuration: json['rentlDuration'],
      active: json['active'],
    );
  }
}

class LanguageItem {
  final String language;
  final String fileUrl;

  LanguageItem({
    required this.language,
    required this.fileUrl,
  });

  factory LanguageItem.fromJson(Map<String, dynamic> json) {
    return LanguageItem(
      language: json['language'],
      fileUrl: json['fileUrl'],
    );
  }
}

class Availability {
  final List<String> regions;
  final List<String> platforms;

  Availability({
    required this.regions,
    required this.platforms,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      regions: List<String>.from(json['regions']),
      platforms: List<String>.from(json['platforms']),
    );
  }
}
