import 'package:ott/data/models/content.dart';

class GetAllVideoResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  GetAllVideoResponse({this.message, this.data, this.statusCode, this.success});

  GetAllVideoResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    statusCode = json['statusCode'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['statusCode'] = statusCode;
    data['success'] = success;
    return data;
  }
}

class Data {
  List<Content>? contentList;

  Data({this.contentList});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['ContentList'] != null) {
      contentList = <Content>[];
      json['ContentList'].forEach((v) {
        contentList!.add(Content.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (contentList != null) {
      data['ContentList'] = contentList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
