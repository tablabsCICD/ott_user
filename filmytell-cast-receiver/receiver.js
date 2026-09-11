/**
 * FilmyTell Google Cast Custom Web Receiver Main Application
 */

const context = cast.framework.CastReceiverContext.getInstance();
const playerManager = context.getPlayerManager();

// Custom message namespace for FilmyTell sender-receiver communication
const FILMYTELL_NAMESPACE = 'urn:x-cast:com.filmytell.ott.cast';

// Configure Web Receiver Options
const options = new cast.framework.CastReceiverOptions();
options.maxInactivity = 3600; // 1 hour inactivity timeout
options.disableIdleTimeout = false;

// Intercept LOAD request to handle authorization, signed URLs, and custom metadata
playerManager.setMessageInterceptor(
  cast.framework.messages.MessageType.LOAD,
  (loadRequestData) => {
    console.log('[FilmyTell Receiver] LOAD Intercepted:', loadRequestData);
    window.filmytellPlayer.showLoader(true);

    const media = loadRequestData.media;
    if (!media) {
      console.error('[FilmyTell Receiver] No media information in LOAD request');
      return loadRequestData;
    }

    // Extract customData passed from sender (auth token, watermark, session ID, contentId)
    const customData = media.customData || {};
    const authToken = customData.authToken;
    const watermarkText = customData.watermarkText || customData.userIdentifier;

    if (watermarkText) {
      window.filmytellPlayer.setupWatermark(watermarkText);
    }

    // Configure playback request headers if token is present
    const playbackConfig = new cast.framework.PlaybackConfig();
    playbackConfig.manifestRequestHandler = (requestInfo) => {
      requestInfo.withCredentials = true;
      if (authToken) {
        requestInfo.headers = requestInfo.headers || {};
        requestInfo.headers['Authorization'] = `Bearer ${authToken}`;
      }
    };

    playbackConfig.segmentRequestHandler = (requestInfo) => {
      requestInfo.withCredentials = true;
      if (authToken) {
        requestInfo.headers = requestInfo.headers || {};
        requestInfo.headers['Authorization'] = `Bearer ${authToken}`;
      }
    };

    context.setPlaybackConfig(playbackConfig);

    // Set content type to HLS or MP4 as specified
    if (!media.contentType || media.contentType === 'application/octet-stream') {
      if (media.contentUrl && media.contentUrl.includes('.m3u8')) {
        media.contentType = 'application/x-mpegurl';
        media.streamType = cast.framework.messages.StreamType.BUFFERED;
      } else {
        media.contentType = 'video/mp4';
      }
    }

    return loadRequestData;
  }
);

// Listen to media and player state changes
playerManager.addEventListener(
  cast.framework.events.EventType.MEDIA_STATUS,
  (event) => {
    const playerState = (event && event.mediaStatus && event.mediaStatus.playerState)
      || (playerManager.getPlayerState ? playerManager.getPlayerState() : null);
    console.log('[FilmyTell Receiver] Media Status / Player State:', playerState);
    if (!window.filmytellPlayer) return;

    if (
      playerState === cast.framework.messages.PlayerState.PLAYING ||
      playerState === cast.framework.messages.PlayerState.PAUSED
    ) {
      window.filmytellPlayer.showLoader(false);
    } else if (
      playerState === cast.framework.messages.PlayerState.BUFFERING ||
      playerState === cast.framework.messages.PlayerState.LOADING
    ) {
      window.filmytellPlayer.showLoader(true);
    } else if (playerState === cast.framework.messages.PlayerState.IDLE) {
      window.filmytellPlayer.showLoader(false);
      window.filmytellPlayer.clearWatermark();
    }
  }
);

// Listen to player errors
playerManager.addEventListener(
  cast.framework.events.EventType.ERROR,
  (event) => {
    console.error('[FilmyTell Receiver] Playback Error:', event);
    window.filmytellPlayer.showLoader(false);
  }
);

// Custom Message Bus listener for custom sender commands
context.addCustomMessageListener(FILMYTELL_NAMESPACE, (customEvent) => {
  console.log('[FilmyTell Receiver] Custom Message Received:', customEvent);
  const data = customEvent.data;
  if (!data) return;

  if (data.type === 'UPDATE_WATERMARK') {
    window.filmytellPlayer.setupWatermark(data.watermarkText);
  } else if (data.type === 'REFRESH_AUTH_TOKEN') {
    // Handle live token refresh if updated from sender
    console.log('[FilmyTell Receiver] Auth token refreshed from sender');
  }
});

// Start Cast Receiver Context
context.start(options);
console.log('[FilmyTell Receiver] Started CastReceiverContext successfully');
