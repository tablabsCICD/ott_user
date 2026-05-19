// To parse this JSON data, do
//
//     final contentResponse = contentResponseFromJson(jsonString);

import 'package:ott/data/models/content.dart';

class GetContentResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  GetContentResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory GetContentResponse.fromJson(Map<String, dynamic> json) =>
      GetContentResponse(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        statusCode: json["statusCode"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "data": data?.toJson(),
        "statusCode": statusCode,
        "success": success,
      };
}

class Data {
  Content? contentList;

  Data({
    this.contentList,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        contentList: json["ContentList"] == null
            ? null
            : Content.fromJson(json["ContentList"]),
      );

  Map<String, dynamic> toJson() => {
        "ContentList": contentList?.toJson(),
      };
}
