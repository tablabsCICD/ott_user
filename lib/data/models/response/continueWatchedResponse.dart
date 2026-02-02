import '../content.dart';

class ContinueWatchedResponse {
  List<Content>? data;
  String? message;
  int? statusCode;
  bool? isSuccess;

  ContinueWatchedResponse({
    this.data,
    this.message,
    this.statusCode,
    this.isSuccess,
  });

  factory ContinueWatchedResponse.fromJson(Map<String, dynamic> json) => ContinueWatchedResponse(
    data: json["data"] == null ? [] : List<Content>.from(json["data"]!.map((x) => Content.fromJson(x))),
    message: json["message"],
    statusCode: json["statusCode"],
    isSuccess: json["isSuccess"],
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<Content>.from(data!.map((x) => x.toJson())),
    "message": message,
    "statusCode": statusCode,
    "isSuccess": isSuccess,
  };
}