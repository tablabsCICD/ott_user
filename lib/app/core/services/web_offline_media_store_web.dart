import 'dart:js_interop';

import 'package:web/web.dart' as web;

const String _cacheName = 'filmytell-offline-media-v1';

String _cacheKey(int contentId) =>
    Uri.base.resolve('/__filmytell_offline_media__/$contentId').toString();

Future<web.Cache> _openCache() => web.window.caches.open(_cacheName).toDart;

Future<void> storeWebOfflineMedia(int contentId, String sourceUrl) async {
  late final web.Response response;
  try {
    response = await web.window
        .fetch(
          sourceUrl.toJS,
          web.RequestInit(
            mode: 'cors',
            credentials: 'include',
            cache: 'no-store',
          ),
        )
        .toDart;
  } catch (_) {
    throw StateError(
      'The media server blocked the offline download. Allow this site origin '
      'in the CDN CORS policy for GET, HEAD, and Range requests.',
    );
  }
  if (!response.ok) {
    throw StateError('Media download failed with HTTP ${response.status}.');
  }

  final contentType = response.headers.get('content-type')?.toLowerCase() ?? '';
  final sourcePath = Uri.tryParse(sourceUrl)?.path.toLowerCase() ?? '';
  final isHls = sourcePath.endsWith('.m3u8') ||
      contentType.contains('mpegurl') ||
      contentType.contains('vnd.apple.mpegurl');
  if (isHls) {
    throw StateError(
      'Protected HLS cannot be saved as one browser file. A backend offline '
      'package or DRM offline-license endpoint is required.',
    );
  }

  final cache = await _openCache();
  await cache.put(_cacheKey(contentId).toJS, response).toDart;
}

Future<bool> hasWebOfflineMedia(int contentId) async {
  final cache = await _openCache();
  final response = await cache.match(_cacheKey(contentId).toJS).toDart;
  return response != null;
}

Future<String?> openWebOfflineMedia(int contentId) async {
  final cache = await _openCache();
  final response = await cache.match(_cacheKey(contentId).toJS).toDart;
  if (response == null) return null;

  final blob = await response.blob().toDart;
  return web.URL.createObjectURL(blob);
}

Future<void> deleteWebOfflineMedia(int contentId) async {
  final cache = await _openCache();
  await cache.delete(_cacheKey(contentId).toJS).toDart;
}

void revokeWebOfflineMediaUrl(String? url) {
  if (url != null && url.startsWith('blob:')) {
    web.URL.revokeObjectURL(url);
  }
}
