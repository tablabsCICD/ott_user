import 'package:ott/app/core/constant/app_constant.dart';

class LegalDocumentUrls {
  const LegalDocumentUrls({
    required this.privacyPolicyUrl,
    required this.termsAndConditionsUrl,
  });

  final String privacyPolicyUrl;
  final String termsAndConditionsUrl;

  factory LegalDocumentUrls.fromJson(Map<String, dynamic> json) {
    return LegalDocumentUrls(
      privacyPolicyUrl: (json['privacyPolicyUrl'] ?? '').toString(),
      termsAndConditionsUrl: (json['termsAndConditionsUrl'] ?? '').toString(),
    );
  }

  static const fallback = LegalDocumentUrls(
    privacyPolicyUrl: AppConstant.privacyPolicy,
    termsAndConditionsUrl: AppConstant.termsAndCondition,
  );

  LegalDocumentUrls withFallbacks() {
    return LegalDocumentUrls(
      privacyPolicyUrl: privacyPolicyUrl.trim().isNotEmpty
          ? privacyPolicyUrl.trim()
          : AppConstant.privacyPolicy,
      termsAndConditionsUrl: termsAndConditionsUrl.trim().isNotEmpty
          ? termsAndConditionsUrl.trim()
          : AppConstant.termsAndCondition,
    );
  }
}

