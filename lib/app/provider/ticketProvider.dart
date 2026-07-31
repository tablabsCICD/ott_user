import 'dart:convert';
import 'dart:developer';

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
import 'baseProvider.dart';

class TicketProvider extends BaseProvider {
  final List<TicketRaised> _ticketList = [];
  List<TicketRaised> get ticketList => _ticketList;

  TextEditingController topicController = TextEditingController();
  String? imgUrl = '';
  bool _isLoadingTickets = false;
  bool _isSubmitting = false;
  int? _deletingTicketId;

  bool get isLoadingTickets => _isLoadingTickets;
  bool get isSubmitting => _isSubmitting;
  int? get deletingTicketId => _deletingTicketId;

  Future<Map<String, Object>> raiseTicket() async {
    final topic = topicController.text.trim();
    if (topic.isEmpty) {
      return {'success': false, 'message': 'Please enter your query'};
    }
    if (topic.length < 10) {
      return {
        'success': false,
        'message': 'Query must be at least 10 characters'
      };
    }

    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user == null || user.id == null) {
      return {'success': false, 'message': 'User details not found'};
    }

    _isSubmitting = true;
    notifyListeners();

    DateTime now = DateTime.now().toUtc(); // Get current time in UTC
    String formattedDate = now.toIso8601String();
    String apiUrl = ApiConstant.raiseTicket;
    RaiseTicketRequest raiseTicketRequest = RaiseTicketRequest();
    raiseTicketRequest.userId = user.id!;
    raiseTicketRequest.mobileNumber =
        user.mobileNumber; //client or admin mobile number
    raiseTicketRequest.email = user.emailId; //client or admin email
    raiseTicketRequest.image = imgUrl;
    raiseTicketRequest.date = formattedDate;
    raiseTicketRequest.feedback = '';
    raiseTicketRequest.tickedId = 0;
    raiseTicketRequest.topic = topic;

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
            _ticketList.insert(0, raiseTicketResponse.data!.ticketRaised!);
            clearAttachment(notify: false);
            topicController.clear();
            notifyListeners();
            return {
              'success': true,
              'message':
                  raiseTicketResponse.message ?? 'Ticket raised successfully'
            };
          } else {

            return {
              'success': false,
              'message': raiseTicketResponse.message ?? 'No data returned'
            };
          }
        } else {

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

      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Map<String, Object>> getRaisedTicketByUserId() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user == null || user.id == null) {
      return {'success': false, 'message': 'User details not found'};
    }

    _isLoadingTickets = true;
    notifyListeners();

    String apiUrl = ApiConstant.getRaisedTicketByUserId(user.id!);

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
            _sortTicketsByLatest();
            notifyListeners();
            return {
              'success': true,
              'message': getRaiseTicketListResponse.message!
            };
          } else {

            _ticketList.clear();
            notifyListeners();
            return {
              'success': false,
              'message':
                  getRaiseTicketListResponse.message ?? 'No data returned'
            };
          }
        } else {

          _ticketList.clear();
          notifyListeners();
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

      return {
        'success': false,
        'message': 'An error occurred while adding user: $error'
      };
    } finally {
      _isLoadingTickets = false;
      notifyListeners();
    }
  }

  Future<Map<String, Object>> deleteTicket(int ticketId) async {
    _deletingTicketId = ticketId;
    notifyListeners();

    final apiUrl = ApiConstant.deleteTicket(ticketId);
    final apiHelper = ApiHelper();

    try {
      final response = await apiHelper.deleteApi(apiUrl);
      if (response.statusCode == 200) {
        String message = 'Ticket deleted successfully';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map<String, dynamic> &&
              responseBody['message'] != null) {
            message = responseBody['message'].toString();
          }
        } catch (_) {}

        _ticketList.removeWhere((ticket) => ticket.tickedId == ticketId);
        notifyListeners();
        return {'success': true, 'message': message};
      }

      return {'success': false, 'message': 'Unable to delete ticket'};
    } catch (error) {

      return {
        'success': false,
        'message': 'An error occurred while deleting ticket'
      };
    } finally {
      _deletingTicketId = null;
      notifyListeners();
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
        await uploadImage();
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
          'file',
          byteData,
          filename: _webFile!.name,
        );

        request.files.add(multipartFile);
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          _setUploadedImageUrl(responseBody);
          notifyListeners();
        }
      } else if (!kIsWeb && _imageFile != null) {
        // Mobile/desktop upload logic
        final request = http.MultipartRequest('POST', url);
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
          //  contentType: MediaType('image', 'jpeg'),
        ));
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          _setUploadedImageUrl(responseBody);
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error uploading image: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void _setUploadedImageUrl(String responseBody) {
    final decoded = jsonDecode(responseBody);
    String? fileUrl;

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        fileUrl = data['fileUrl'] as String?;
      } else if (data is String) {
        fileUrl = data;
      }
      fileUrl ??= decoded['fileUrl'] as String?;
    } else if (decoded is String) {
      fileUrl = decoded;
    }

    if (fileUrl != null && fileUrl.isNotEmpty) {
      _uploadedImageUrl = fileUrl;
      imgUrl = fileUrl;
    } else {
      log('Upload success but fileUrl missing: $responseBody');
    }
  }

  void clearAttachment({bool notify = true}) {
    _imageFile = null;
    _webFile = null;
    _uploadedImageUrl = null;
    imgUrl = '';
    if (notify) {
      notifyListeners();
    }
  }

  void _sortTicketsByLatest() {
    _ticketList.sort((a, b) => (b.date ?? 0).compareTo(a.date ?? 0));
  }
}
