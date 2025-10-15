
import 'package:ott/data/models/content.dart';

class DashboardResponse {
  String? message;
  List<DashboardData>? data;
  int? statusCode;
  bool? success;

  DashboardResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) => DashboardResponse(
    message: json["message"],
    data: json["data"] == null ? [] : List<DashboardData>.from(json["data"]!.map((x) => DashboardData.fromJson(x))),
    statusCode: json["statusCode"],
    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "statusCode": statusCode,
    "success": success,
  };
}

class DashboardData {

  List<Content?>? movies;
  String? language;
  String? category;

  DashboardData({
  this.movies,
  this.language,
  this.category,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
  movies: json["movies"] == null ? [] : List<Content?>.from(json["movies"]!.map((x) => x == null ? null : Content.fromJson(x))),
  language: json["language"],
  category: json["category"],
  );

  Map<String, dynamic> toJson() => {
  "movies": movies == null ? [] : List<dynamic>.from(movies!.map((x) => x?.toJson())),
  "language": language,
  "category": category,
  };
  }
