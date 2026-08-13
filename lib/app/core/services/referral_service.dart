import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';

class ReferralService {
  ReferralService._();

  static final ReferralService instance = ReferralService._();

  String? _pendingReferralCode;
  bool _isInitialized = false;

  String? get cachedReferralCode => _pendingReferralCode;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final stored = await LocalSharePreferences.localSharePreferences
          .getString(SharedPreferencesConstant.referralCode);
      final sanitized = sanitizeCode(stored);
      if (sanitized != null) {
        _pendingReferralCode = sanitized;
      } else if (stored.isNotEmpty) {
        await clearReferralCode();
      }
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to initialize ReferralService: $e',
          name: 'ReferralService',
          error: e,
          stackTrace: st,
        );
      }
    } finally {
      _isInitialized = true;
    }
  }

  String? sanitizeCode(String? rawCode) {
    if (rawCode == null) return null;
    final text = rawCode.trim();
    if (text.isEmpty) return null;

    String decoded;
    try {
      decoded = Uri.decodeComponent(text).trim();
    } catch (_) {
      decoded = text;
    }

    if (decoded.isEmpty) return null;
    if (decoded.contains('{') || decoded.contains('}')) return null;
    if (decoded.toLowerCase() == 'null' || decoded.toLowerCase() == 'undefined') {
      return null;
    }

    return decoded;
  }

  bool isValidReferralCode(String? rawCode) {
    return sanitizeCode(rawCode) != null;
  }

  Future<String?> captureFromUri(Uri? uri) async {
    if (uri == null) return getReferralCode();

    String? codeParam;
    final queryParams = uri.queryParameters;

    if (queryParams.containsKey('referralCode')) {
      codeParam = queryParams['referralCode'];
    } else if (queryParams.containsKey('referral_code')) {
      codeParam = queryParams['referral_code'];
    } else if (queryParams.containsKey('ref')) {
      codeParam = queryParams['ref'];
    }

    final sanitized = sanitizeCode(codeParam);
    if (sanitized != null) {
      await storeReferralCode(sanitized);
      return sanitized;
    }

    return getReferralCode();
  }

  Future<void> storeReferralCode(String code) async {
    final sanitized = sanitizeCode(code);
    if (sanitized == null) return;

    _pendingReferralCode = sanitized;
    try {
      await LocalSharePreferences.localSharePreferences.setString(
        SharedPreferencesConstant.referralCode,
        sanitized,
      );
      if (kDebugMode) {
        developer.log(
          'Preserved referral code: $sanitized',
          name: 'ReferralService',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error storing referral code: $e',
          name: 'ReferralService',
        );
      }
    }
  }

  Future<String?> getReferralCode() async {
    if (_pendingReferralCode != null) {
      return _pendingReferralCode;
    }

    try {
      final stored = await LocalSharePreferences.localSharePreferences
          .getString(SharedPreferencesConstant.referralCode);
      final sanitized = sanitizeCode(stored);
      _pendingReferralCode = sanitized;
      return sanitized;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearReferralCode() async {
    _pendingReferralCode = null;
    try {
      await LocalSharePreferences.localSharePreferences
          .remove(SharedPreferencesConstant.referralCode);
      if (kDebugMode) {
        developer.log(
          'Cleared referral code',
          name: 'ReferralService',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error clearing referral code: $e',
          name: 'ReferralService',
        );
      }
    }
  }
}
