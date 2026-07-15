import 'package:ott/app/core/constant/api_constant.dart';

String normalizeNetworkImageUrl(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    return Uri.encodeFull(trimmed);
  }

  if (trimmed.startsWith('/')) {
    final baseUri = Uri.parse(ApiConstant.baseUrl);
    return baseUri
        .replace(path: trimmed, query: null, fragment: null)
        .toString();
  }

  return Uri.parse(ApiConstant.baseUrl).resolve(trimmed).toString();
}

