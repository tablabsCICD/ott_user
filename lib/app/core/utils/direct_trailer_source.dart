/// Defines the source boundary for trailer playback.
///
/// Trailer URLs come directly from the backend and must never be routed
/// through the protected movie signed-URL workflow.
abstract final class DirectTrailerSource {
  static String? fromBackend(String? backendUrl) {
    if (backendUrl == null || backendUrl.trim().isEmpty) return null;
    return backendUrl;
  }
}
