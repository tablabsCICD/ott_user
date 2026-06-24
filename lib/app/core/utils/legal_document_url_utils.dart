Uri legalDocumentViewUri(String url) {
  final trimmedUrl = url.trim();
  final uri = Uri.parse(trimmedUrl);

  final drivePreviewUri = _googleDrivePreviewUri(uri);
  if (drivePreviewUri != null) return drivePreviewUri;

  if (_shouldUseEmbeddedDocumentViewer(uri)) {
    return Uri.https('docs.google.com', '/gview', {
      'embedded': 'true',
      'url': trimmedUrl,
    });
  }

  return uri;
}

bool _shouldUseEmbeddedDocumentViewer(Uri uri) {
  if (!uri.hasScheme || !uri.hasAuthority) return false;

  final path = uri.path.toLowerCase();
  return path.endsWith('.pdf') ||
      path.endsWith('.doc') ||
      path.endsWith('.docx');
}

Uri? _googleDrivePreviewUri(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host != 'drive.google.com' && host != 'www.drive.google.com') {
    return null;
  }

  final segments = uri.pathSegments;
  String? fileId;

  final fileSegmentIndex = segments.indexOf('file');
  if (fileSegmentIndex != -1 &&
      fileSegmentIndex + 2 < segments.length &&
      segments[fileSegmentIndex + 1] == 'd') {
    fileId = segments[fileSegmentIndex + 2];
  }

  fileId ??= uri.queryParameters['id'];
  if (fileId == null || fileId.trim().isEmpty) return null;

  return Uri.https('drive.google.com', '/file/d/${fileId.trim()}/preview');
}
