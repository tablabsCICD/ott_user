import '../user.dart';

class GetUserResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  GetUserResponse({this.message, this.data, this.statusCode, this.success});

  GetUserResponse.fromJson(Map<String, dynamic> json) {
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
  User? user;
  String? sessionId;
  String? tokenType;
  String? token;
  ActiveDevice? activeDevice;

  Data({
    this.user,
    this.sessionId,
    this.tokenType,
    this.token,
    this.activeDevice,
  });

  Data.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId']?.toString();
    tokenType = json['tokenType']?.toString();
    token = json['token']?.toString();
    activeDevice = json['activeDevice'] is Map<String, dynamic>
        ? ActiveDevice.fromJson(json['activeDevice'])
        : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionId'] = sessionId;
    data['tokenType'] = tokenType;
    data['token'] = token;
    if (activeDevice != null) {
      data['activeDevice'] = activeDevice!.toJson();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class ActiveDevice {
  int? id;
  String? deviceId;
  String? deviceName;
  String? deviceType;
  String? sessionId;
  dynamic loginTime;
  dynamic lastAccessTime;
  String? appVersion;

  ActiveDevice({
    this.id,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.sessionId,
    this.loginTime,
    this.lastAccessTime,
    this.appVersion,
  });

  ActiveDevice.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    deviceId = json['deviceId']?.toString();
    deviceName = json['deviceName']?.toString();
    deviceType = json['deviceType']?.toString();
    sessionId = json['sessionId']?.toString();
    loginTime = json['loginTime'];
    lastAccessTime = json['lastAccessTime'];
    appVersion = json['appVersion']?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'sessionId': sessionId,
        'loginTime': loginTime,
        'lastAccessTime': lastAccessTime,
        'appVersion': appVersion,
      };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
