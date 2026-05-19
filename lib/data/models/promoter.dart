class PromoterModel {
  int? id;
  String? firstName;
  String? lastName;
  String? mobileNumber;
  String? emailId;
  String? profilePhoto;
  String? password;
  String? otp;
  String? age;
  String? dob;
  String? refferedBy;
  String? joinDate;
  String? country;
  String? state;
  String? district;
  String? taluka;
  String? gender;
  String? insentives;
  String? targetResion;
  String? status;
  String? addres;
  String? level;

  PromoterModel(
      {this.id,
      this.firstName,
      this.lastName,
      this.mobileNumber,
      this.emailId,
      this.profilePhoto,
      this.password,
      this.otp,
      this.age,
      this.dob,
      this.refferedBy,
      this.joinDate,
      this.country,
      this.state,
      this.district,
      this.taluka,
      this.gender,
      this.insentives,
      this.targetResion,
      this.status,
      this.addres,
      this.level});

  PromoterModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    mobileNumber = json['mobileNumber'];
    emailId = json['emailId'];
    profilePhoto = json['profilePhoto'];
    password = json['password'];
    otp = json['otp'];
    age = json['age'];
    dob = json['dob'];
    refferedBy = json['refferedBy'];
    joinDate = json['joinDate'];
    country = json['country'];
    state = json['state'];
    district = json['district'];
    taluka = json['taluka'];
    gender = json['gender'];
    insentives = json['insentives'];
    targetResion = json['targetResion'];
    status = json['status'];
    addres = json['addres'];
    level = json['level'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['mobileNumber'] = mobileNumber;
    data['emailId'] = emailId;
    data['profilePhoto'] = profilePhoto;
    data['password'] = password;
    data['otp'] = otp;
    data['age'] = age;
    data['dob'] = dob;
    data['refferedBy'] = refferedBy;
    data['joinDate'] = joinDate;
    data['country'] = country;
    data['state'] = state;
    data['district'] = district;
    data['taluka'] = taluka;
    data['gender'] = gender;
    data['insentives'] = insentives;
    data['targetResion'] = targetResion;
    data['status'] = status;
    data['addres'] = addres;
    data['level'] = level;
    return data;
  }
}
