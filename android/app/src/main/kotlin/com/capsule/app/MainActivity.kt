package com.capsule.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.net.Uri
import android.provider.MediaStore
import android.os.Handler
import android.os.Looper

import androidx.mediarouter.app.MediaRouteChooserDialogFragment
import androidx.fragment.app.DialogFragment
import androidx.mediarouter.media.MediaRouteSelector

import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaQueueItem
import com.google.android.gms.cast.MediaStatus
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.images.WebImage
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import org.json.JSONObject

class MainActivity: FlutterFragmentActivity() {

    private val CHROMECAST_CHANNEL = "com.capsule.app/chromecast"
    private val CHROMECAST_EVENTS_CHANNEL = "com.capsule.app/chromecast_events"

    // ✅ New channel for MediaStore lookup
    private val MEDIA_STORE_CHANNEL = "com.capsule.app/media_store"

    private var castContext: CastContext? = null
    private var castSession: CastSession? = null
    private var remoteMediaClient: RemoteMediaClient? = null
    private var methodChannel: MethodChannel? = null
    private val castDialogTag = "capsule_cast_dialog"

    // Real-time Cast status stream (to Flutter)
    private var castEventsSink: EventChannel.EventSink? = null
    private var remoteMediaClientCallback: RemoteMediaClient.Callback? = null
    private var remoteMediaProgressListener: RemoteMediaClient.ProgressListener? = null
    private var lastCastEventAtMs: Long = 0L
    private var lastCastEventKey: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // Ensure we always log the real crash cause before any 3rd-party crash handler
        // terminates the process (some OEMs/SDKs can obscure the original stacktrace).
        try {
            val previous = Thread.getDefaultUncaughtExceptionHandler()
            Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
                try {
                    Log.e("CapsuleUncaught", "Uncaught exception on thread=${thread.name}", throwable)
                } catch (_: Throwable) {}

                // Best-effort: surface this back to Flutter as a cast error.
                try {
                    methodChannel?.invokeMethod(
                        "onCastError",
                        "Android crash: ${throwable.javaClass.simpleName}: ${throwable.message}"
                    )
                } catch (_: Throwable) {}

                previous?.uncaughtException(thread, throwable)
            }
        } catch (_: Throwable) {}
    }

    private fun ensureGooglePlayServicesOrNotify(): Boolean {
        return try {
            val status = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(this)
            val ok = status == ConnectionResult.SUCCESS
            if (!ok) {
                Log.e("Chromecast", "Google Play Services not available (status=$status)")
                methodChannel?.invokeMethod(
                    "onCastError",
                    "Chromecast unavailable on this device (Google Play Services missing)"
                )
            }
            ok
        } catch (t: Throwable) {
            Log.e("Chromecast", "Play Services check failed: ${t.message}")
            false
        }
    }

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            castSession = session
            remoteMediaClient = session.remoteMediaClient
            attachRemoteMediaClient(session.remoteMediaClient)

            runOnUiThread {
                methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                    "isConnected" to true,
                    "deviceName" to session.castDevice?.friendlyName
                ))
            }

            Log.d("Chromecast", "Session started with ${session.castDevice?.friendlyName}")
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            castSession = session
            remoteMediaClient = session.remoteMediaClient
            attachRemoteMediaClient(session.remoteMediaClient)

            runOnUiThread {
                methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                    "isConnected" to true,
                    "deviceName" to session.castDevice?.friendlyName
                ))
            }
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            castSession = null
            remoteMediaClient = null
            detachRemoteMediaClient()

            runOnUiThread {
                methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                    "isConnected" to false,
                    "deviceName" to null
                ))
            }

            Log.d("Chromecast", "Session ended")
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            Log.d("Chromecast", "Session suspended")
        }

        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionStartFailed(session: CastSession, error: Int) {
            runOnUiThread {
                methodChannel?.invokeMethod("onCastError", "Failed to start casting session")
            }
        }
        override fun onSessionEnding(session: CastSession) {}
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionResumeFailed(session: CastSession, error: Int) {}
    }

    private fun showCastChooserDialog(attempt: Int = 0) {
        try {
            Log.d("Chromecast", "Opening Cast chooser dialog… (attempt=$attempt)")
            if (!ensureGooglePlayServicesOrNotify()) return
            // Avoid IllegalStateException when activity state is already saved.
            val fm = supportFragmentManager
            if (fm.isStateSaved) {
                // This can happen if the user taps during/around activity resume, or while
                // Flutter is doing a route transition. Retry a few times instead of no-oping.
                Log.w("Chromecast", "FragmentManager state is saved; delaying Cast dialog show")
                if (attempt < 6) {
                    Handler(Looper.getMainLooper()).postDelayed(
                        { showCastChooserDialog(attempt + 1) },
                        120L
                    )
                } else {
                    methodChannel?.invokeMethod("onCastError", "Cannot open Cast dialog right now")
                }
                return
            }

            val ctx = castContext ?: CastContext.getSharedInstance(this).also { castContext = it }
            // Some devices/SDK combos can return a null/empty mergedSelector even when Cast is configured.
            // Build an explicit selector from the receiver app id as a robust fallback.
            val merged = ctx.mergedSelector
            val selector: MediaRouteSelector = if (merged != null) {
                merged
            } else {
                val appId = try {
                    ctx.castOptions.receiverApplicationId
                } catch (_: Throwable) {
                    CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
                }

                MediaRouteSelector.Builder()
                    .addControlCategory(CastMediaControlIntent.categoryForCast(appId))
                    .build()
            }

            // If we have a stale dialog fragment (e.g., it was dismissed but not removed),
            // returning here makes taps look like "nothing happens".
            val existing = fm.findFragmentByTag(castDialogTag)
            if (existing != null) {
                Log.w(
                    "Chromecast",
                    "Existing Cast dialog fragment found (${existing::class.java.simpleName}); removing and recreating"
                )
                try { (existing as? DialogFragment)?.dismissAllowingStateLoss() } catch (_: Throwable) {}
                try { fm.beginTransaction().remove(existing).commitNowAllowingStateLoss() } catch (_: Throwable) {}
            }

            val dialog = MediaRouteChooserDialogFragment()
            dialog.setRouteSelector(selector)
            // IMPORTANT:
            // Some OEM ROMs (notably MIUI) crash if the dialog background is translucent/transparent.
            // Force an opaque theme to prevent:
            //   IllegalArgumentException: background can not be translucent: #0
            dialog.setStyle(DialogFragment.STYLE_NORMAL, R.style.CapsuleCastDialogTheme)

            // Use showNow() so exceptions happen inside this try/catch (vs async commit in show()).
            dialog.showNow(fm, castDialogTag)
            Log.d("Chromecast", "✅ Cast chooser dialog shown")
        } catch (t: Throwable) {
            Log.e("Chromecast", "Show cast dialog error: ${t.message}", t)
            methodChannel?.invokeMethod("onCastError", "Failed to open Cast dialog")
        }
    }

    private fun emitCastStatus(status: Map<String, Any?>) {
        try {
            val now = System.currentTimeMillis()
            // Deduplicate identical events in a short window (avoid spamming Flutter)
            val key = buildCastEventKey(status)
            val lastAt = lastCastEventAtMs
            if (lastCastEventKey == key && (now - lastAt) < 120L) {
                return
            }
            lastCastEventKey = key
            lastCastEventAtMs = now

            runOnUiThread {
                castEventsSink?.success(status)
            }
        } catch (_: Throwable) {}
    }

    private fun buildCastEventKey(status: Map<String, Any?>): String {
        val idx = status["index"]?.toString() ?: ""
        val isPlaying = status["isPlaying"]?.toString() ?: ""
        val storyId = status["storyId"]?.toString() ?: ""
        val mediaUrl = status["mediaUrl"]?.toString() ?: ""
        val pos = status["positionMs"]?.toString() ?: ""
        val dur = status["durationMs"]?.toString() ?: ""
        return "$idx|$isPlaying|$storyId|$mediaUrl|$pos|$dur"
    }

    private fun buildPlaybackStatusMap(
        session: CastSession?,
        client: RemoteMediaClient?,
        positionMsOverride: Long? = null,
        durationMsOverride: Long? = null
    ): Map<String, Any?> {
        try {
            if (session == null || client == null) {
                return mapOf(
                    "isConnected" to false,
                    "deviceName" to null,
                    "isPlaying" to false,
                    "positionMs" to 0L,
                    "durationMs" to 0L,
                    "imageDurationMs" to 0L,
                    "mediaUrl" to null,
                    "storyId" to null,
                    "playerState" to null,
                    "idleReason" to null,
                    "index" to null,
                    "total" to null
                )
            }

            val status = client.mediaStatus
            val playerState = status?.playerState
            val idleReason = status?.idleReason
            val isPlaying = playerState == MediaStatus.PLAYER_STATE_PLAYING

            var positionMs = positionMsOverride ?: client.approximateStreamPosition
            var durationMs = durationMsOverride ?: client.streamDuration

            val currentItemId = status?.currentItemId ?: 0
            val queueItems = status?.queueItems

            var index: Int? = null
            var total: Int? = null
            var imageDurationMs: Long = 0L
            var storyId: String? = null
            val mediaUrl: String? = try { status?.mediaInfo?.contentId } catch (_: Throwable) { null }

            try {
                if (queueItems != null) {
                    total = queueItems.size
                    if (currentItemId != 0) {
                        val idxFound = queueItems.indexOfFirst { it.itemId == currentItemId }
                        if (idxFound >= 0) index = idxFound
                    }

                    val cur = if (index != null && index!! >= 0 && index!! < queueItems.size) queueItems[index!!] else null
                    val custom = cur?.media?.customData ?: status?.mediaInfo?.customData
                    if (custom != null) {
                        if (custom.has("index")) index = custom.optInt("index")
                        if (custom.has("total")) total = custom.optInt("total")
                        if (custom.has("storyId")) storyId = custom.optString("storyId", null)
                        if (custom.has("imageDurationSeconds")) {
                            val seconds = custom.optInt("imageDurationSeconds", 0)
                            if (seconds > 0) imageDurationMs = (seconds.toLong() * 1000L)
                        }
                    }
                } else {
                    val custom = status?.mediaInfo?.customData
                    if (custom != null) {
                        if (custom.has("index")) index = custom.optInt("index")
                        if (custom.has("total")) total = custom.optInt("total")
                        if (custom.has("storyId")) storyId = custom.optString("storyId", null)
                        if (custom.has("imageDurationSeconds")) {
                            val seconds = custom.optInt("imageDurationSeconds", 0)
                            if (seconds > 0) imageDurationMs = (seconds.toLong() * 1000L)
                        }
                    }
                }
            } catch (_: Throwable) {}

            if (durationMs <= 0L && imageDurationMs > 0L) {
                durationMs = imageDurationMs
            }
            if (positionMs < 0L) positionMs = 0L

            return mapOf(
                "isConnected" to true,
                "deviceName" to session.castDevice?.friendlyName,
                "isPlaying" to isPlaying,
                "positionMs" to positionMs,
                "durationMs" to durationMs,
                "imageDurationMs" to imageDurationMs,
                "mediaUrl" to mediaUrl,
                "storyId" to storyId,
                "playerState" to playerState,
                "idleReason" to idleReason,
                "index" to index,
                "total" to total
            )
        } catch (_: Throwable) {
            return mapOf(
                "isConnected" to (session != null && client != null),
                "deviceName" to session?.castDevice?.friendlyName,
                "isPlaying" to false,
                "positionMs" to 0L,
                "durationMs" to 0L,
                "imageDurationMs" to 0L,
                "mediaUrl" to null,
                "storyId" to null,
                "playerState" to null,
                "idleReason" to null,
                "index" to null,
                "total" to null
            )
        }
    }

    private fun attachRemoteMediaClient(client: RemoteMediaClient?) {
        try {
            detachRemoteMediaClient()
            val c = client ?: return

            // Callback fires on status/queue changes (index changes, play/pause, etc.)
            val cb = object : RemoteMediaClient.Callback() {
                override fun onStatusUpdated() {
                    emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient))
                }

                override fun onQueueStatusUpdated() {
                    emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient))
                }

                override fun onMetadataUpdated() {
                    emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient))
                }
            }
            remoteMediaClientCallback = cb
            c.registerCallback(cb)

            // Progress listener gives near real-time position/duration updates.
            val pl = RemoteMediaClient.ProgressListener { progressMs, durationMs ->
                emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient, progressMs, durationMs))
            }
            remoteMediaProgressListener = pl
            c.addProgressListener(pl, 250)

            // Emit an initial status snapshot
            emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient))
        } catch (_: Throwable) {}
    }

    private fun detachRemoteMediaClient() {
        try {
            val c = remoteMediaClient
            val cb = remoteMediaClientCallback
            if (c != null && cb != null) {
                try { c.unregisterCallback(cb) } catch (_: Throwable) {}
            }
            remoteMediaClientCallback = null

            val pl = remoteMediaProgressListener
            if (c != null && pl != null) {
                try { c.removeProgressListener(pl) } catch (_: Throwable) {}
            }
            remoteMediaProgressListener = null
        } catch (_: Throwable) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // =========================
        // Chromecast channel (unchanged)
        // =========================
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHROMECAST_CHANNEL)

        // =========================
        // Chromecast events channel (real-time playback status)
        // =========================
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHROMECAST_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    castEventsSink = events
                    emitCastStatus(buildPlaybackStatusMap(castSession, remoteMediaClient))
                }

                override fun onCancel(arguments: Any?) {
                    castEventsSink = null
                }
            })
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    runOnUiThread {
                        try {
                            if (!ensureGooglePlayServicesOrNotify()) {
                                result.error(
                                    "PLAY_SERVICES_MISSING",
                                    "Google Play Services required for Chromecast",
                                    null
                                )
                            } else {
                                castContext = CastContext.getSharedInstance(this)
                                castContext?.sessionManager?.addSessionManagerListener(
                                    sessionManagerListener,
                                    CastSession::class.java
                                )
                                Log.d("Chromecast", "✅ Chromecast initialized successfully")
                                result.success(true)
                            }
                        } catch (t: Throwable) {
                            Log.e("Chromecast", "❌ Initialization failed: ${t.message}")
                            result.error("INIT_ERROR", t.message, null)
                        }
                    }
                }

                "startDiscovery" -> {
                    // Cast discovery is managed by the MediaRouter + Cast SDK.
                    // We keep this method for compatibility with Flutter code.
                    Log.d("Chromecast", "Discovery requested (handled by Cast SDK)")
                    result.success(true)
                }

                "stopDiscovery" -> {
                    result.success(true)
                }

                "connect" -> {
                    // In Cast SDK, device selection should be driven by the Cast dialog.
                    // We keep this method for backward compatibility with Flutter code.
                    runOnUiThread { showCastChooserDialog() }
                    result.success(true)
                }

                "showCastDialog" -> {
                    runOnUiThread { showCastChooserDialog() }
                    result.success(true)
                }

                "disconnect" -> {
                    runOnUiThread {
                        try {
                            castContext?.sessionManager?.endCurrentSession(true)
                            Log.d("Chromecast", "Disconnected from Chromecast")
                            result.success(true)
                        } catch (t: Throwable) {
                            Log.e("Chromecast", "Disconnect error: ${t.message}")
                            result.error("DISCONNECT_ERROR", t.message, null)
                        }
                    }
                }

                "castMedia" -> {
                    val mediaUrl = call.argument<String>("mediaUrl")
                    val mediaType = call.argument<String>("mediaType")
                    val title = call.argument<String>("title") ?: "Capsule Memory"
                    val description = call.argument<String>("description") ?: ""
                    val thumbnailUrl = call.argument<String>("thumbnailUrl")

                    if (mediaUrl == null) {
                        result.error("INVALID_ARGS", "Media URL is required", null)
                        return@setMethodCallHandler
                    }

                    runOnUiThread {
                        try {
                            if (!ensureGooglePlayServicesOrNotify()) {
                                result.error(
                                    "PLAY_SERVICES_MISSING",
                                    "Google Play Services required for Chromecast",
                                    null
                                )
                            } else {
                                val metadata = MediaMetadata(
                                    if (mediaType == "video") MediaMetadata.MEDIA_TYPE_MOVIE
                                    else MediaMetadata.MEDIA_TYPE_PHOTO
                                )
                                metadata.putString(MediaMetadata.KEY_TITLE, title)
                                metadata.putString(MediaMetadata.KEY_SUBTITLE, description)

                                if (thumbnailUrl != null) {
                                    try { metadata.addImage(WebImage(Uri.parse(thumbnailUrl))) } catch (_: Throwable) {}
                                }

                                val contentType = if (mediaType == "video") "video/mp4" else "image/jpeg"
                                val mediaInfo = MediaInfo.Builder(mediaUrl)
                                    .setContentType(contentType)
                                    .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                                    .setMetadata(metadata)
                                    .build()

                                val request = MediaLoadRequestData.Builder()
                                    .setMediaInfo(mediaInfo)
                                    .setAutoplay(true)
                                    .build()

                                val client = remoteMediaClient
                                if (client == null) {
                                    result.error("NO_SESSION", "No active casting session", null)
                                } else {
                                    client.load(request).setResultCallback { mediaChannelResult ->
                                        runOnUiThread {
                                            if (mediaChannelResult.status.isSuccess) {
                                                Log.d("Chromecast", "✅ Media loaded successfully")
                                                result.success(true)
                                            } else {
                                                Log.e("Chromecast", "❌ Failed to load media")
                                                result.error("CAST_ERROR", "Failed to load media", null)
                                            }
                                        }
                                    }
                                }
                            }
                        } catch (t: Throwable) {
                            Log.e("Chromecast", "Cast error: ${t.message}")
                            result.error("CAST_ERROR", t.message, null)
                        }
                    }
                }

                "castQueue" -> {
                    val args = call.arguments as? Map<*, *>
                    val itemsRaw = args?.get("items") as? List<*>
                    val startIndexRaw = args?.get("startIndex")

                    if (itemsRaw == null || itemsRaw.isEmpty()) {
                        result.error("INVALID_ARGS", "Queue items are required", null)
                        return@setMethodCallHandler
                    }

                    val startIndex = when (startIndexRaw) {
                        is Int -> startIndexRaw
                        is Number -> startIndexRaw.toInt()
                        is String -> startIndexRaw.toIntOrNull() ?: 0
                        else -> 0
                    }.coerceIn(0, itemsRaw.size - 1)

                    runOnUiThread {
                        val client = remoteMediaClient
                        if (client == null) {
                            result.error("NO_SESSION", "No active casting session", null)
                        } else {
                            try {
                                val queueItems = itemsRaw.mapNotNull { raw ->
                                    val m = raw as? Map<*, *> ?: return@mapNotNull null
                                    val mediaUrl = (m["mediaUrl"] as? String)?.trim().orEmpty()
                                    if (mediaUrl.isEmpty()) return@mapNotNull null

                                    val contentType = (m["contentType"] as? String)?.trim()
                                        .takeUnless { it.isNullOrEmpty() } ?: "video/mp4"
                                    val title = (m["title"] as? String) ?: "Capsule"
                                    val subtitle = (m["subtitle"] as? String) ?: ""
                                    val thumbnailUrl = (m["thumbnailUrl"] as? String)?.trim()
                                        .takeUnless { it.isNullOrEmpty() }
                                    val avatarUrl = (m["avatarUrl"] as? String)?.trim()
                                        .takeUnless { it.isNullOrEmpty() }
                                    val mediaType = (m["mediaType"] as? String)?.trim()?.lowercase() ?: ""

                                    val metadata = MediaMetadata(
                                        if (mediaType == "image") MediaMetadata.MEDIA_TYPE_PHOTO else MediaMetadata.MEDIA_TYPE_MOVIE
                                    )
                                    metadata.putString(MediaMetadata.KEY_TITLE, title)
                                    metadata.putString(MediaMetadata.KEY_SUBTITLE, subtitle)
                                    if (thumbnailUrl != null) {
                                        try { metadata.addImage(WebImage(Uri.parse(thumbnailUrl))) } catch (_: Throwable) {}
                                    }
                                    if (avatarUrl != null && avatarUrl != thumbnailUrl) {
                                        try { metadata.addImage(WebImage(Uri.parse(avatarUrl))) } catch (_: Throwable) {}
                                    }

                                    val mediaInfoBuilder = MediaInfo.Builder(mediaUrl)
                                        .setContentType(contentType)
                                        .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                                        .setMetadata(metadata)

                                    val customData = m["customData"] as? Map<*, *>
                                    if (customData != null) {
                                        try { mediaInfoBuilder.setCustomData(JSONObject(customData)) } catch (_: Throwable) {}
                                    }

                                    val mediaInfo = mediaInfoBuilder.build()
                                    MediaQueueItem.Builder(mediaInfo)
                                        .setAutoplay(true)
                                        .build()
                                }.toTypedArray()

                                if (queueItems.isEmpty()) {
                                    result.error("INVALID_ARGS", "No valid queue items", null)
                                } else {
                                    client.queueLoad(
                                        queueItems,
                                        startIndex,
                                        MediaStatus.REPEAT_MODE_REPEAT_OFF,
                                        JSONObject()
                                    ).setResultCallback { r ->
                                        runOnUiThread {
                                            if (r.status.isSuccess) {
                                                result.success(true)
                                            } else {
                                                result.error("CAST_ERROR", "Failed to load queue", null)
                                            }
                                        }
                                    }
                                }
                            } catch (t: Throwable) {
                                Log.e("Chromecast", "castQueue error: ${t.message}")
                                result.error("CAST_ERROR", t.message, null)
                            }
                        }
                    }
                }

                "play" -> {
                    runOnUiThread {
                        try { remoteMediaClient?.play(); result.success(null) }
                        catch (e: Exception) { result.error("PLAY_ERROR", e.message, null) }
                    }
                }

                "pause" -> {
                    runOnUiThread {
                        try { remoteMediaClient?.pause(); result.success(null) }
                        catch (e: Exception) { result.error("PAUSE_ERROR", e.message, null) }
                    }
                }

                "queueNext" -> {
                    runOnUiThread {
                        try { remoteMediaClient?.queueNext(null); result.success(null) }
                        catch (e: Exception) { result.error("QUEUE_NEXT_ERROR", e.message, null) }
                    }
                }

                "queuePrev" -> {
                    runOnUiThread {
                        try { remoteMediaClient?.queuePrev(null); result.success(null) }
                        catch (e: Exception) { result.error("QUEUE_PREV_ERROR", e.message, null) }
                    }
                }

                "stop" -> {
                    runOnUiThread {
                        try { remoteMediaClient?.stop(); result.success(null) }
                        catch (e: Exception) { result.error("STOP_ERROR", e.message, null) }
                    }
                }

                "seek" -> {
                    val position = call.argument<Double>("position")
                    if (position != null) {
                        runOnUiThread {
                            try {
                                remoteMediaClient?.seek((position * 1000).toLong())
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("SEEK_ERROR", e.message, null)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "Position is required", null)
                    }
                }

                "setVolume" -> {
                    val volume = call.argument<Double>("volume")
                    if (volume != null) {
                        runOnUiThread {
                            try {
                                remoteMediaClient?.setStreamVolume(volume)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("VOLUME_ERROR", e.message, null)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "Volume is required", null)
                    }
                }

                "getPlaybackStatus" -> {
                    try {
                        val session = castSession
                        val client = remoteMediaClient
                        result.success(buildPlaybackStatusMap(session, client))
                    } catch (t: Throwable) {
                        result.error("STATUS_ERROR", t.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // =========================
        // ✅ MediaStore channel (new)
        // =========================
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_STORE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDateTaken" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrBlank()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }

                        try {
                            val uri = Uri.parse(uriStr)

                            // Prefer DATE_TAKEN (ms since epoch), then DATE_ADDED (seconds)
                            val projection = arrayOf(
                                MediaStore.Images.ImageColumns.DATE_TAKEN,
                                MediaStore.MediaColumns.DATE_ADDED
                            )

                            contentResolver.query(uri, projection, null, null, null)?.use { c ->
                                if (c.moveToFirst()) {
                                    val idxTaken = c.getColumnIndex(MediaStore.Images.ImageColumns.DATE_TAKEN)
                                    if (idxTaken >= 0) {
                                        val taken = c.getLong(idxTaken)
                                        if (taken > 0L) {
                                            result.success(taken)
                                            return@setMethodCallHandler
                                        }
                                    }

                                    val idxAdded = c.getColumnIndex(MediaStore.MediaColumns.DATE_ADDED)
                                    if (idxAdded >= 0) {
                                        val addedSec = c.getLong(idxAdded)
                                        if (addedSec > 0L) {
                                            result.success(addedSec * 1000L)
                                            return@setMethodCallHandler
                                        }
                                    }
                                }
                            }

                            result.success(null)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        detachRemoteMediaClient()
        castContext?.sessionManager?.removeSessionManagerListener(
            sessionManagerListener,
            CastSession::class.java
        )
    }
}