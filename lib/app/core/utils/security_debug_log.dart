import 'package:flutter/foundation.dart';

/// Debug-only tracing for the secure playback pipeline.
///
/// Normal events contain no playback secrets. Diagnostics may contain device
/// and source details needed to investigate backend integration, but callers
/// must redact JWTs, signed URLs, signatures, and session IDs.
abstract final class SecurityDebugLog {
  static void event(String component, String message) {
    if (!kDebugMode) return;
    debugPrint('[SECURE_PLAYBACK][$component] $message');
  }

  static void state(String from, String to) {
    event('STATE', '$from -> $to');
  }

  static void diagnostic(String message) {
    if (!kDebugMode) return;
    const maximumLength = 12000;
    final printable = message.length <= maximumLength
        ? message
        : '${message.substring(0, maximumLength)}...[truncated]';
    debugPrint('[SECURE_PLAYBACK][HTTP_DIAGNOSTIC] $printable');
  }

  static void exception(
    String component,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    final errorText = _redactSecrets(error.toString());
    final stackText = stackTrace == null
        ? '<not available>'
        : _redactSecrets(
            stackTrace.toString().split('\n').take(8).join(' | '),
          );
    diagnostic(
      'EXCEPTION component=$component type=${error.runtimeType} '
      'message=$errorText stack=$stackText',
    );
  }

  static String _redactSecrets(String value) {
    var result = value.replaceAll(
      RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
      'Bearer <redacted>',
    );
    result = result.replaceAllMapped(
      RegExp(r"""https?://[^\s<>"']+""", caseSensitive: false),
      (match) {
        final rawUrl = match.group(0)!;
        final uri = Uri.tryParse(rawUrl);
        if (uri == null) return '<url-redacted>';
        final safeUrl = '${uri.scheme}://${uri.authority}${uri.path}';
        return uri.hasQuery ? '$safeUrl?<redacted>' : safeUrl;
      },
    );
    return result;
  }
}
