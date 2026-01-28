
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
  List<Content>? movies;
  Pagination? pagination;
  String? language;
  String? category;

  bool isRowLoading = false;

  bool get hasMore => pagination?.hasNext ?? false;
  int get currentPage => pagination?.page ?? 0;

  DashboardData({
    this.movies,
    this.pagination,
    this.language,
    this.category,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    movies: json["movies"] == null
        ? []
        : List<Content>.from(
        json["movies"]!.map((x) => Content.fromJson(x))),
    pagination: json["pagination"] == null
        ? null
        : Pagination.fromJson(json["pagination"]),
    language: json["language"],
    category: json["category"],
  );

  Map<String, dynamic> toJson() => {
    "movies": movies == null
        ? []
        : List<dynamic>.from(movies!.map((x) => x.toJson())),
    "pagination": pagination?.toJson(),
    "language": language,
    "category": category,
  };
}


class Pagination {
  int? totalItems;
  int? size;
  int? totalPages;
  bool? hasNext;
  int? page;

  Pagination({
    this.totalItems,
    this.size,
    this.totalPages,
    this.hasNext,
    this.page,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    totalItems: json["totalItems"],
    size: json["size"],
    totalPages: json["totalPages"],
    hasNext: json["hasNext"],
    page: json["page"],
  );

  Map<String, dynamic> toJson() => {
    "totalItems": totalItems,
    "size": size,
    "totalPages": totalPages,
    "hasNext": hasNext,
    "page": page,
  };
}
