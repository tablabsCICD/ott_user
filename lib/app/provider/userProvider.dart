import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'package:image_picker/image_picker.dart'; // For web-specific file handling

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/data/models/response/errorResponse.dart';
import 'package:ott/data/models/response/getUserResponse.dart';
import 'package:ott/data/models/response/updateUserResponse.dart';

import '../../data/models/request/user_request.dart';
import '../../data/models/response/addUserResponse.dart';
import '../../data/models/user.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';
import 'baseProvider.dart';

class UserProvider extends BaseProvider {
  UserProvider() : super('Ideal') {}

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController officeBuildingController = TextEditingController();
  TextEditingController registrationDateController = TextEditingController();
  TextEditingController profileController = TextEditingController();
  TextEditingController pinCodeDateController = TextEditingController();
  TextEditingController refferedByController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  String? selectedGender;
  List<String> selectedLanguages = [];

  bool isEnbale = false;

  setValue() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    print("SEtData${user!.firstName}");
    firstNameController.text = user.firstName ?? "";
    lastNameController.text = user.lastName ?? "";
    mobileController.text = user.mobileNumber ?? "";
    emailController.text = user.emailId ?? "";
    dobController.text = user.dob ?? "";
    profileController.text = user.profilePhoto ?? "";
    notifyListeners();
  }

  checkValidation() {
    if (firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        mobileController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        dobController.text.isNotEmpty) {
      isEnbale = true;
    } else {
      isEnbale = false;
    }
    notifyListeners();
  }

  User userObject = User();

  User get userObj => userObject;

  // Create a new user
  Future<Map<String, dynamic>> createUser() async {
    String apiUrl = ApiConstant.registration;
    UserRequest userRequest = UserRequest();
    userRequest.admin = false;
    userRequest.age = '';
    userRequest.area = officeBuildingController.text;
    userRequest.city = cityController.text;
    userRequest.country = countryController.text;
    userRequest.deviceId = '';
    userRequest.deviceName = '';
    userRequest.deviceToken = '';
    userRequest.district = districtController.text;
    userRequest.dob = dobController.text;
    userRequest.emailId = emailController.text;
    userRequest.firstName = firstNameController.text;
    userRequest.gender = selectedGender;
    userRequest.joinDate = '';
    userRequest.mobileNumber = mobileController.text;
    userRequest.lastName = lastNameController.text;
    userRequest.locationId = 0;
    userRequest.officeBuilding = officeBuildingController.text;
    userRequest.osName = "Web";
    userRequest.password = passwordController.text;
    userRequest.pincode = "411017";
    userRequest.profilePhoto = profileController.text;
    userRequest.refferedBy = refferedByController.text;
    userRequest.taluka = cityController.text;
    userRequest.state = stateController.text;
    userRequest.languages = selectedLanguages;
    userRequest.verified = true;

    ApiHelper apiHelper = ApiHelper();

    try {
      var response =
          await apiHelper.postApiWithBody(apiUrl, userRequest.toJson());
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetUserResponse addUserResponse =
            GetUserResponse.fromJson(responseBody);
        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            userObject = addUserResponse.data!.user!;
            //log("before SEtData ${userObject.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setBool(
                SharedPreferencesConstant.isUserLoggedIn, true);
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(addUserResponse.data!.user));

            // log("after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            disposeData();
            notifyListeners();

            return {'success': true, 'message': 'User created successfully'};
          } else {
            debugPrint("Empty data: ${addUserResponse.message}");
            return {
              'success': false,
              'message': addUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
          return {
            'success': false,
            'message': addUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 500) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        ErrorResposne addUserResponse = ErrorResposne.fromJson(responseBody);
        return {'success': false, 'message': addUserResponse.message};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      } else {
        return {'success': false, 'message': 'Something went wrong!'};
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }

  // Update user data
  Future<Map<String, Object>> updateUser() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.editUserById;
    //log("API=====$apiUrl");
    ApiHelper apiHelper = ApiHelper();
    Map<String, dynamic> data = {
      "id": user!.id,
      "emailId": emailController.text,
      "firstName": firstNameController.text,
      "lastName": lastNameController.text,
      //"dob": dobController.text,
      "mobileNumber": user.mobileNumber, // mobileController.text,
      "profilePhoto": profileController.text,
      //"refferedBy": refferedByController.text,
    };
    //log("data=====$data");

    try {
      var response = await apiHelper.putApiWithBody(apiUrl, data);
      //log('Update User statusCode === ${response.statusCode}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        UpdateUserResponse updateUserResponse =
            UpdateUserResponse.fromJson(responseBody);
        //log('Update User response === ${updateUserResponse}');

        debugPrint("data: ${updateUserResponse.message}");
        if (updateUserResponse.success == true) {
          if (updateUserResponse.data != null) {
            userObject = updateUserResponse.data!.user!;
            print("before SEtData ${user.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(updateUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {
              'success': true,
              'message': updateUserResponse.message ?? ""
            };
          } else {
            debugPrint("Empty data: ${updateUserResponse.message}");
            return {
              'success': false,
              'message': updateUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${updateUserResponse.message}");
          return {
            'success': false,
            'message': updateUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 500) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while update user: $error'
      };
    }
  }

  // Update user basic details data
  Future<Map<String, Object>> updateUserDetails() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.editUserById;
    //log("API=====$apiUrl");
    ApiHelper apiHelper = ApiHelper();
    Map<String, dynamic> data = {
      "id": user!.id,
      "emailId": emailController.text,
      "firstName": firstNameController.text,
      "lastName": lastNameController.text,
      "dob": dobController.text,
      "mobileNumber": user.mobileNumber, // mobileController.text,
      "profilePhoto": profileController.text,
      "refferedBy": refferedByController.text,
    };
    //log("data=====$data");

    try {
      var response = await apiHelper.putApiWithBody(apiUrl, data);
      //log('Update User statusCode === ${response.statusCode}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        UpdateUserResponse updateUserResponse =
            UpdateUserResponse.fromJson(responseBody);
        //log('Update User response === ${updateUserResponse}');

        debugPrint("data: ${updateUserResponse.message}");
        if (updateUserResponse.success == true) {
          if (updateUserResponse.data != null) {
            userObject = updateUserResponse.data!.user!;
            print("before SEtData ${user.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(updateUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {
              'success': true,
              'message': updateUserResponse.message ?? ""
            };
          } else {
            debugPrint("Empty data: ${updateUserResponse.message}");
            return {
              'success': false,
              'message': updateUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${updateUserResponse.message}");
          return {
            'success': false,
            'message': updateUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 500) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while update user: $error'
      };
    }
  }

  // Update user Location data
  Future<Map<String, Object>> updateUserLocation() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.editUserById;
    log("API=====$apiUrl");
    ApiHelper apiHelper = ApiHelper();
    Map<String, dynamic> data = {
      "id": user!.id,
      "emailId": user.emailId,
      "mobileNumber": user.mobileNumber,
      "country": countryController.text,
      "state": stateController.text,
      "district": districtController.text,
      "taluka": cityController.text,
    };
    log("data=====$data");

    try {
      var response = await apiHelper.putApiWithBody(apiUrl, data);
      log('Update User statusCode === ${response.statusCode}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        UpdateUserResponse updateUserResponse =
            UpdateUserResponse.fromJson(responseBody);
        log('Update User response === ${updateUserResponse}');

        debugPrint("data: ${updateUserResponse.message}");
        if (updateUserResponse.success == true) {
          if (updateUserResponse.data != null) {
            userObject = updateUserResponse.data!.user!;
            print("before SEtData ${user.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(updateUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {
              'success': true,
              'message': updateUserResponse.message ?? ""
            };
          } else {
            debugPrint("Empty data: ${updateUserResponse.message}");
            return {
              'success': false,
              'message': updateUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${updateUserResponse.message}");
          return {
            'success': false,
            'message': updateUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 500) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while update user: $error'
      };
    }
  }

  // Update user data
  Future<Map<String, Object>> updateUserLang(List<String> langList) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.editUserById;

    ApiHelper apiHelper = ApiHelper();
    Map<String, dynamic> data = {
      "emailId": user!.emailId,
      "firstName": user.firstName,
      "id": user.id,
      "lastName": user.lastName,
      "mobileNumber": user.mobileNumber,
      "languages": langList
    };
    try {
      var response = await apiHelper.putApiWithBody(apiUrl, data);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        UpdateUserResponse updateUserResponse =
            UpdateUserResponse.fromJson(responseBody);

        debugPrint("data: ${updateUserResponse.message}");
        if (updateUserResponse.success == true) {
          if (updateUserResponse.data != null) {
            user = updateUserResponse.data!.user!;
            print("before SEtData ${user.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(updateUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {
              'success': true,
              'message': updateUserResponse.message ?? ""
            };
          } else {
            debugPrint("Empty data: ${updateUserResponse.message}");
            return {
              'success': false,
              'message': updateUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${updateUserResponse.message}");
          return {
            'success': false,
            'message': updateUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 500) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while update user: $error'
      };
    }
  }

//Login - send otp
  sendOTP(String mobile) async {
    String apiUrl = ApiConstant.sendOTP(mobile);

    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetUserResponse addUserResponse =
            GetUserResponse.fromJson(responseBody);

        //log("= data: ${addUserResponse.message}");

        if (addUserResponse.success == true) {
          //log('= $addUserResponse');
          return {'success': true, 'message': 'OTP sent'};
        } else {
          return {
            'success': false,
            'message': 'User not found',
          };
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 500 ||
          response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Error in response',
        };
      } else {
        return {
          'failure': true,
          'message': 'Something went wrong!',
        };
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } on io.SocketException {
      return {
        'success': false,
        'message':
            'No internet connection. Please check your network and try again.',
      };
    } catch (error) {
      log("Error: $error");
      return {'success': false, 'message': 'error: $error'};
    }
  }

//verify otp
  Future<Map<String, dynamic>> verifyOTP(String mobile, String otp) async {
    final apiUrl = ApiConstant.verifyOTP(mobile, otp);
    final apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApi(apiUrl);
      log('Verify OTP Response==== ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetUserResponse addUserResponse =
            GetUserResponse.fromJson(responseBody);

        debugPrint("data: ${addUserResponse.message}");
        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            userObject = addUserResponse.data!.user!;
            print("before SEtData ${userObject.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setBool(
                SharedPreferencesConstant.isUserLoggedIn, true);
            print(
                "check  SEtLogin ${await localSharePreferences.getBool(SharedPreferencesConstant.isUserLoggedIn)}");
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(addUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {'success': true, 'message': 'User logged in successfully'};
          } else {
            debugPrint("Empty data: ${addUserResponse.message}");
            return {
              'success': false,
              'message': addUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
          return {
            'success': false,
            'message': addUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 500 ||
          response.statusCode == 404) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while logging user: $error'
      };
    }
  }

  // Delete a user
  Future<void> deleteUser(int id) async {
    String apiUrl = ApiConstant.deleteUserById(id);
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.deleteApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse deleteUserResponse =
            AddUserResponse.fromJson(responseBody);
        if (deleteUserResponse.success == true) {
          notifyListeners();
        } else {
          debugPrint("Error: ${deleteUserResponse.message}");
        }
      } else {
        throw Exception(
            'Failed to delete user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      throw Exception('An error occurred while delete user.');
    }
  }

  Future<void> getUserById(int id) async {
    String apiUrl = ApiConstant.getUserById(id);
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetUserResponse addUserResponse =
            GetUserResponse.fromJson(responseBody);
        if (addUserResponse.success == true) {
          if (addUserResponse.data != null &&
              addUserResponse.data!.user != null) {
            userObject = addUserResponse.data!.user!;
            notifyListeners();
          } else {
            debugPrint("empty data: ${addUserResponse.message}");
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
        }
      } else {
        throw Exception(
            'Failed to delete user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      throw Exception('An error occurred while delete user.');
    }
  }

  setDate(DateTime pickedDate) {
    dobController.text = pickedDate.toLocal().toString().split(' ')[0];
    notifyListeners();
  }

// login email
  login(String email, String password) async {
    String apiUrl = ApiConstant.login;
    Map<String, dynamic> data = {"emailId": email, "password": password};
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(apiUrl, data);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetUserResponse addUserResponse =
            GetUserResponse.fromJson(responseBody);

        debugPrint("data: ${addUserResponse.message}");
        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            userObject = addUserResponse.data!.user!;
            print("before SEtData ${userObject.firstName}");
            LocalSharePreferences localSharePreferences =
                LocalSharePreferences();
            localSharePreferences.setBool(
                SharedPreferencesConstant.isUserLoggedIn, true);
            print(
                "check  SEtLogin ${await localSharePreferences.getBool(SharedPreferencesConstant.isUserLoggedIn)}");
            localSharePreferences.setString(
                SharedPreferencesConstant.currentUser,
                jsonEncode(addUserResponse.data!.user));
            print(
                "after SEtData ${await localSharePreferences.getString(SharedPreferencesConstant.currentUser)}");
            notifyListeners();
            return {'success': true, 'message': 'User logged in successfully'};
          } else {
            debugPrint("Empty data: ${addUserResponse.message}");
            return {
              'success': false,
              'message': addUserResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
          return {
            'success': false,
            'message': addUserResponse.message ?? 'Error in response'
          };
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 500 ||
          response.statusCode == 404) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AddUserResponse addUserResponse =
            AddUserResponse.fromJson(responseBody);
        debugPrint("Error: ${addUserResponse.message}");
        return {
          'success': false,
          'message': addUserResponse.message ?? 'Error in response'
        };
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while logging user: $error'
      };
    }
  }

  io.File? _imageFile; // For mobile platforms
  html.File? _webFile; // For web platform
  String? _uploadedImageUrl;
  bool _isUploading = false;

  // Getters
  io.File? get imageFile => _imageFile;
  html.File? get webFile => _webFile;
  String? get uploadedImageUrl => _uploadedImageUrl;
  bool get isUploading => _isUploading;

  // Pick Image
  Future<void> pickImage() async {
    try {
      if (kIsWeb) {
        log('Web file picker');
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
            _webFile = uploadInput.files!.first;
            await uploadImage();
            notifyListeners();
          }
        });
      } else {
        log('Mobile/desktop file picker');
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          _imageFile = io.File(pickedFile.path);
          await uploadImage();
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error picking image: $e');
    }
  }

  // Upload Image
  Future<void> uploadImage() async {
    log('Uploading image...');
    final url = Uri.parse(ApiConstant.uploadImg);
    _isUploading = true;
    notifyListeners();

    try {
      http.MultipartRequest request = http.MultipartRequest('POST', url);

      if (kIsWeb && _webFile != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(_webFile!);
        await reader.onLoad.first;
        final byteData = reader.result as List<int>;
        final multipartFile = http.MultipartFile.fromBytes(
          'profilePicture',
          byteData,
          filename: _webFile!.name,
        );
        request.files.add(multipartFile);
      } else if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          _imageFile!.path,
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        _uploadedImageUrl = jsonDecode(responseBody);
        profileController.text = _uploadedImageUrl!;
      } else {
        log('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error uploading image: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void disposeData() {
    firstNameController.clear();
    lastNameController.clear();
    cityController.clear();
    countryController.clear();
    confirmPasswordController.clear();
    districtController.clear();
    dobController.clear();
    emailController.clear();
    mobileController.clear(); // double-check spelling here
    officeBuildingController.clear();
    profileController.clear();
    profileController.clear();
    pinCodeDateController.clear();
    refferedByController.clear();
    roleController.clear();
    stateController.clear();
  }
}
