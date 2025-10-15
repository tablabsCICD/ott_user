import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/response/saveUserContent.dart';
import 'package:ott/data/models/user.dart';

import '../../data/models/content.dart';
import '../../data/models/response/purchesContentListResponse.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';

class PurchaseContentProvider extends ChangeNotifier {
  List<UserContent> _userContentList = [];

  List<UserContent> get userContentList => _userContentList;

  Future<Map<String, Object>> saveUserContent(Content content) async {
    String apiUrl = ApiConstant.saveUserContent;
    print(apiUrl);
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    Map<String, dynamic> mapData = {
      "active": true,
      "contentPercentage": 0,
      "dateFrom": "",
      "dateTo": "",
      "id": 0,
      "isGifted": false,
      "movieId": content.id!,
      "price": content.price!,
      "referedBy": '',
      "status": "Paid",
      "userId": user!.id!,
      "userIdGiftFrom": 0,
      "userIdGiftTo": 0
    };
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(apiUrl, mapData);
      print(response);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        SavePurchaseContentResponse addUserResponse =
            SavePurchaseContentResponse.fromJson(responseBody);

        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            _userContentList.add(addUserResponse.data!.userContentPurchase!);
            notifyListeners();
            return {'success': true, 'message': addUserResponse.message!};
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

  Future<Map<String, Object>> getPurchaseContent() async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.getUserContent(user!.id!);
    print("API URL: $apiUrl");

    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.getApi(apiUrl);
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // SAFELY parse the response with try-catch to catch date format issues
        try {
          PurchaseContentListResponse parsedResponse =
              PurchaseContentListResponse.fromJson(responseBody);

          if (parsedResponse.success == true) {
            if (parsedResponse.data != null &&
                parsedResponse.data!.userContent != null) {
              _userContentList.clear();
              _userContentList.addAll(parsedResponse.data!.userContent!);
              notifyListeners();

              return {
                'success': true,
                'message': parsedResponse.message ?? 'Data loaded successfully'
              };
            } else {
              debugPrint("Empty data: ${parsedResponse.message}");
              return {
                'success': false,
                'message': parsedResponse.message ?? 'No data returned'
              };
            }
          } else {
            debugPrint("API error: ${parsedResponse.message}");
            return {
              'success': false,
              'message': parsedResponse.message ?? 'Error in response'
            };
          }
        } catch (e) {
          debugPrint("Parsing error: $e");
          return {'success': false, 'message': 'Error while parsing data: $e'};
        }
      } else {
        return {'success': false, 'message': 'Something went wrong!'};
      }
    } catch (error) {
      debugPrint("Network error: $error");
      return {
        'success': false,
        'message': 'An error occurred while fetching content: $error'
      };
    }
  }
}
