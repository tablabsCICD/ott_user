class RaiseTicketRequest {
  String? date;
  String? email;
  String? feedback;
  String? image;
  String? mobileNumber;
  int? tickedId;
  String? topic;
  int? userId;

  RaiseTicketRequest({
    this.date,
    this.email,
    this.feedback,
    this.image,
    this.mobileNumber,
    this.tickedId,
    this.topic,
    this.userId,
  });

  factory RaiseTicketRequest.fromJson(Map<String, dynamic> json) => RaiseTicketRequest(
    date: json["date"],
    email: json["email"],
    feedback: json["feedback"],
    image: json["image"],
    mobileNumber: json["mobileNumber"],
    tickedId: json["tickedId"],
    topic: json["topic"],
    userId: json["userId"],
  );

  Map<String, dynamic> toJson() => {
    "date": date,
    "email": email,
    "feedback": feedback,
    "image": image,
    "mobileNumber": mobileNumber,
    "tickedId": tickedId,
    "topic": topic,
    "userId": userId,
  };
}
