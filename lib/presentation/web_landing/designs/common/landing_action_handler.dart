import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/legal_document_service.dart';
import 'package:ott/app/core/utils/legal_document_url_utils.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable action handler providing unified access to login, trailers,
/// legal documents, external platforms, and internal pages.
class LandingActionHandler {
  LandingActionHandler._();

  static void openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginCard()),
    );
  }

  static Future<void> openTrailer(
    BuildContext context,
    Content content,
  ) async {
    var playableContent = content;
    var trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';

    if (trailerUrl.isEmpty) {
      final provider = context.read<WebLandingProvider>();
      playableContent = await provider.loadContentWithTrailer(content);
      trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';
    }

    if (!context.mounted) return;
    if (trailerUrl.isEmpty) {
      CustomToast.show(
        context,
        'Trailer not available for this title right now.',
        isSuccess: false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: playableContent,
        ),
      ),
    );
  }

  static Future<void> openExternal(BuildContext context, String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!context.mounted) return;
      if (!opened) {
        CustomToast.show(
          context,
          'Unable to open link.',
          isSuccess: false,
        );
      }
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          'Unable to open link.',
          isSuccess: false,
        );
      }
    }
  }

  static Future<void> openDocument(BuildContext context, String rawUrl) async {
    try {
      final uri = legalDocumentViewUri(rawUrl);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!context.mounted || opened) return;
      CustomToast.show(
        context,
        'Unable to open document.',
        isSuccess: false,
      );
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          'Unable to open document.',
          isSuccess: false,
        );
      }
    }
  }

  static Future<void> openPrivacyPolicy(BuildContext context) async {
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final url = documentUrls.privacyPolicyUrl.trim().isEmpty
          ? AppConstant.privacyPolicy
          : documentUrls.privacyPolicyUrl;
      if (context.mounted) {
        await openDocument(context, url);
      }
    } catch (_) {
      if (context.mounted) {
        await openDocument(context, AppConstant.privacyPolicy);
      }
    }
  }

  static Future<void> openTerms(BuildContext context) async {
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final url = documentUrls.termsAndConditionsUrl.trim().isEmpty
          ? AppConstant.termsAndCondition
          : documentUrls.termsAndConditionsUrl;
      if (context.mounted) {
        await openDocument(context, url);
      }
    } catch (_) {
      if (context.mounted) {
        await openDocument(context, AppConstant.termsAndCondition);
      }
    }
  }

  static Future<void> openInternalStaticPage(
    BuildContext context,
    String path,
  ) async {
    try {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final base = Uri.base;
      final uri = kIsWeb
          ? Uri(
              scheme: base.scheme.isNotEmpty ? base.scheme : 'https',
              host: base.host.isNotEmpty ? base.host : 'filmytell.com',
              port: base.hasPort ? base.port : null,
              path: cleanPath,
            )
          : Uri.https('filmytell.com', cleanPath);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
      if (!context.mounted || opened) return;
      CustomToast.show(
        context,
        'Unable to open page.',
        isSuccess: false,
      );
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          'Unable to open page.',
          isSuccess: false,
        );
      }
    }
  }
}
