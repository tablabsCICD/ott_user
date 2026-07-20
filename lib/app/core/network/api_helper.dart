import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/response/api_response.dart';
import '../services/session_manager.dart';
import '../utils/sharepreferences.dart';

class ApiHelper {
  Future<dynamic> getApi(String url) async {
    _logRequest("GET", url);
    final request = await http
        .get(Uri.parse(url), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    return _handleResponse(request);
  }

  Future<dynamic> getApi1(String url) async {
    _logRequest("GET", url);
    final request = await http.get(Uri.parse(url), headers: await _headers());
    return _handleResponse(request);
  }

  Future<dynamic> deleteApi(String url) async {
    _logRequest("DELETE", url);
    final request =
        await http.delete(Uri.parse(url), headers: await _headers());
    return _handleResponse(request);
  }

  Future<dynamic> postApi(String url) async {
    _logRequest("POST", url);
    final request = await http.post(Uri.parse(url), headers: await _headers());
    return _handleResponse(request);
  }

  Future<dynamic> postApiWithBody(String url, Map<String, dynamic> data) async {
    _logRequest("POST", url);
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> putApi(String url) async {
    _logRequest("PUT", url);
    final request = await http.put(Uri.parse(url), headers: await _headers());
    return _handleResponse(request);
  }

  Future<dynamic> putApiWithBody(String url, Map<String, dynamic> data) async {
    _logRequest("PUT", url);
    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> postApiWithoutAuthToken(String url) async {
    _logRequest("POST", url);
    final request = await http.post(Uri.parse(url));
    _logResponse(request);
    return request;
  }

  Future<dynamic> postApiWithoutBodyAndToken(
    String url,
    Map<String, dynamic> data,
  ) async {
    _logRequest("POST", url);
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    return response;
  }

  ApiResponse returnResponse<T>(Response request) {
    if (request.statusCode == 200 ||
        request.statusCode == 400 ||
        request.statusCode == 201) {
      final response = jsonDecode(request.body);
      return ApiResponse(request.statusCode, response);
    } else {
      return ApiResponse(request.statusCode, null);
    }
  }

  Future<Map<String, String>> _headers() async {
    final token =
        await LocalSharePreferences.localSharePreferences.getAuthToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<Response> _handleResponse(Response response) async {
    if (SessionManager.instance.isReplacementSessionResponse(response)) {
      final message = SessionManager.extractMessage(response.body) ??
          SessionManager.replacementSessionMessage;
      await SessionManager.instance.handleSessionExpired(message);
    }
    _logResponse(response);
    return response;
  }

  void _logRequest(String method, String url) {
    if (!kDebugMode) return;
    final uri = Uri.tryParse(url);
    final redacted = uri == null
        ? 'redacted'
        : uri.replace(queryParameters: const {}).toString();
    debugPrint("$method $redacted");
  }

  void _logResponse(Response response) {
    if (!kDebugMode) return;
    final uri = response.request?.url;
    final endpoint = uri == null
        ? '<unknown>'
        : '${uri.scheme}://${uri.authority}${uri.path}';
    debugPrint(
      'HTTP response endpoint=$endpoint status=${response.statusCode} bytes=${response.bodyBytes.length}',
    );
  }
}
