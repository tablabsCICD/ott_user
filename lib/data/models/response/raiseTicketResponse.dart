import 'getRaisedTicketListResponse.dart';

class RaiseTicketResponse {
  Data? data;
  String? message;
  int? status;

  RaiseTicketResponse({
    this.data,
    this.message,
    this.status,
  });

  factory RaiseTicketResponse.fromJson(Map<String, dynamic> json) =>
      RaiseTicketResponse(
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
  TicketRaised? ticketRaised;

  Data({
    this.ticketRaised,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        ticketRaised: json["TicketRaised"] == null
            ? null
            : TicketRaised.fromJson(json["TicketRaised"]),
      );

  Map<String, dynamic> toJson() => {
        "TicketRaised": ticketRaised?.toJson(),
      };
}
