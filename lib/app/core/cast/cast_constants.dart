class CastConfig {
  /// Resolves the active Google Cast Application ID.
  /// Configurable via `--dart-define=CAST_APP_ID=YOUR_APP_ID`.
  /// The actual production Cast App ID is supplied upon registration in Google Cast Developer Console.
  /// Configured with FilmyTell Custom Receiver Application ID: 0C452C93
  static const String appId = String.fromEnvironment(
    'CAST_APP_ID',
    defaultValue: '0C452C93',
  );

  /// Indicates whether the application is running with a registered custom receiver ID
  static bool get isCustomReceiver => appId == '0C452C93';
}

class CastConstants {
  /// Reference to configured Cast Application ID
  static String get castAppId => CastConfig.appId;

  /// Custom message namespace for FilmyTell custom sender-receiver telemetry & controls.
  static const String castNamespace = 'urn:x-cast:com.filmytell.ott.cast';

  /// Media MIME types
  static const String hlsMimeType = 'application/x-mpegurl';
  static const String mp4MimeType = 'video/mp4';
}
