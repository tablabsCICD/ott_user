import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/request/raiseTicketRequest.dart';
import '../../data/models/response/getRaisedTicketListResponse.dart';
import '../../data/models/response/raiseTicketResponse.dart';

import '../../data/models/user.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class TicketProvider extends ChangeNotifier {
  List<TicketRaised> _ticketList = [];
  List<TicketRaised> get ticketList => _ticketList;

  TextEditingController topicController = TextEditingController();
  String? imgUrl = '';

  Future<Map<String, Object>> raiseTicket() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    DateTime now = DateTime.now().toUtc(); // Get current time in UTC
    String formattedDate = now.toIso8601String();
    String apiUrl = ApiConstant.raiseTicket;
    RaiseTicketRequest raiseTicketRequest = RaiseTicketRequest();
    raiseTicketRequest.userId = user!.id!;
    raiseTicketRequest.mobileNumber =
        user.mobileNumber; //client or admin mobile number
    raiseTicketRequest.email = user.emailId; //client or admin email
    raiseTicketRequest.image = imgUrl;
    raiseTicketRequest.date = formattedDate;
    raiseTicketRequest.feedback = '';
    raiseTicketRequest.tickedId = 0;
    raiseTicketRequest.topic = topicController.text;

    ApiHelper apiHelper = ApiHelper();

    try {
      var response =
          await apiHelper.postApiWithBody(apiUrl, raiseTicketRequest.toJson());
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        RaiseTicketResponse raiseTicketResponse =
            RaiseTicketResponse.fromJson(responseBody);
        if (raiseTicketResponse.data != null) {
          if (raiseTicketResponse.data?.ticketRaised != null) {
            _ticketList.add(raiseTicketResponse.data!.ticketRaised!);
            imgUrl = null;
            _uploadedImageUrl = null;
            topicController
                .clear(); // Use `clear()` instead of assigning an empty string for text controllers
            notifyListeners();
            return {
              'success': true,
              'message':
                  raiseTicketResponse.message ?? 'Ticket raised successfully'
            };
          } else {
            debugPrint("Empty data: ${raiseTicketResponse.message}");
            return {
              'success': false,
              'message': raiseTicketResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${raiseTicketResponse.message}");
          return {
            'success': false,
            'message': raiseTicketResponse.message ?? 'Error in response'
          };
        }
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    }
  }

  Future<Map<String, Object>> getRaisedTicketByUserId() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.getRaisedTicketByUserId(user!.id!);

    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetRaiseTicketListResponse getRaiseTicketListResponse =
            GetRaiseTicketListResponse.fromJson(responseBody);
        if (getRaiseTicketListResponse.data != null) {
          if (getRaiseTicketListResponse.data!.ticketRaised != null) {
            _ticketList.clear();
            _ticketList.addAll(getRaiseTicketListResponse.data!.ticketRaised!);
            notifyListeners();
            return {
              'success': true,
              'message': getRaiseTicketListResponse.message!
            };
          } else {
            debugPrint("Empty data: ${getRaiseTicketListResponse.message}");
            return {
              'success': false,
              'message':
                  getRaiseTicketListResponse.message ?? 'No data returned'
            };
          }
        } else {
          debugPrint("Error: ${getRaiseTicketListResponse.message}");
          return {
            'success': false,
            'message': getRaiseTicketListResponse.message ?? 'Error in response'
          };
        }
      } else {
        return {'failure': true, 'message': 'Something went wrong!'};
        // throw Exception('Failed to add user. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
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
    if (kIsWeb) {
      // Web file picker
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
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
      // Mobile/desktop file picker
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _imageFile = io.File(pickedFile.path);
        if (kIsWeb && _webFile != null) {
          await uploadImage();
        }
        notifyListeners();
      }
    }
  }

  // Upload Image
  Future<void> uploadImage() async {
    if ((!kIsWeb && _imageFile == null) || (kIsWeb && _webFile == null)) {
      return; // No file selected
    }

    final url = Uri.parse(ApiConstant.uploadImg);
    _isUploading = true;
    notifyListeners();

    try {
      if (kIsWeb && _webFile != null) {
        // Web upload logic
        final request = http.MultipartRequest('POST', url);
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
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          _uploadedImageUrl = jsonDecode(responseBody);
          imgUrl = _uploadedImageUrl!;
          notifyListeners();
        }
      } else if (!kIsWeb && _imageFile != null) {
        // Mobile/desktop upload logic
        final request = http.MultipartRequest('POST', url);
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          _imageFile!.path,
          //  contentType: MediaType('image', 'jpeg'),
        ));
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          _uploadedImageUrl = jsonDecode(responseBody);
          imgUrl = _uploadedImageUrl!;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
