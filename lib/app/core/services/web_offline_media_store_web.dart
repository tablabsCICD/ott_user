import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:web/web.dart' as web;

const String _cacheName = 'ott_offline_media_cache_v1';

String _cacheKey(int contentId) => '/offline_media/$contentId';

Future<bool> hasWebOfflineMediaImpl(int contentId) async {
  try {
    final caches = html.window.caches;
    if (caches == null) return false;
    final cache = await caches.open(_cacheName);
    final response = await cache.match(_cacheKey(contentId));
    return response != null;
  } catch (_) {
    return false;
  }
}

Future<String?> openWebOfflineMediaImpl(int contentId) async {
  try {
    final caches = html.window.caches;
    if (caches == null) return null;
    final cache = await caches.open(_cacheName);
    final response = await cache.match(_cacheKey(contentId));
    if (response == null) return null;
    final blob = await response.blob();
    return html.Url.createObjectUrlFromBlob(blob);
  } catch (_) {
    return null;
  }
}

Future<void> storeWebOfflineMediaImpl(int contentId, String videoUrl) async {
  final caches = html.window.caches;
  if (caches == null) {
    throw UnsupportedError('Cache API is not supported in this environment.');
  }

  final response = await http.get(Uri.parse(videoUrl));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to download media: HTTP ${response.statusCode}');
  }

  final webResponse = web.Response(response.bodyBytes.toJS);
  final cache = await caches.open(_cacheName);
  await cache.put(_cacheKey(contentId), webResponse);
}

Future<void> deleteWebOfflineMediaImpl(int contentId) async {
  try {
    final caches = html.window.caches;
    if (caches == null) return;
    final cache = await caches.open(_cacheName);
    await cache.delete(_cacheKey(contentId));
  } catch (_) {}
}

void revokeWebOfflineMediaUrlImpl(String? url) {
  if (url != null && url.startsWith('blob:')) {
    try {
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }
}
