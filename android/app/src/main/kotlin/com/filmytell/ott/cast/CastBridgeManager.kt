package com.filmytell.ott.cast

import android.app.Activity
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.mediarouter.app.MediaRouteChooserDialogFragment
import androidx.mediarouter.app.MediaRouteControllerDialogFragment
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.images.WebImage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class CastBridgeManager(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val channelName = "com.filmytell.ott/cast"
    private var methodChannel: MethodChannel? = null
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var currentCastSession: CastSession? = null
    private var remoteMediaClient: RemoteMediaClient? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val mediaClientCallback = object : RemoteMediaClient.Callback() {
        override fun onStatusUpdated() {
            notifyMediaState()
        }

        override fun onMetadataUpdated() {
            notifyMediaState()
        }
    }

    private val progressListener = RemoteMediaClient.ProgressListener { progressMs, durationMs ->
        notifyProgress(progressMs, durationMs)
    }

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarting(session: CastSession) {
            notifySessionState("CONNECTING", null)
        }

        override fun onSessionStarted(session: CastSession, sessionId: String) {
            currentCastSession = session
            setupRemoteMediaClient(session)
            notifySessionState("CONNECTED", session.castDevice?.friendlyName)
        }

        override fun onSessionStartFailed(session: CastSession, error: Int) {
            currentCastSession = null
            teardownRemoteMediaClient()
            notifySessionState("DISCONNECTED", null)
        }

        override fun onSessionEnding(session: CastSession) {
            notifySessionState("CONNECTING", null)
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            currentCastSession = null
            teardownRemoteMediaClient()
            notifySessionState("DISCONNECTED", null)
        }

        override fun onSessionResuming(session: CastSession, sessionId: String) {
            notifySessionState("CONNECTING", null)
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            currentCastSession = session
            setupRemoteMediaClient(session)
            notifySessionState("CONNECTED", session.castDevice?.friendlyName)
        }

        override fun onSessionResumeFailed(session: CastSession, error: Int) {
            currentCastSession = null
            teardownRemoteMediaClient()
            notifySessionState("DISCONNECTED", null)
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            notifySessionState("CONNECTING", null)
        }
    }

    fun register(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler(this)

        try {
            castContext = CastContext.getSharedInstance(activity.applicationContext)
            sessionManager = castContext?.sessionManager
            sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)

            currentCastSession = sessionManager?.currentCastSession
            currentCastSession?.let { setupRemoteMediaClient(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Google Cast Context: ${e.message}")
        }
    }

    fun unregister() {
        try {
            sessionManager?.removeSessionManagerListener(sessionManagerListener, CastSession::class.java)
            teardownRemoteMediaClient()
            methodChannel?.setMethodCallHandler(null)
            methodChannel = null
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering CastBridgeManager: ${e.message}")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                result.success(getCurrentStateMap())
            }
            "showCastDialog" -> {
                showNativeCastDialog(result)
            }
            "disconnect" -> {
                disconnect(result)
            }
            "loadMedia" -> {
                val mediaData = call.arguments as? Map<*, *>
                if (mediaData != null) {
                    loadMedia(mediaData, result)
                } else {
                    result.error("INVALID_ARGS", "Missing mediaData map", null)
                }
            }
            "play" -> {
                remoteMediaClient?.play()
                result.success(true)
            }
            "pause" -> {
                remoteMediaClient?.pause()
                result.success(true)
            }
            "seek" -> {
                val positionSeconds = (call.argument<Number>("positionSeconds"))?.toLong() ?: 0L
                remoteMediaClient?.seek(positionSeconds * 1000L)
                result.success(true)
            }
            "stop" -> {
                remoteMediaClient?.stop()
                result.success(true)
            }
            "setVolume" -> {
                val volume = (call.argument<Number>("volume"))?.toDouble() ?: 1.0
                remoteMediaClient?.setStreamVolume(volume)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun showNativeCastDialog(result: MethodChannel.Result) {
        mainHandler.post {
            try {
                val fragmentActivity = activity as? FragmentActivity
                if (fragmentActivity == null) {
                    result.error("NOT_FRAGMENT_ACTIVITY", "Activity is not a FragmentActivity", null)
                    return@post
                }

                val selector = MediaRouteSelector.Builder()
                    .addControlCategory(CastMediaControlIntent.categoryForCast(CastOptionsProvider.APP_ID))
                    .build()

                val router = MediaRouter.getInstance(activity.applicationContext)
                val currentRoute = router.selectedRoute

                if (currentRoute.isDefault || currentRoute.matchesSelector(selector).not()) {
                    val dialog = MediaRouteChooserDialogFragment()
                    dialog.routeSelector = selector
                    dialog.show(fragmentActivity.supportFragmentManager, "MediaRouteChooserDialogFragment")
                } else {
                    val dialog = MediaRouteControllerDialogFragment()
                    dialog.show(fragmentActivity.supportFragmentManager, "MediaRouteControllerDialogFragment")
                }
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error opening Cast dialog: ${e.message}", e)
                result.error("CAST_DIALOG_ERROR", e.message, null)
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        mainHandler.post {
            try {
                sessionManager?.endCurrentSession(true)
                result.success(true)
            } catch (e: Exception) {
                result.error("DISCONNECT_ERROR", e.message, null)
            }
        }
    }

    private fun loadMedia(mediaData: Map<*, *>, result: MethodChannel.Result) {
        val client = remoteMediaClient
        if (client == null) {
            result.error("NO_REMOTE_CLIENT", "No active Cast media client", null)
            return
        }

        try {
            val mediaUrl = (mediaData["mediaUrl"] as? String) ?: ""
            val title = (mediaData["title"] as? String) ?: "FilmyTell"
            val subtitle = mediaData["subtitle"] as? String
            val posterUrl = mediaData["posterUrl"] as? String
            val contentType = (mediaData["contentType"] as? String) ?: "application/x-mpegurl"
            val initialPositionSeconds = (mediaData["initialPositionSeconds"] as? Number)?.toLong() ?: 0L
            val watermarkText = mediaData["watermarkText"] as? String
            val contentId = (mediaData["contentId"] as? Number)?.toInt() ?: 0
            val isSeries = (mediaData["isSeries"] as? Boolean) ?: false
            val seasonId = (mediaData["seasonId"] as? Number)?.toInt()
            val episodeId = (mediaData["episodeId"] as? Number)?.toInt()

            val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)
            metadata.putString(MediaMetadata.KEY_TITLE, title)
            if (!subtitle.isNullOrEmpty()) {
                metadata.putString(MediaMetadata.KEY_SUBTITLE, subtitle)
            }
            if (!posterUrl.isNullOrEmpty()) {
                metadata.addImage(WebImage(Uri.parse(posterUrl)))
            }

            val customJson = JSONObject().apply {
                put("contentId", contentId)
                put("isSeries", isSeries)
                if (seasonId != null) put("seasonId", seasonId)
                if (episodeId != null) put("episodeId", episodeId)
                if (!watermarkText.isNullOrEmpty()) put("watermarkText", watermarkText)
            }

            val mediaInfo = MediaInfo.Builder(mediaUrl)
                .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                .setContentType(contentType)
                .setMetadata(metadata)
                .setCustomData(customJson)
                .build()

            val loadRequest = MediaLoadRequestData.Builder()
                .setMediaInfo(mediaInfo)
                .setCurrentTime(initialPositionSeconds * 1000L)
                .setAutoplay(true)
                .build()

            client.load(loadRequest)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error loading media on Cast client: ${e.message}", e)
            result.error("LOAD_MEDIA_ERROR", e.message, null)
        }
    }

    private fun setupRemoteMediaClient(session: CastSession) {
        teardownRemoteMediaClient()
        remoteMediaClient = session.remoteMediaClient
        remoteMediaClient?.registerCallback(mediaClientCallback)
        remoteMediaClient?.addProgressListener(progressListener, 1000L)
    }

    private fun teardownRemoteMediaClient() {
        remoteMediaClient?.removeProgressListener(progressListener)
        remoteMediaClient?.unregisterCallback(mediaClientCallback)
        remoteMediaClient = null
    }

    private fun notifySessionState(state: String, deviceName: String?) {
        mainHandler.post {
            val payload = mapOf(
                "sessionState" to state,
                "deviceName" to (deviceName ?: currentCastSession?.castDevice?.friendlyName ?: ""),
                "isConnected" to (state == "CONNECTED")
            )
            methodChannel?.invokeMethod("onSessionStateChanged", payload)
        }
    }

    private fun notifyMediaState() {
        mainHandler.post {
            val client = remoteMediaClient ?: return@post
            val isPlaying = client.isPlaying
            val isPaused = client.isPaused
            val isBuffering = client.isBuffering

            val playerState = when {
                isPlaying -> "PLAYING"
                isPaused -> "PAUSED"
                isBuffering -> "BUFFERING"
                else -> "IDLE"
            }

            val durationSeconds = (client.streamDuration / 1000L).coerceAtLeast(0L)
            val positionSeconds = (client.approximateStreamPosition / 1000L).coerceAtLeast(0L)

            val payload = mapOf(
                "playerState" to playerState,
                "positionSeconds" to positionSeconds,
                "durationSeconds" to durationSeconds,
                "isMuted" to (client.mediaStatus?.isMute ?: false)
            )
            methodChannel?.invokeMethod("onMediaStateChanged", payload)
        }
    }

    private fun notifyProgress(progressMs: Long, durationMs: Long) {
        mainHandler.post {
            val payload = mapOf(
                "positionSeconds" to (progressMs / 1000L).coerceAtLeast(0L),
                "durationSeconds" to (durationMs / 1000L).coerceAtLeast(0L)
            )
            methodChannel?.invokeMethod("onProgressUpdated", payload)
        }
    }

    private fun getCurrentStateMap(): Map<String, Any?> {
        val isConnected = currentCastSession?.isConnected == true
        val deviceName = currentCastSession?.castDevice?.friendlyName ?: ""
        val client = remoteMediaClient

        val playerState = when {
            client?.isPlaying == true -> "PLAYING"
            client?.isPaused == true -> "PAUSED"
            client?.isBuffering == true -> "BUFFERING"
            isConnected -> "CONNECTED"
            else -> "DISCONNECTED"
        }

        return mapOf(
            "isConnected" to isConnected,
            "deviceName" to deviceName,
            "playerState" to playerState,
            "positionSeconds" to ((client?.approximateStreamPosition ?: 0L) / 1000L),
            "durationSeconds" to ((client?.streamDuration ?: 0L) / 1000L)
        )
    }

    companion object {
        private const val TAG = "CastBridgeManager"
    }
}
