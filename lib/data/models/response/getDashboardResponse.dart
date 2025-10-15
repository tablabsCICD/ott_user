import 'package:ott/data/models/content.dart';

class GetDashboardResponse {
  List<Datum>? data;
  bool? success;
  String? message;
  int? statusCode;

  GetDashboardResponse({
    this.data,
    this.success,
    this.message,
    this.statusCode,
  });

  factory GetDashboardResponse.fromJson(Map<String, dynamic> json) => GetDashboardResponse(
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    success: json["success"],
    message: json["message"],
    statusCode: json["statusCode"],
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "success": success,
    "message": message,
    "statusCode": statusCode,
  };
}

class Datum {
  List<Content>? movies;
  String? language;
  String? category;

  Datum({
    this.movies,
    this.language,
    this.category,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    movies: json["movies"] == null ? [] : List<Content>.from(json["movies"]!.map((x) => Content.fromJson(x))),
    language: json["language"],
    category: json["category"],
  );

  Map<String, dynamic> toJson() => {
    "movies": movies == null ? [] : List<dynamic>.from(movies!.map((x) => x.toJson())),
    "language": language,
    "category": category,
  };
}

