import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/getContentResponse.dart';
import 'package:ott/data/models/user.dart';
import 'dart:convert';

import '../../data/models/response/get_dashboard_data.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import 'baseProvider.dart';

class DashboardProvider extends BaseProvider {
  DashboardProvider() : super('Ideal') {}

  List<DashboardData> _dashboardData = [];
  get dashboardData => _dashboardData;

  Content _content = Content();

  get content => _content;

  TextEditingController searchContentController = TextEditingController();

  getDashboardData(String type, List<String> languages, int userId) async {
    List<DashboardData> finalDashboardData = [];

    await Future.wait([
      _safeApiCall(
        () => getDashboardLatestData(type, languages, userId),
        (data) => finalDashboardData.addAll(data),
      ),
      _safeApiCall(
        () => getDashboardTrendingData(type, languages, userId),
        (data) => finalDashboardData.addAll(data),
      ),
      _safeApiCall(
        () => getDashboardUpcomingData(type, languages, userId),
        (data) => finalDashboardData.addAll(data),
      ),
    ]);

    if (finalDashboardData.isNotEmpty) {
      _dashboardData = finalDashboardData;
      notifyListeners();
    }
  }

  Future<void> _safeApiCall(
    Future<List<DashboardData>> Function() apiCall,
    Function(List<DashboardData>) onSuccess,
  ) async {
    try {
      final result = await apiCall();
      if (result.isNotEmpty) {
        onSuccess(result);
      }
    } catch (e) {
      debugPrint("API failed but continuing: $e");
    }
  }

  Future<List<DashboardData>> getDashboardLatestData(
      String type, List<String> languages, int userId) async {
    String languagesParam = languages.map((lang) => "langList=$lang").join('&');

    String apiUrl =
        "${ApiConstant.getNewDashboardData}latest?type=$type&$languagesParam&userId=$userId";

    debugPrint(apiUrl);
    ApiHelper apiHelper = ApiHelper();
    var response = await apiHelper.getApi(apiUrl);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      DashboardResponse dashboardResponse =
          DashboardResponse.fromJson(responseBody);

      return dashboardResponse.data!;
    } else {
      throw Exception('Latest API Failed');
    }
  }

  Future<List<DashboardData>> getDashboardTrendingData(
      String type, List<String> languages, int userId) async {
    String languagesParam = languages.map((lang) => "langList=$lang").join('&');

    String apiUrl =
        "${ApiConstant.getNewDashboardData}trending?type=$type&$languagesParam&userId=$userId";

    ApiHelper apiHelper = ApiHelper();
    var response = await apiHelper.getApi(apiUrl);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      DashboardResponse dashboardResponse =
          DashboardResponse.fromJson(responseBody);

      return dashboardResponse.data!;
    } else {
      throw Exception('Trending API Failed');
    }
  }

  Future<List<DashboardData>> getDashboardUpcomingData(
      String type, List<String> languages, int userId) async {
    String languagesParam = languages.map((lang) => "langList=$lang").join('&');

    String apiUrl =
        "${ApiConstant.getNewDashboardData}upcoming?type=$type&$languagesParam&userId=$userId";

    ApiHelper apiHelper = ApiHelper();
    var response = await apiHelper.getApi(apiUrl);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      DashboardResponse dashboardResponse =
          DashboardResponse.fromJson(responseBody);

      return dashboardResponse.data!;
    } else {
      throw Exception('Upcoming API Failed');
    }
  }

  getContentById(int id) async {
    User? user = await LocalSharePreferences.localSharePreferences.getUser();
    String apiUrl = ApiConstant.getVideoById(id, user!.id);
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        GetContentResponse addUserResponse =
            GetContentResponse.fromJson(responseBody);
        //print("\ncontent by id response " + responseBody.toString());
        if (addUserResponse.success == true) {
          if (addUserResponse.data != null &&
              addUserResponse.data!.contentList != null) {
            _content = addUserResponse.data!.contentList!;
            notifyListeners();
          } else {
            debugPrint("empty data: ${addUserResponse.message}");
          }
        } else {
          debugPrint("Error: ${addUserResponse.message}");
        }
      } else {
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint("Error: $error");
      throw Exception('An error occurred while fetching data.');
    }
  }

  // List<Content> _trendingContentList = [];
  // List<Content> get trendingContentList => _trendingContentList;

  // Future<void> getTopTrendingContent() async {
  //   //log('=======inside top 10 trending');
  //   User? user = await LocalSharePreferences.localSharePreferences.getUser();
  //   String apiUrl = ApiConstant.getTopTrendingContentLast7Days(user!.id);
  //   ApiHelper apiHelper = ApiHelper();

  //   try {
  //     var response = await apiHelper.getApi(apiUrl);

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseBody = json.decode(response.body);

  //       final List<dynamic> list = responseBody['data']?['TopTenContent'] ?? [];

  //       _trendingContentList = list
  //           .where((e) => e != null) // 👈 remove null items
  //           .map((e) => Content.fromJson(e))
  //           .toList();

  //       notifyListeners();
  //     } else {
  //       throw Exception(
  //           'Failed to get data. Status code: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     log('Trending error: $error');
  //     throw Exception('An error occurred while fetching the data.');
  //   }
  // }
}
