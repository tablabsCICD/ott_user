import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/prefrense_constant.dart';

class ReferralService {
  ReferralService._();

  static final ReferralService instance = ReferralService._();

  static bool isValidCode(String? rawCode) {
    if (rawCode == null) return false;
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    if (lower == '{referralcode}' ||
        lower == '{referral_code}' ||
        lower == '{code}' ||
        lower == 'undefined' ||
        lower == 'null') {
      return false;
    }

    return trimmed.length >= 2;
  }

  static String? extractCodeFromUri(Uri? uri) {
    if (uri == null) return null;

    final queryParams = uri.queryParameters;
    String? rawValue;

    for (final entry in queryParams.entries) {
      final keyLower = entry.key.trim().toLowerCase();
      if (keyLower == 'referralcode' ||
          keyLower == 'referral_code' ||
          keyLower == 'ref') {
        rawValue = entry.value;
        break;
      }
    }

    if (rawValue == null &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.last.toLowerCase() == 'register') {
      rawValue = queryParams['code'];
    }

    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = Uri.decodeComponent(rawValue).trim();
      return isValidCode(decoded) ? decoded : null;
    } catch (_) {
      final trimmed = rawValue.trim();
      return isValidCode(trimmed) ? trimmed : null;
    }
  }

  Future<String?> captureFromUri(Uri? uri) async {
    final code = extractCodeFromUri(uri);
    if (code != null) {
      await saveReferralCode(code);
      developer.log(
        'Captured valid referral code from URL: $code',
        name: 'ReferralService',
      );
      return code;
    }
    return getPendingReferralCode();
  }

  Future<void> saveReferralCode(String code) async {
    if (!isValidCode(code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesConstant.pendingReferralCode, code.trim());
  }

  Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SharedPreferencesConstant.pendingReferralCode);
    if (isValidCode(raw)) {
      return raw!.trim();
    }
    return null;
  }

  Future<void> clearReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferencesConstant.pendingReferralCode);
    developer.log(
      'Cleared pending referral code',
      name: 'ReferralService',
    );
  }
}
