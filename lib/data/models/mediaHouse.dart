
// import 'package:ott/data/models/location.dart';
// import 'package:ott/data/models/user.dart';

// class MediaHouse {
//   int? id;
//   String? mediaHouseName;
//   String? address;
//   String? contactNumber;
//   String? email;
//   String? registrationCertificate;
//   String? gstCertificates;
//   String? adharCard;
//   String? shopAct;
//   String? panCard;
//   int? createdDate;
//   int? updatedDate;
//   String? profileImage;
//   String? otp;
//   String? password;
//   String? status;
//   String? joinDate;
//   String? logo;
//   String? totalReveneu;
//   String? postCount;
//   String? discription;
//   User? user;
//   Location? location;
//   String? totalViews;

//   MediaHouse(
//       {this.id,
//         this.mediaHouseName,
//         this.address,
//         this.contactNumber,
//         this.email,
//         this.registrationCertificate,
//         this.gstCertificates,
//         this.adharCard,
//         this.shopAct,
//         this.panCard,
//         this.createdDate,
//         this.updatedDate,
//         this.profileImage,
//         this.otp,
//         this.password,
//         this.status,
//         this.joinDate,
//         this.logo,
//         this.totalReveneu,
//         this.postCount,
//         this.discription,
//         this.user,
//         this.location,
//         this.totalViews});

//   MediaHouse.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     mediaHouseName = json['mediaHouseName']??'';
//     address = json['address']??'';
//     contactNumber = json['contactNumber']??'';
//     email = json['email']??'';
//     registrationCertificate = json['registrationCertificate']??'';
//     gstCertificates = json['gstCertificates']??'';
//     adharCard = json['adharCard']??'';
//     shopAct = json['shopAct']??'';
//     panCard = json['panCard']??'';
//     createdDate = json['createdDate'];
//     updatedDate = json['updatedDate'];
//     profileImage = json['profileImage']??'';
//     otp = json['otp']??'';
//     password = json['password']??'';
//     status = json['status']??'';
//     joinDate = json['joinDate']??'';
//     logo = json['logo']??'';
//     totalReveneu = json['totalReveneu']??'';
//     postCount = json['postCount']??'';
//     discription = json['discription']??'';
//     user = json['user'] != null ? new User.fromJson(json['user']) : null;
//     location = json['location'] != null
//         ? new Location.fromJson(json['location'])
//         : null;
//     totalViews = json['totalViews']??'';
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['mediaHouseName'] = this.mediaHouseName;
//     data['address'] = this.address;
//     data['contactNumber'] = this.contactNumber;
//     data['email'] = this.email;
//     data['registrationCertificate'] = this.registrationCertificate;
//     data['gstCertificates'] = this.gstCertificates;
//     data['adharCard'] = this.adharCard;
//     data['shopAct'] = this.shopAct;
//     data['panCard'] = this.panCard;
//     data['createdDate'] = this.createdDate;
//     data['updatedDate'] = this.updatedDate;
//     data['profileImage'] = this.profileImage;
//     data['otp'] = this.otp;
//     data['password'] = this.password;
//     data['status'] = this.status;
//     data['joinDate'] = this.joinDate;
//     data['logo'] = this.logo;
//     data['totalReveneu'] = this.totalReveneu;
//     data['postCount'] = this.postCount;
//     data['discription'] = this.discription;
//     if (this.user != null) {
//       data['user'] = this.user!.toJson();
//     }
//     if (this.location != null) {
//       data['location'] = this.location!.toJson();
//     }
//     data['totalViews'] = this.totalViews;
//     return data;
//   }
// }