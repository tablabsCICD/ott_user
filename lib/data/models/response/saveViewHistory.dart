// To parse this JSON data, do
//
//     final saveViewHistory = saveViewHistoryFromJson(jsonString);



import '../content.dart';

class SaveViewHistory {
  String? message;
  Data? data;
  int? statusCode;
  dynamic total;
  bool? success;

  SaveViewHistory({
    this.message,
    this.data,
    this.statusCode,
    this.total,
    this.success,
  });

  factory SaveViewHistory.fromJson(Map<String, dynamic> json) => SaveViewHistory(
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
    statusCode: json["statusCode"],
    total: json["total"],
    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data?.toJson(),
    "statusCode": statusCode,
    "total": total,
    "success": success,
  };
}

class Data {
  ViewHistory? viewHistory;

  Data({
    this.viewHistory,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    viewHistory: json["viewHistory"] == null ? null : ViewHistory.fromJson(json["viewHistory"]),
  );

  Map<String, dynamic> toJson() => {
    "viewHistory": viewHistory?.toJson(),
  };
}

class ViewHistory {
  int? id;
  int? userId;
  Content? content;
  int? viewDate;
  String? resumeTime;
  String? selectedLanguage;

  ViewHistory({
    this.id,
    this.userId,
    this.content,
    this.viewDate,
    this.resumeTime,
    this.selectedLanguage,
  });

  factory ViewHistory.fromJson(Map<String, dynamic> json) => ViewHistory(
    id: json["id"],
    userId: json["userId"],
    content: json["content"] == null ? null : Content.fromJson(json["content"]),
    viewDate: json["viewDate"],
    resumeTime: json["resumeTime"],
    selectedLanguage: json["selectedLanguage"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "content": content?.toJson(),
    "viewDate": viewDate,
    "resumeTime": resumeTime,
    "selectedLanguage": selectedLanguage,
  };
}

