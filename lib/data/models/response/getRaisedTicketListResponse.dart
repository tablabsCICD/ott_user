
import '../user.dart';

class GetRaiseTicketListResponse {
  Data? data;
  String? message;
  int? status;

  GetRaiseTicketListResponse({
    this.data,
    this.message,
    this.status,
  });

  factory GetRaiseTicketListResponse.fromJson(Map<String, dynamic> json) => GetRaiseTicketListResponse(
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
    message: json["message"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "data": data?.toJson(),
    "message": message,
    "status": status,
  };
}

class Data {
  List<TicketRaised>? ticketRaised;

  Data({
    this.ticketRaised,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    ticketRaised: json["TicketRaised"] == null ? [] : List<TicketRaised>.from(json["TicketRaised"]!.map((x) => TicketRaised.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "TicketRaised": ticketRaised == null ? [] : List<dynamic>.from(ticketRaised!.map((x) => x.toJson())),
  };
}

class TicketRaised {
  int? tickedId;
  String? topic;
  String? mobileNumber;
  String? email;
  User? user;
  int? userId;
  int? date;
  String? feedback;
  String? image;

  TicketRaised({
    this.tickedId,
    this.topic,
    this.mobileNumber,
    this.email,
    this.user,
    this.userId,
    this.date,
    this.feedback,
    this.image,
  });

  factory TicketRaised.fromJson(Map<String, dynamic> json) => TicketRaised(
    tickedId: json["tickedId"],
    topic: json["topic"],
    mobileNumber: json["mobileNumber"],
    email: json["email"],
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    userId: json["userId"],
    date: json["date"],
    feedback: json["feedback"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "tickedId": tickedId,
    "topic": topic,
    "mobileNumber": mobileNumber,
    "email": email,
    "user": user?.toJson(),
    "userId": userId,
    "date": date,
    "feedback": feedback,
    "image": image,
  };
}

