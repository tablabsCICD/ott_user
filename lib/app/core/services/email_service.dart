import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';

class EmailService {
  EmailService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String recipientEmail = 'swatibahir@gmail.com';

  Future<bool> sendEmail({
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstant.sendEmail),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'subject': subject,
              'to': recipientEmail,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint('Email API response [${response.statusCode}]: '
            '${response.body}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['success'] == true;
      }

      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Email API error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }
}
