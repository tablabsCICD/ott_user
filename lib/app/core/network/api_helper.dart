import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/response/api_response.dart';
import '../constant/prefrense_constant.dart';
import '../utils/sharepreferences.dart';

class ApiHelper {
  Future<dynamic> getApi(String URL) async {
    debugPrint("✅" + URL);
    final url = Uri.parse(URL);
    var request = await http.get(url).timeout(Duration(seconds: 10));
    debugPrint(request.body);
    return request;
  }

  Future<dynamic> getApi1(String URL) async {
    debugPrint("✅GET API" + URL);
    final url = Uri.parse(URL);
    var request = await http.get(url);
    debugPrint("GETAPI RESPONSE ${request.body}");
    return request;
  }

  Future<dynamic> deleteApi(String URL) async {
    debugPrint("✅" + URL);
    var request = await http.delete(Uri.parse(URL), headers: {
      "Content-Type": "application/json",
    });
    debugPrint(request.body);
    return request;
  }

  Future<dynamic> postApi(String URL) async {
    debugPrint("✅" + URL);
    var request = await http.post(Uri.parse(URL), headers: {
      "Content-Type": "application/json",
    });
    debugPrint(request.body);
    return request;
  }

  Future<dynamic> postApiWithBody(String url, Map<String, dynamic> data) async {
    debugPrint("✅" + url);
    var body = json.encode(data);
    print(body);
    final response = await http.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: body);
    debugPrint(response.body);
    return response;
  }

  Future<dynamic> putApi(String URL) async {
    debugPrint("✅" + URL);
    var request = await http.put(Uri.parse(URL), headers: {
      "Content-Type": "application/json",
    });
    debugPrint(request.body);
    return request;
  }

  Future<dynamic> putApiWithBody(String url, Map<String, dynamic> data) async {
    debugPrint("✅" + url);
    var body = json.encode(data);
    debugPrint(body);
    final response = await http.put(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: body);
    debugPrint(response.body);
    return response;
  }

  Future<dynamic> postApiWithoutAuthToken(String URL) async {
    debugPrint("✅" + URL);
    var request = await http.post(Uri.parse(URL));
    debugPrint(request.body);
    return request;
  }

  Future<dynamic> postApiWithoutBodyAndToken(
      String url, Map<String, dynamic> data) async {
    debugPrint("✅" + url);
    var body = json.encode(data);
    debugPrint(body);
    final response = await http.post(Uri.parse(url),
        headers: {"Content-Type": "application/json"}, body: body);
    debugPrint(response.body);
    return response;
  }

  ApiResponse returnResponse<T>(Response request) {
    if (request.statusCode == 200 ||
        request.statusCode == 400 ||
        request.statusCode == 201) {
      var response1 = request.body;
      print("**************************************${response1}");
      var response = jsonDecode(request.body);
      ApiResponse apiResponseHelper = ApiResponse(request.statusCode, response);
      return apiResponseHelper;
    } else {
      ApiResponse apiResponseHelper = ApiResponse(request.statusCode, null);
      return apiResponseHelper;
    }
  }
}
