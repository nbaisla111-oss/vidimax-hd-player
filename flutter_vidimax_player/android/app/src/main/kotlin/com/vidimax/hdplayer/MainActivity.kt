package com.vidimax.hdplayer

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import android.util.Rational
import android.util.Size
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.vidimax.player/system_controls"
        private const val ACTION_PIP_CONTROL = "com.vidimax.hdplayer.ACTION_PIP_CONTROL"
        private const val EXTRA_CONTROL_TYPE = "control_type"
        private const val CONTROL_PREV = "prev"
        private const val CONTROL_TOGGLE = "toggle"
        private const val CONTROL_NEXT = "next"
    }

    private var methodChannel: MethodChannel? = null
    private var isPlayerActive = false
    private var isVideoPlaying = false
    private var lastAspectWidth = 16
    private var lastAspectHeight = 9
    private val mediaWorker = Executors.newCachedThreadPool()

    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_PIP_CONTROL) return
            val control = intent.getStringExtra(EXTRA_CONTROL_TYPE) ?: return
            methodChannel?.invokeMethod("onPipAction", control)
        }
    }

    private val mediaActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != MediaPlaybackService.ACTION_MEDIA_EVENT) return
            val event = intent.getStringExtra(MediaPlaybackService.EXTRA_EVENT) ?: return
            methodChannel?.invokeMethod("onMediaAction", event)
        }
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MediaPlaybackService.actionListener = { event ->
            runOnUiThread {
                methodChannel?.invokeMethod("onMediaAction", event)
            }
        }
        val pipFilter = IntentFilter(ACTION_PIP_CONTROL)
        val mediaFilter = IntentFilter(MediaPlaybackService.ACTION_MEDIA_EVENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, pipFilter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(mediaActionReceiver, mediaFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipActionReceiver, pipFilter)
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(mediaActionReceiver, mediaFilter)
        }
    }

    override fun onStop() {
        super.onStop()
        if (isPlayerActive) {
            val layout = window.attributes
            if (layout.screenBrightness != WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE) {
                layout.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                window.attributes = layout
            }
            methodChannel?.invokeMethod("onPlayerBackgrounded", null)
        }
    }

    override fun onDestroy() {
        MediaPlaybackService.actionListener = null
        try {
            unregisterReceiver(pipActionReceiver)
        } catch (_: Exception) {
        }
        try {
            unregisterReceiver(mediaActionReceiver)
        } catch (_: Exception) {
        }
        try {
            mediaWorker.shutdownNow()
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenBrightness" -> {
                    val current = window.attributes.screenBrightness
                    val effective = if (current >= 0f) {
                        current.toDouble().coerceIn(0.02, 1.0)
                    } else {
                        try {
                            val sys = Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS)
                            (sys.toDouble() / 255.0).coerceIn(0.05, 1.0)
                        } catch (_: Exception) {
                            0.5
                        }
                    }
                    result.success(effective)
                }
                "setScreenBrightness" -> {
                    val brightness = call.argument<Double>("brightness")?.toFloat() ?: -1.0f
                    val layout = window.attributes
                    layout.screenBrightness = brightness.coerceIn(0.02f, 1.0f)
                    window.attributes = layout
                    result.success(true)
                }
                "resetScreenBrightness" -> {
                    val layout = window.attributes
                    layout.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = layout
                    result.success(true)
                }
                "getMediaVolume" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    result.success(current.toDouble() / max.toDouble())
                }
                "setMediaVolume" -> {
                    val targetFraction = (call.argument<Double>("volume") ?: 0.5).coerceIn(0.0, 1.0)
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    val targetStep = Math.round(targetFraction * max).toInt().coerceIn(0, max)
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetStep, 0)
                    val actual = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max.toDouble()
                    result.success(actual)
                }
                "setOrientationMode" -> {
                    val mode = call.argument<String>("mode") ?: "auto"
                    requestedOrientation = when (mode) {
                        "landscape" -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                        "portrait" -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
                        else -> ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                    }
                    result.success(true)
                }
                "getAudioArtwork" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    mediaWorker.execute {
                        val artBytes = extractAudioArtworkBytes(path)
                        runOnUiThread { result.success(artBytes) }
                    }
                }
                "getVideoMetadata" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    mediaWorker.execute {
                        val meta = extractVideoDisplayMetadata(path)
                        runOnUiThread { result.success(meta) }
                    }
                }
                "getVideosMediaInfo" -> {
                    val paths = call.argument<List<String>>("paths") ?: emptyList()
                    mediaWorker.execute {
                        val infoMap = extractVideosMediaInfoBatch(paths)
                        runOnUiThread { result.success(infoMap) }
                    }
                }
                "getAudiosMediaInfo" -> {
                    val paths = call.argument<List<String>>("paths") ?: emptyList()
                    mediaWorker.execute {
                        val infoMap = extractAudiosMediaInfoBatch(paths)
                        runOnUiThread { result.success(infoMap) }
                    }
                }
                "updateMediaNotification" -> {
                    val title = call.argument<String>("title") ?: "Rox Player"
                    val subtitle = call.argument<String>("subtitle") ?: "Playing media"
                    val path = call.argument<String>("path") ?: ""
                    val mediaType = call.argument<String>("mediaType") ?: "audio"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 0L
                    val positionMs = (call.argument<Number>("positionMs"))?.toLong() ?: 0L

                    val serviceIntent = Intent(this, MediaPlaybackService::class.java).apply {
                        action = MediaPlaybackService.ACTION_UPDATE
                        putExtra(MediaPlaybackService.EXTRA_TITLE, title)
                        putExtra(MediaPlaybackService.EXTRA_SUBTITLE, subtitle)
                        putExtra(MediaPlaybackService.EXTRA_PATH, path)
                        putExtra(MediaPlaybackService.EXTRA_MEDIA_TYPE, mediaType)
                        putExtra(MediaPlaybackService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(MediaPlaybackService.EXTRA_DURATION_MS, durationMs)
                        putExtra(MediaPlaybackService.EXTRA_POSITION_MS, positionMs)
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "clearMediaNotification" -> {
                    try {
                        stopService(Intent(this, MediaPlaybackService::class.java))
                    } catch (_: Exception) {
                    }
                    result.success(true)
                }
                "setPipPlayerState" -> {
                    isPlayerActive = call.argument<Boolean>("active") ?: false
                    isVideoPlaying = call.argument<Boolean>("playing") ?: false
                    lastAspectWidth = call.argument<Int>("width") ?: 16
                    lastAspectHeight = call.argument<Int>("height") ?: 9
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode) {
                        updatePipParams()
                    }
                    result.success(true)
                }
                "enterPipMode" -> {
                    isPlayerActive = true
                    isVideoPlaying = call.argument<Boolean>("playing") ?: true
                    lastAspectWidth = call.argument<Int>("width") ?: 16
                    lastAspectHeight = call.argument<Int>("height") ?: 9
                    val entered = triggerPictureInPicture()
                    result.success(entered)
                }
                "isPipSupported" -> {
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                    result.success(supported)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractAudioArtworkBytes(path: String): ByteArray? {
        val file = File(path)
        if (!file.exists()) return null

        var rawBytes: ByteArray? = null
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            rawBytes = retriever.embeddedPicture
        } catch (_: Exception) {
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        // Fallback to MediaStore thumbnail if embeddedPicture wasn't directly returned
        if (rawBytes == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val projection = arrayOf(
                    MediaStore.Audio.Media._ID,
                    MediaStore.Audio.Media.ALBUM_ID
                )
                @Suppress("DEPRECATION")
                val selection = "${MediaStore.Audio.Media.DATA} = ?"
                contentResolver.query(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    arrayOf(path),
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val audioId = cursor.getLong(0)
                        val albumId = cursor.getLong(1)
                        val audioUri = ContentUris.withAppendedId(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                            audioId
                        )
                        var bmp: Bitmap? = try {
                            contentResolver.loadThumbnail(audioUri, Size(320, 320), null)
                        } catch (_: Exception) {
                            null
                        }
                        if (bmp == null && albumId > 0) {
                            val albumUri = ContentUris.withAppendedId(
                                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                                albumId
                            )
                            bmp = try {
                                contentResolver.loadThumbnail(albumUri, Size(320, 320), null)
                            } catch (_: Exception) {
                                null
                            }
                        }
                        if (bmp != null) {
                            val baos = ByteArrayOutputStream()
                            bmp.compress(Bitmap.CompressFormat.JPEG, 85, baos)
                            bmp.recycle()
                            return baos.toByteArray()
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }

        if (rawBytes == null) return null

        // Downscale oversized embedded covers (e.g. >90KB) so scrolling dozens of tracks stays smooth
        if (rawBytes.size <= 90 * 1024) {
            return rawBytes
        }

        return try {
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, boundsOpts)
            val maxDim = maxOf(boundsOpts.outWidth, boundsOpts.outHeight)
            var sampleSize = 1
            while (maxDim / sampleSize > 512) {
                sampleSize *= 2
            }
            val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
            val bmp = BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, decodeOpts)
            if (bmp != null) {
                val baos = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.JPEG, 85, baos)
                bmp.recycle()
                baos.toByteArray()
            } else {
                rawBytes
            }
        } catch (_: Exception) {
            rawBytes
        }
    }

    private fun extractVideoDisplayMetadata(path: String): Map<String, Int>? {
        val file = File(path)
        if (!file.exists()) return null

        var codedW = 0
        var codedH = 0
        var rotation = 0

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            codedW = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            codedH = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
        } catch (_: Exception) {
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        // Fallback & pixel-aspect-ratio (SAR) inspection via MediaExtractor
        var sarNum = 1
        var sarDen = 1
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(path)
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) {
                    if (codedW <= 0 && format.containsKey(MediaFormat.KEY_WIDTH)) {
                        codedW = format.getInteger(MediaFormat.KEY_WIDTH)
                    }
                    if (codedH <= 0 && format.containsKey(MediaFormat.KEY_HEIGHT)) {
                        codedH = format.getInteger(MediaFormat.KEY_HEIGHT)
                    }
                    if (rotation == 0 && format.containsKey("rotation-degrees")) {
                        rotation = format.getInteger("rotation-degrees")
                    }
                    if (format.containsKey("sar-width") && format.containsKey("sar-height")) {
                        val sw = format.getInteger("sar-width")
                        val sh = format.getInteger("sar-height")
                        if (sw > 0 && sh > 0) {
                            sarNum = sw
                            sarDen = sh
                        }
                    }
                    break
                }
            }
        } catch (_: Exception) {
        } finally {
            try {
                extractor.release()
            } catch (_: Exception) {
            }
        }

        if (codedW <= 0 || codedH <= 0) return null

        // Apply pixel aspect ratio before orientation rotation
        val sarAdjustedW = if (sarNum != sarDen) {
            Math.round(codedW.toDouble() * sarNum.toDouble() / sarDen.toDouble()).toInt().coerceAtLeast(1)
        } else {
            codedW
        }

        val normRot = ((rotation % 360) + 360) % 360
        val displayW = if (normRot == 90 || normRot == 270) codedH else sarAdjustedW
        val displayH = if (normRot == 90 || normRot == 270) sarAdjustedW else codedH

        return mapOf(
            "width" to displayW,
            "height" to displayH,
            "codedWidth" to codedW,
            "codedHeight" to codedH,
            "rotation" to normRot
        )
    }

    private fun formatResolutionLabel(w: Int, h: Int): String {
        if (w <= 0 || h <= 0) return "HD"
        val minDim = minOf(w, h)
        val maxDim = maxOf(w, h)
        return when {
            minDim >= 2160 || maxDim >= 3840 -> "4K UHD"
            minDim >= 1440 || maxDim >= 2560 -> "2K QHD"
            minDim >= 1080 || maxDim >= 1920 -> "1080p FHD"
            minDim >= 720 || maxDim >= 1280 -> "720p HD"
            minDim >= 480 || maxDim >= 854 -> "480p SD"
            minDim >= 360 -> "360p"
            else -> "${w}x${h}"
        }
    }

    private fun extractVideosMediaInfoBatch(paths: List<String>): Map<String, Map<String, Any>> {
        val resultMap = HashMap<String, Map<String, Any>>(paths.size)
        if (paths.isEmpty()) return resultMap

        data class StoreVideoMeta(val durationMs: Long, val width: Int, val height: Int)
        val storeMap = HashMap<String, StoreVideoMeta>()

        try {
            @Suppress("DEPRECATION")
            val projection = arrayOf(
                MediaStore.Video.Media.DATA,
                MediaStore.Video.Media.DURATION,
                MediaStore.Video.Media.WIDTH,
                MediaStore.Video.Media.HEIGHT
            )
            contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                null
            )?.use { cursor ->
                val dataIdx = cursor.getColumnIndex(MediaStore.Video.Media.DATA)
                val durIdx = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)
                val wIdx = cursor.getColumnIndex(MediaStore.Video.Media.WIDTH)
                val hIdx = cursor.getColumnIndex(MediaStore.Video.Media.HEIGHT)
                while (cursor.moveToNext()) {
                    val filePath = if (dataIdx >= 0) cursor.getString(dataIdx) else null
                    if (!filePath.isNullOrBlank()) {
                        val dur = if (durIdx >= 0) cursor.getLong(durIdx) else 0L
                        val w = if (wIdx >= 0) cursor.getInt(wIdx) else 0
                        val h = if (hIdx >= 0) cursor.getInt(hIdx) else 0
                        storeMap[filePath] = StoreVideoMeta(dur, w, h)
                    }
                }
            }
        } catch (_: Exception) {
        }

        for (path in paths) {
            val cached = storeMap[path]
            var durMs = cached?.durationMs ?: 0L
            var w = cached?.width ?: 0
            var h = cached?.height ?: 0

            if (durMs <= 0L || w <= 0 || h <= 0) {
                val file = File(path)
                if (file.exists()) {
                    val retriever = MediaMetadataRetriever()
                    try {
                        retriever.setDataSource(path)
                        if (durMs <= 0L) {
                            durMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                                ?.toLongOrNull() ?: 0L
                        }
                        if (w <= 0 || h <= 0) {
                            val rw = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                                ?.toIntOrNull() ?: 0
                            val rh = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                                ?.toIntOrNull() ?: 0
                            val rot = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                                ?.toIntOrNull() ?: 0
                            if (rw > 0 && rh > 0) {
                                val normRot = ((rot % 360) + 360) % 360
                                w = if (normRot == 90 || normRot == 270) rh else rw
                                h = if (normRot == 90 || normRot == 270) rw else rh
                            }
                        }
                    } catch (_: Exception) {
                    } finally {
                        try {
                            retriever.release()
                        } catch (_: Exception) {
                        }
                    }
                }
            }

            resultMap[path] = mapOf(
                "durationMs" to durMs.coerceAtLeast(0L),
                "width" to w.coerceAtLeast(0),
                "height" to h.coerceAtLeast(0),
                "resolution" to formatResolutionLabel(w, h)
            )
        }

        return resultMap
    }

    private fun extractAudiosMediaInfoBatch(paths: List<String>): Map<String, Map<String, Any>> {
        val resultMap = HashMap<String, Map<String, Any>>(paths.size)
        if (paths.isEmpty()) return resultMap

        data class StoreAudioMeta(val durationMs: Long, val artist: String, val album: String)
        val storeMap = HashMap<String, StoreAudioMeta>()

        try {
            @Suppress("DEPRECATION")
            val projection = arrayOf(
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM
            )
            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                null
            )?.use { cursor ->
                val dataIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
                val durIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
                val artIdx = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
                val albIdx = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
                while (cursor.moveToNext()) {
                    val filePath = if (dataIdx >= 0) cursor.getString(dataIdx) else null
                    if (!filePath.isNullOrBlank()) {
                        val dur = if (durIdx >= 0) cursor.getLong(durIdx) else 0L
                        val artist = if (artIdx >= 0) (cursor.getString(artIdx) ?: "") else ""
                        val album = if (albIdx >= 0) (cursor.getString(albIdx) ?: "") else ""
                        storeMap[filePath] = StoreAudioMeta(dur, artist, album)
                    }
                }
            }
        } catch (_: Exception) {
        }

        for (path in paths) {
            val cached = storeMap[path]
            var durMs = cached?.durationMs ?: 0L
            var artist = cached?.artist ?: ""
            var album = cached?.album ?: ""

            if (durMs <= 0L) {
                val file = File(path)
                if (file.exists()) {
                    val retriever = MediaMetadataRetriever()
                    try {
                        retriever.setDataSource(path)
                        durMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                            ?.toLongOrNull() ?: 0L
                        if (artist.isBlank() || artist == "<unknown>") {
                            artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: ""
                        }
                        if (album.isBlank() || album == "<unknown>") {
                            album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM) ?: ""
                        }
                    } catch (_: Exception) {
                    } finally {
                        try {
                            retriever.release()
                        } catch (_: Exception) {
                        }
                    }
                }
            }

            if (artist == "<unknown>") artist = ""
            if (album == "<unknown>") album = ""

            resultMap[path] = mapOf(
                "durationMs" to durMs.coerceAtLeast(0L),
                "artist" to artist.trim(),
                "album" to album.trim()
            )
        }

        return resultMap
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isPlayerActive && isVideoPlaying) {
            triggerPictureInPicture()
        }
    }

    @Suppress("DEPRECATION")
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        if (isInPictureInPictureMode) {
            val layout = window.attributes
            if (layout.screenBrightness != WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE) {
                layout.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                window.attributes = layout
            }
        }
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    private fun buildClampedAspectRatio(): Rational {
        val w = if (lastAspectWidth > 0) lastAspectWidth else 16
        val h = if (lastAspectHeight > 0) lastAspectHeight else 9
        val ratio = w.toFloat() / h.toFloat()
        // Android requires PiP aspect ratio strictly within [0.418410, 2.390000]
        return when {
            ratio > 2.35f -> Rational(235, 100)
            ratio < 0.45f -> Rational(45, 100)
            else -> Rational(w, h)
        }
    }

    private fun createPipAction(
        requestCode: Int,
        controlType: String,
        iconRes: Int,
        title: String
    ): RemoteAction {
        val intent = Intent(ACTION_PIP_CONTROL).apply {
            setPackage(packageName)
            putExtra(EXTRA_CONTROL_TYPE, controlType)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return RemoteAction(
            Icon.createWithResource(this, iconRes),
            title,
            title,
            pendingIntent
        )
    }

    private fun buildPipParams(): PictureInPictureParams {
        val actions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            listOf(
                createPipAction(101, CONTROL_PREV, android.R.drawable.ic_media_previous, "Previous"),
                createPipAction(
                    102,
                    CONTROL_TOGGLE,
                    if (isVideoPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                    if (isVideoPlaying) "Pause" else "Play"
                ),
                createPipAction(103, CONTROL_NEXT, android.R.drawable.ic_media_next, "Next")
            )
        } else {
            emptyList()
        }

        return PictureInPictureParams.Builder()
            .setAspectRatio(buildClampedAspectRatio())
            .setActions(actions)
            .build()
    }

    private fun updatePipParams() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                setPictureInPictureParams(buildPipParams())
            } catch (_: Exception) {
            }
        }
    }

    private fun triggerPictureInPicture(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) return false
        return try {
            enterPictureInPictureMode(buildPipParams())
        } catch (_: Exception) {
            false
        }
    }
}
