
import 'package:ott/data/models/content.dart';

class GetAllVideoResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  GetAllVideoResponse({this.message, this.data, this.statusCode, this.success});

  GetAllVideoResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    statusCode = json['statusCode'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['statusCode'] = this.statusCode;
    data['success'] = this.success;
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
        contentList!.add(new Content.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.contentList != null) {
      data['ContentList'] = this.contentList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}