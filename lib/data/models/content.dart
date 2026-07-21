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
  String? teaserUrl;
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

  int? watchedSeconds;
  int? watchedPercentage;

  int? seasonId;
  int? episodeId;

  Content({
    this.id,
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
    this.teaserUrl,
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
    this.isRental,
    this.watchedSeconds,
    this.watchedPercentage,
    this.seasonId,
    this.episodeId,
  });

  String? get teaserOrTrailerUrl {
    final teaser = teaserUrl;
    if (teaser != null && teaser.trim().isNotEmpty) return teaser;

    final trailer = trailerUrl;
    if (trailer != null && trailer.trim().isNotEmpty) return trailer;
    return null;
  }

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: _asInt(json['id']),
    title: json['title'],
    description: json['description'],
    runtime: _asInt(json['runtime']),
    releaseDate: json['releaseDate'],

    ratings: _asDouble(json['ratings']),
    price: _asDouble(json['price']),
    totalRevenue: _asDouble(json['totalRevenue']),

    languageList: (json['languageList'] as List?)
        ?.map((e) => e is Map
            ? LanguageList.fromJson(Map<String, dynamic>.from(e))
            : LanguageList(language: e.toString()))
        .toList(),

    castList: (json['castList'] as List?)
        ?.map((e) => e.toString())
        .toList(),

    genreList: (json['genreList'] as List?)
        ?.map((e) => e.toString())
        .toList(),

    directorList: (json['directorList'] as List?)
        ?.map((e) => e.toString())
        .toList(),

    views: _asInt(json['views']),
    ageRating: json['ageRating'],

    posterUrlList: (json['posterUrlList'] as List?)
        ?.map((e) => e.toString())
        .toList(),

    teaserUrl: _firstDirectTrailerValue(json, const [
      'teaserUrl',
      'teaserFile',
      'teaserFileUrl',
      'teaser_url',
      'teaser_file',
      'teasurUrl',
      'teasurFile',
      'teasurFileUrl',
      'teasur_url',
      'teasur_file',
    ]),
    trailerUrl: _firstDirectTrailerValue(json, const [
      'trailerUrl',
      'trailerFile',
      'trailerFileUrl',
      'trailer_url',
      'trailer_file',
      'trailer_file_url',
    ]),
    contentUrl: _contentUrlFromJson(json),
    approvalStatus: json['approvalStatus'],
    type: json['type'],
    sensorCertificate: json['sensorCertificate'],
    isFeatured: json['isFeatured'] == true,

    availability: json['availability'] != null
        ? Availability.fromJson(json['availability'])
        : null,

    audioFormatList: (json['audioFormatList'] as List?)
        ?.map((e) => e.toString())
        .toList(),

    subtitleLanguageList: (json['subtitleLanguageList'] as List?)
        ?.map((e) => e.toString())
        .toList(),


    isDownloadable: json['isDownloadable'] == true,

    uploadDateTime: _asInt(json['uploadDateTime']),
    approvedDateTime: _asInt(json['approvedDateTime']),

    mediaHouseName: json['mediaHouseName'],
    mediaHouseId: _asInt(json['mediaHouseId']),

    ratingCount: _asInt(json['ratingCount']),
    rentlDuration: json['rentlDuration'],
    isRental: json['isRental'] == true,

    watchedSeconds: _asInt(json['watchedSeconds']),
    watchedPercentage: _asInt(json['watchedPercentage']),

    seasonId: _asInt(json['seasonId']),
    episodeId: _asInt(json['episodeId']),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "runtime": runtime,
    "releaseDate": releaseDate,
    "ratings": ratings,
    "price": price,
    "languageList":
    languageList?.map((x) => x.toJson()).toList() ?? [],
    "castList": castList ?? [],
    "genreList": genreList ?? [],
    "directorList": directorList ?? [],
    "views": views,
    "totalRevenue": totalRevenue,
    "ageRating": ageRating,
    "posterUrlList": posterUrlList ?? [],
    "teaserUrl": teaserUrl,
    "trailerUrl": trailerUrl,
    "contentUrl": contentUrl,
    "approvalStatus": approvalStatus,
    "type": type,
    "sensorCertificate": sensorCertificate,
    "isFeatured": isFeatured,
    "availability": availability?.toJson(),
    "audioFormatList": audioFormatList ?? [],
    "subtitleLanguageList": subtitleLanguageList ?? [],
    "isDownloadable": isDownloadable,
    "uploadDateTime": uploadDateTime,
    "approvedDateTime": approvedDateTime,
    "mediaHouseName": mediaHouseName,
    "mediaHouseId": mediaHouseId,
    "ratingCount": ratingCount,
    "rentlDuration": rentlDuration,
    "isRental": isRental,
    "watchedSeconds": watchedSeconds,
    "watchedPercentage": watchedPercentage,
    "seasonId": seasonId,
    "episodeId": episodeId,
  };
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String? _firstStringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _stringFromField(json[key]);
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String? _firstDirectTrailerValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _directTrailerStringFromField(json[key]);
    if (value != null) return value;
  }
  return null;
}

String? _contentUrlFromJson(Map<String, dynamic> json) {
  final directUrl = _firstStringValue(json, const [
    'contentUrl',
    'contentFile',
    'contentFileUrl',
    'content_url',
    'content_file',
    'content_file_url',
    'videoUrl',
    'videoFile',
    'videoFileUrl',
    'video_url',
    'video_file',
    'video_file_url',
    'movieUrl',
    'movieFile',
    'movieFileUrl',
    'movie_url',
    'movie_file',
    'movie_file_url',
    'fileUrl',
    'file_url',
    'url',
  ]);
  if (directUrl != null && directUrl.isNotEmpty) return directUrl;

  final languages = json['languageList'];
  if (languages is List) {
    for (final item in languages) {
      if (item is Map) {
        final languageUrl = _stringFromField(item['fileUrl']) ??
            _stringFromField(item['file_url']) ??
            _stringFromField(item['url']);
        if (languageUrl != null && languageUrl.isNotEmpty) return languageUrl;
      }
    }
  }

  return null;
}

String? _stringFromField(dynamic field) {
  if (field == null) return null;
  if (field is Map) {
    for (final key in const ['url', 'fileUrl', 'file_url', 'path']) {
      final value = field[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  final value = field.toString().trim();
  return value.isEmpty ? null : value;
}

String? _directTrailerStringFromField(dynamic field) {
  if (field == null) return null;
  if (field is Map) {
    for (final key in const ['url', 'fileUrl', 'file_url', 'path']) {
      final rawValue = field[key]?.toString();
      if (rawValue != null && rawValue.trim().isNotEmpty) return rawValue;
    }
    return null;
  }

  final value = field.toString();
  return value.trim().isEmpty ? null : value;
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
