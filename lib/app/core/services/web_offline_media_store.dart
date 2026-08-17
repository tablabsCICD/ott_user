import 'web_offline_media_store_stub.dart'
    if (dart.library.html) 'web_offline_media_store_web.dart';

Future<bool> hasWebOfflineMedia(int contentId) =>
    hasWebOfflineMediaImpl(contentId);

Future<String?> openWebOfflineMedia(int contentId) =>
    openWebOfflineMediaImpl(contentId);

Future<void> storeWebOfflineMedia(int contentId, String videoUrl) =>
    storeWebOfflineMediaImpl(contentId, videoUrl);

Future<void> deleteWebOfflineMedia(int contentId) =>
    deleteWebOfflineMediaImpl(contentId);

void revokeWebOfflineMediaUrl(String? url) =>
    revokeWebOfflineMediaUrlImpl(url);
