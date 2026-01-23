
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['mobileNumber'] = this.mobileNumber;
    data['emailId'] = this.emailId;
    data['profilePhoto'] = this.profilePhoto;
    data['password'] = this.password;
    data['otp'] = this.otp;
    data['age'] = this.age;
    data['dob'] = this.dob;
    data['refferedBy'] = this.refferedBy;
    data['joinDate'] = this.joinDate;
    data['country'] = this.country;
    data['state'] = this.state;
    data['district'] = this.district;
    data['taluka'] = this.taluka;
    data['gender'] = this.gender;
    data['insentives'] = this.insentives;
    data['targetResion'] = this.targetResion;
    data['status'] = this.status;
    data['addres'] = this.addres;
    data['level'] = this.level;
    return data;
  }
}
