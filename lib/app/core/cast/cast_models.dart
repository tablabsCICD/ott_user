enum CastPlayerState {
  disconnected,
  discovering,
  connecting,
  connected,
  playing,
  paused,
  buffering,
  error,
}

class CastDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? modelName;
  final bool isConnected;

  const CastDevice({
    required this.id,
    required this.name,
    required this.host,
    this.port = 8009,
    this.modelName,
    this.isConnected = false,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? modelName,
    bool? isConnected,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      modelName: modelName ?? this.modelName,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CastDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          host == other.host;

  @override
  int get hashCode => id.hashCode ^ host.hashCode;
}

class CastMediaMetadata {
  final int contentId;
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final String mediaUrl;
  final String contentType;
  final Duration initialPosition;
  final Duration? duration;
  final bool isSeries;
  final int? seasonId;
  final int? episodeId;
  final String? authToken;
  final String? watermarkText;

  const CastMediaMetadata({
    required this.contentId,
    required this.title,
    this.subtitle,
    this.posterUrl,
    required this.mediaUrl,
    this.contentType = 'application/x-mpegurl',
    this.initialPosition = Duration.zero,
    this.duration,
    this.isSeries = false,
    this.seasonId,
    this.episodeId,
    this.authToken,
    this.watermarkText,
  });

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (posterUrl != null) 'posterUrl': posterUrl,
      'mediaUrl': mediaUrl,
      'contentType': contentType,
      'initialPositionSeconds': initialPosition.inSeconds,
      if (duration != null) 'durationSeconds': duration!.inSeconds,
      'isSeries': isSeries,
      if (seasonId != null) 'seasonId': seasonId,
      if (episodeId != null) 'episodeId': episodeId,
      if (authToken != null) 'authToken': authToken,
      if (watermarkText != null) 'watermarkText': watermarkText,
    };
  }
}
