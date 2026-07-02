import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ott/data/models/response/saveUserContent.dart';
import 'package:ott/data/models/user.dart';

import '../../data/models/content.dart';
import '../../data/models/response/purchesContentListResponse.dart';
import '../core/network/api_helper.dart';
import '../core/constant/prefrense_constant.dart';
import '../core/utils/sharepreferences.dart';
import 'baseProvider.dart';

class PurchaseContentProvider extends BaseProvider {
  static const String _purchaseCacheKey = 'cached_purchase_content';
  final List<UserContent> _userContentList = [];
  bool _isSavingContent = false;

  List<UserContent> get userContentList => _userContentList;
  bool get isSavingContent => _isSavingContent;

  Future<Map<String, Object>> saveUserContent(Content content) async {
    if (_isSavingContent) {
      return {
        'success': false,
        'message': 'Purchase already in progress. Please wait.'
      };
    }

    _isSavingContent = true;
    notifyListeners();

    String apiUrl = ApiConstant.saveUserContent;

    debugPrint("save user content=================== $apiUrl");

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
    debugPrint(mapData.toString());
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.postApiWithBody(apiUrl, mapData);
      debugPrint("save user content ${response.body}");
      final responseBody = _decodeResponseBody(response.body);
      if (response.statusCode == 200) {
        SavePurchaseContentResponse addUserResponse =
            SavePurchaseContentResponse.fromJson(responseBody);

        if (addUserResponse.success == true) {
          if (addUserResponse.data != null) {
            _userContentList.add(addUserResponse.data!.userContentPurchase!);
            await _persistPurchaseContentCache();
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
            'message': _cleanPurchaseError(
              addUserResponse.message ?? 'Error in response',
            ),
          };
        }
      } else {
        return {
          'success': false,
          'message': _cleanPurchaseError(
            responseBody['message']?.toString() ??
                'Purchase failed. Please try again.',
          ),
        };
      }
    } catch (error) {
      debugPrint("Error: $error");
      return {
        'success': false,
        'message': _cleanPurchaseError(error)
      };
    } finally {
      _isSavingContent = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {};
  }

  String _cleanPurchaseError(Object error) {
    final message = error.toString();
    if (message.contains('Unknown duration:')) {
      return message.replaceFirst('Exception: ', '');
    }
    if (_isServerTransactionError(message)) {
      return 'Purchase could not be completed. Please try again in a moment.';
    }

    return 'Purchase failed. Please try again.';
  }

  bool _isServerTransactionError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('transactionrequiredexception') ||
        normalized.contains('no entitymanager with actual transaction') ||
        normalized.contains("cannot reliably process 'remove' call") ||
        normalized.contains('nested exception is javax.persistence');
  }

  Future<Map<String, Object>> getPurchaseContent({
    bool isGifted = false,
    bool isExpired = false,
  }) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user?.id == null) {
      await _loadPurchaseContentCache();
      return {
        'success': false,
        'message': 'User data is not available.',
      };
    }

    String apiUrl = ApiConstant.getUserContent(
      user!.id!,
      isGifted: isGifted,
      isExpired: isExpired,
    );
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
              if (!isGifted && !isExpired) {
                await _persistPurchaseContentCache();
              }
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
        await _loadPurchaseContentCache();
        return {
          'success': _userContentList.isNotEmpty,
          'message': _userContentList.isNotEmpty
              ? 'Loaded cached purchase content.'
              : 'Something went wrong!',
        };
      }
    } catch (error) {
      debugPrint("Network error: $error");
      await _loadPurchaseContentCache();
      return {
        'success': _userContentList.isNotEmpty,
        'message': _userContentList.isNotEmpty
            ? 'Loaded cached purchase content.'
            : 'An error occurred while fetching content: $error'
      };
    }
  }

  Future<void> _persistPurchaseContentCache() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user?.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final encoded = _userContentList
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(
      '${SharedPreferencesConstant.currentUser}_${_purchaseCacheKey}_${user!.id}',
      encoded,
    );
  }

  Future<void> _loadPurchaseContentCache() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user?.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(
          '${SharedPreferencesConstant.currentUser}_${_purchaseCacheKey}_${user!.id}',
        ) ??
        const <String>[];

    final cachedItems = <UserContent>[];
    for (final raw in rawList) {
      try {
        cachedItems.add(UserContent.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }

    _userContentList
      ..clear()
      ..addAll(cachedItems);
    notifyListeners();
  }
}
