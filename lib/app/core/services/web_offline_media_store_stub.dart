Future<void> storeWebOfflineMedia(int contentId, String sourceUrl) =>
    Future<void>.error(
      UnsupportedError('Browser offline storage is unavailable.'),
    );

Future<bool> hasWebOfflineMedia(int contentId) async => false;

Future<String?> openWebOfflineMedia(int contentId) async => null;

Future<void> deleteWebOfflineMedia(int contentId) async {}

void revokeWebOfflineMediaUrl(String? url) {}
