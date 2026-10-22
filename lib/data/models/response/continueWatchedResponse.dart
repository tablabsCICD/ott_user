import '../content.dart';

class ContinueWatchedResponse {
  List<Content>? data;
  String? message;
  int? statusCode;
  bool? isSuccess;
  bool? success;

  ContinueWatchedResponse({
    this.data,
    this.message,
    this.statusCode,
    this.isSuccess,
    this.success,
  });

  factory ContinueWatchedResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json["data"];
    final List<Content> contentList = [];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          if (item['movie'] is Map<String, dynamic>) {
            final c = Content.fromJson(item['movie'] as Map<String, dynamic>);
            c.watchedPercentage ??= _asInt(item['watchedPercentage'] ??
                item['contentPercentage'] ??
                item['watched_percentage']);
            c.watchedSeconds ??=
                _asInt(item['watchedSeconds'] ?? item['watched_seconds']);
            c.seasonId ??= _asInt(item['seasonId']);
            c.episodeId ??= _asInt(item['episodeId']);
            contentList.add(c);
          } else if (item['content'] is Map<String, dynamic>) {
            final c = Content.fromJson(item['content'] as Map<String, dynamic>);
            c.watchedPercentage ??= _asInt(item['watchedPercentage'] ??
                item['contentPercentage'] ??
                item['watched_percentage']);
            c.watchedSeconds ??=
                _asInt(item['watchedSeconds'] ?? item['watched_seconds']);
            c.seasonId ??= _asInt(item['seasonId']);
            c.episodeId ??= _asInt(item['episodeId']);
            contentList.add(c);
          } else {
            contentList.add(Content.fromJson(item));
          }
        }
      }
    }

    final bool isSuccessVal = json["isSuccess"] == true ||
        json["success"] == true ||
        json["statusCode"] == 200;

    return ContinueWatchedResponse(
      data: contentList,
      message: json["message"]?.toString(),
      statusCode: json["statusCode"] is int
          ? json["statusCode"]
          : int.tryParse(json["statusCode"]?.toString() ?? ''),
      isSuccess: isSuccessVal,
      success: isSuccessVal,
    );
  }

  Map<String, dynamic> toJson() => {
        "data": data == null ? [] : List<Content>.from(data!.map((x) => x.toJson())),
        "message": message,
        "statusCode": statusCode,
        "isSuccess": isSuccess,
        "success": success,
      };
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}