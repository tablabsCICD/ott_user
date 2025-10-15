class AllLangResponse {
  String? message;
  Data? data;
  int? statusCode;
  bool? success;

  AllLangResponse({
    this.message,
    this.data,
    this.statusCode,
    this.success,
  });

  factory AllLangResponse.fromJson(Map<String, dynamic> json) => AllLangResponse(
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
  List<Language>? languages;

  Data({
    this.languages,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    languages: json["languages"] == null ? [] : List<Language>.from(json["languages"]!.map((x) => Language.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "languages": languages == null ? [] : List<dynamic>.from(languages!.map((x) => x.toJson())),
  };
}

class Language {
  int? languagesId;
  String? name;

  Language({
    this.languagesId,
    this.name,
  });

  factory Language.fromJson(Map<String, dynamic> json) => Language(
    languagesId: json["languagesId"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "languagesId": languagesId,
    "name": name,
  };
}
