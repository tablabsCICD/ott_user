class Location {
  int? id;
  String? country;
  String? state;
  String? district;
  String? taluka;
  String? city;
  String? area;
  String? pincode;
  String? officeBuilding;

  Location({
    this.id,
    this.country,
    this.state,
    this.district,
    this.taluka,
    this.city,
    this.area,
    this.pincode,
    this.officeBuilding,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json["id"],
    country: json["country"],
    state: json["state"],
    district: json["district"],
    taluka: json["taluka"],
    city: json["city"],
    area: json["area"],
    pincode: json["pincode"],
    officeBuilding: json["officeBuilding"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "country": country,
    "state": state,
    "district": district,
    "taluka": taluka,
    "city": city,
    "area": area,
    "pincode": pincode,
    "officeBuilding": officeBuilding,
  };
}
