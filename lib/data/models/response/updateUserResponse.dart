import 'package:ott/data/models/user.dart';

class UpdateUserResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  UpdateUserResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory UpdateUserResponse.fromJson(Map<String, dynamic> json) => UpdateUserResponse(
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
  User? user;

  Data({
    this.user,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    user: json["user"] == null ? null : User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
  };
}

