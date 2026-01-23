package com.capsule.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.net.Uri
import android.provider.MediaStore

import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.images.WebImage

class MainActivity: FlutterActivity() {

    private val CHROMECAST_CHANNEL = "com.capsule.app/chromecast"

    // ✅ New channel for MediaStore lookup
    private val MEDIA_STORE_CHANNEL = "com.capsule.app/media_store"

    private var castContext: CastContext? = null
    private var castSession: CastSession? = null
    private var remoteMediaClient: RemoteMediaClient? = null
    private var methodChannel: MethodChannel? = null

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            castSession = session
            remoteMediaClient = session.remoteMediaClient

            methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                "isConnected" to true,
                "deviceName" to session.castDevice?.friendlyName
            ))

            Log.d("Chromecast", "Session started with ${session.castDevice?.friendlyName}")
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            castSession = session
            remoteMediaClient = session.remoteMediaClient

            methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                "isConnected" to true,
                "deviceName" to session.castDevice?.friendlyName
            ))
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            castSession = null
            remoteMediaClient = null

            methodChannel?.invokeMethod("onConnectionStateChanged", mapOf(
                "isConnected" to false,
                "deviceName" to null
            ))

            Log.d("Chromecast", "Session ended")
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            Log.d("Chromecast", "Session suspended")
        }

        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionStartFailed(session: CastSession, error: Int) {
            methodChannel?.invokeMethod("onCastError", "Failed to start casting session")
        }
        override fun onSessionEnding(session: CastSession) {}
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionResumeFailed(session: CastSession, error: Int) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // =========================
        // Chromecast channel (unchanged)
        // =========================
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHROMECAST_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    try {
                        castContext = CastContext.getSharedInstance(this)
                        castContext?.sessionManager?.addSessionManagerListener(
                            sessionManagerListener,
                            CastSession::class.java
                        )
                        Log.d("Chromecast", "✅ Chromecast initialized successfully")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("Chromecast", "❌ Initialization failed: ${e.message}")
                        result.error("INIT_ERROR", e.message, null)
                    }
                }

                "startDiscovery" -> {
                    Log.d("Chromecast", "Discovery is automatic")
                    result.success(true)
                }

                "stopDiscovery" -> {
                    result.success(true)
                }

                "connect" -> {
                    result.success(true)
                }

                "disconnect" -> {
                    try {
                        castContext?.sessionManager?.endCurrentSession(true)
                        Log.d("Chromecast", "Disconnected from Chromecast")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("Chromecast", "Disconnect error: ${e.message}")
                        result.error("DISCONNECT_ERROR", e.message, null)
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

                    try {
                        val metadata = MediaMetadata(
                            if (mediaType == "video") MediaMetadata.MEDIA_TYPE_MOVIE
                            else MediaMetadata.MEDIA_TYPE_PHOTO
                        )
                        metadata.putString(MediaMetadata.KEY_TITLE, title)
                        metadata.putString(MediaMetadata.KEY_SUBTITLE, description)

                        if (thumbnailUrl != null) {
                            metadata.addImage(WebImage(Uri.parse(thumbnailUrl)))
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

                        remoteMediaClient?.load(request)?.setResultCallback { mediaChannelResult ->
                            if (mediaChannelResult.status.isSuccess) {
                                Log.d("Chromecast", "✅ Media loaded successfully")
                                result.success(true)
                            } else {
                                Log.e("Chromecast", "❌ Failed to load media")
                                result.error("CAST_ERROR", "Failed to load media", null)
                            }
                        }

                        if (remoteMediaClient == null) {
                            result.error("NO_SESSION", "No active casting session", null)
                        }
                    } catch (e: Exception) {
                        Log.e("Chromecast", "Cast error: ${e.message}")
                        result.error("CAST_ERROR", e.message, null)
                    }
                }

                "play" -> {
                    try { remoteMediaClient?.play(); result.success(null) }
                    catch (e: Exception) { result.error("PLAY_ERROR", e.message, null) }
                }

                "pause" -> {
                    try { remoteMediaClient?.pause(); result.success(null) }
                    catch (e: Exception) { result.error("PAUSE_ERROR", e.message, null) }
                }

                "stop" -> {
                    try { remoteMediaClient?.stop(); result.success(null) }
                    catch (e: Exception) { result.error("STOP_ERROR", e.message, null) }
                }

                "seek" -> {
                    val position = call.argument<Double>("position")
                    if (position != null) {
                        try {
                            remoteMediaClient?.seek((position * 1000).toLong())
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SEEK_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Position is required", null)
                    }
                }

                "setVolume" -> {
                    val volume = call.argument<Double>("volume")
                    if (volume != null) {
                        try {
                            remoteMediaClient?.setStreamVolume(volume)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Volume is required", null)
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
        castContext?.sessionManager?.removeSessionManagerListener(
            sessionManagerListener,
            CastSession::class.java
        )
    }
}