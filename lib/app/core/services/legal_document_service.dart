import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/response/legal_document_urls_response.dart';

class LegalDocumentService {
  LegalDocumentService._();

  static final LegalDocumentService instance = LegalDocumentService._();

  final ApiHelper _apiHelper = ApiHelper();
  LegalDocumentUrls? _cachedUrls;

  Future<LegalDocumentUrls> getDocumentUrls({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUrls != null) return _cachedUrls!;

    try {
      final response = await _apiHelper.getApi(ApiConstant.legalDocumentUrls);
      if (response.statusCode != 200) return LegalDocumentUrls.fallback;

      final body = jsonDecode(response.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic>) return LegalDocumentUrls.fallback;

      _cachedUrls = LegalDocumentUrls.fromJson(data).withFallbacks();
      return _cachedUrls!;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Legal document url fetch failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return LegalDocumentUrls.fallback;
    }
  }
}

