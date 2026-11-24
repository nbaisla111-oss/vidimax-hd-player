package com.rox.player

import android.Manifest
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
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
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.rox.player/system_controls"
        private const val ACTION_PIP_CONTROL = "com.rox.player.ACTION_PIP_CONTROL"
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

    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioNotifyRunnable = Runnable {
        methodChannel?.invokeMethod("onAudioLibraryChanged", null)
    }
    private val videoNotifyRunnable = Runnable {
        methodChannel?.invokeMethod("onVideoLibraryChanged", null)
    }
    private val audioContentObserver = object : ContentObserver(mainHandler) {
        override fun onChange(selfChange: Boolean) {
            super.onChange(selfChange)
            scheduleAudioLibraryChangedNotification()
        }

        override fun onChange(selfChange: Boolean, uri: Uri?) {
            super.onChange(selfChange, uri)
            scheduleAudioLibraryChangedNotification()
        }
    }
    private val videoContentObserver = object : ContentObserver(mainHandler) {
        override fun onChange(selfChange: Boolean) {
            super.onChange(selfChange)
            scheduleVideoLibraryChangedNotification()
        }

        override fun onChange(selfChange: Boolean, uri: Uri?) {
            super.onChange(selfChange, uri)
            scheduleVideoLibraryChangedNotification()
        }
    }
    private var audioObserverRegistered = false
    private var videoObserverRegistered = false

    private fun scheduleAudioLibraryChangedNotification() {
        mainHandler.removeCallbacks(audioNotifyRunnable)
        mainHandler.postDelayed(audioNotifyRunnable, 800L)
    }

    private fun scheduleVideoLibraryChangedNotification() {
        mainHandler.removeCallbacks(videoNotifyRunnable)
        mainHandler.postDelayed(videoNotifyRunnable, 800L)
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
        try {
            contentResolver.registerContentObserver(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                true,
                audioContentObserver
            )
            audioObserverRegistered = true
        } catch (_: Exception) {
        }
        try {
            contentResolver.registerContentObserver(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                true,
                videoContentObserver
            )
            videoObserverRegistered = true
        } catch (_: Exception) {
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
        mainHandler.removeCallbacks(audioNotifyRunnable)
        mainHandler.removeCallbacks(videoNotifyRunnable)
        if (audioObserverRegistered) {
            try {
                contentResolver.unregisterContentObserver(audioContentObserver)
            } catch (_: Exception) {
            }
            audioObserverRegistered = false
        }
        if (videoObserverRegistered) {
            try {
                contentResolver.unregisterContentObserver(videoContentObserver)
            } catch (_: Exception) {
            }
            videoObserverRegistered = false
        }
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
                "queryAllDeviceAudio" -> {
                    mediaWorker.execute {
                        val tracks = queryAllDeviceAudioTracks()
                        runOnUiThread { result.success(tracks) }
                    }
                }
                "saveMediaToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val isVideo = call.argument<Boolean>("isVideo") ?: false
                    if (sourcePath.isNullOrBlank()) {
                        result.success(mapOf("success" to false, "error" to "Empty source path"))
                        return@setMethodCallHandler
                    }
                    mediaWorker.execute {
                        val saveResult = saveMediaFileToGallery(sourcePath, fileName, isVideo)
                        runOnUiThread { result.success(saveResult) }
                    }
                }
                "scanMediaFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType")
                    if (path.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val mimeArray = if (!mimeType.isNullOrBlank()) arrayOf(mimeType) else null
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            mimeArray
                        ) { _, _ -> }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
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

        data class StoreAudioMeta(val durationMs: Long, val artist: String, val album: String, val title: String)
        val storeMap = HashMap<String, StoreAudioMeta>()

        try {
            @Suppress("DEPRECATION")
            val projection = arrayOf(
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.TITLE
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
                val titleIdx = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
                while (cursor.moveToNext()) {
                    val filePath = if (dataIdx >= 0) cursor.getString(dataIdx) else null
                    if (!filePath.isNullOrBlank()) {
                        val dur = if (durIdx >= 0) cursor.getLong(durIdx) else 0L
                        val artist = if (artIdx >= 0) (cursor.getString(artIdx) ?: "") else ""
                        val album = if (albIdx >= 0) (cursor.getString(albIdx) ?: "") else ""
                        val title = if (titleIdx >= 0) (cursor.getString(titleIdx) ?: "") else ""
                        storeMap[normalizeMediaPathKey(filePath)] = StoreAudioMeta(dur, artist, album, title)
                    }
                }
            }
        } catch (_: Exception) {
        }

        for (path in paths) {
            val cached = storeMap[normalizeMediaPathKey(path)]
            var durMs = cached?.durationMs ?: 0L
            var artist = cached?.artist ?: ""
            var album = cached?.album ?: ""
            var title = cached?.title ?: ""

            if (durMs <= 0L || title.isBlank()) {
                val file = File(path)
                if (file.exists()) {
                    val retriever = MediaMetadataRetriever()
                    try {
                        retriever.setDataSource(path)
                        if (durMs <= 0L) {
                            durMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                                ?.toLongOrNull() ?: 0L
                        }
                        if (artist.isBlank() || artist == "<unknown>") {
                            artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: ""
                        }
                        if (album.isBlank() || album == "<unknown>") {
                            album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM) ?: ""
                        }
                        if (title.isBlank()) {
                            title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE) ?: ""
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
                "album" to album.trim(),
                "title" to title.trim()
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

    private fun resolveMediaMimeType(fileName: String, isVideo: Boolean): String {
        val ext = fileName.substringAfterLast('.', "").lowercase(Locale.ROOT)
        return when {
            isVideo -> when (ext) {
                "mp4", "m4v" -> "video/mp4"
                "3gp" -> "video/3gpp"
                "mkv" -> "video/x-matroska"
                "webm" -> "video/webm"
                "avi" -> "video/x-msvideo"
                "mov" -> "video/quicktime"
                else -> "video/mp4"
            }
            else -> when (ext) {
                "png" -> "image/png"
                "webp" -> "image/webp"
                "gif" -> "image/gif"
                else -> "image/jpeg"
            }
        }
    }

    private fun saveMediaFileToGallery(
        sourcePath: String,
        requestedName: String?,
        isVideo: Boolean
    ): Map<String, Any?> {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists() || !sourceFile.canRead()) {
            return mapOf("success" to false, "error" to "Source status file not accessible")
        }

        val cleanName = (requestedName?.takeIf { it.isNotBlank() } ?: sourceFile.name)
        val mimeType = resolveMediaMimeType(cleanName, isVideo)
        val albumFolder = "RoxPlayer_Status"
        val nowMs = System.currentTimeMillis()
        val nowSec = nowMs / 1000L

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = if (isVideo) {
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            }
            val baseDir = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            val relativePath = "$baseDir/$albumFolder"

            // Reuse existing entry if exact file was already saved to prevent Gallery duplicates
            try {
                @Suppress("DEPRECATION")
                val existingProjection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA, MediaStore.MediaColumns.SIZE)
                val existingSelection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
                contentResolver.query(
                    collection,
                    existingProjection,
                    existingSelection,
                    arrayOf(cleanName, "$relativePath%"),
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val existingId = cursor.getLong(0)
                        val existingDataIdx = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                        val existingSizeIdx = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                        val existingPath = if (existingDataIdx >= 0) cursor.getString(existingDataIdx) else null
                        val existingSize = if (existingSizeIdx >= 0) cursor.getLong(existingSizeIdx) else 0L
                        val existingUri = ContentUris.withAppendedId(collection, existingId)
                        if (existingSize == sourceFile.length() && !existingPath.isNullOrBlank() && File(existingPath).exists()) {
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(existingPath),
                                arrayOf(mimeType),
                                null
                            )
                            return mapOf(
                                "success" to true,
                                "savedPath" to existingPath,
                                "uri" to existingUri.toString()
                            )
                        }
                    }
                }
            } catch (_: Exception) {
            }

            try {
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, cleanName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.DATE_ADDED, nowSec)
                    put(MediaStore.MediaColumns.DATE_MODIFIED, nowSec)
                    if (isVideo) {
                        put(MediaStore.Video.Media.DATE_TAKEN, nowMs)
                    } else {
                        put(MediaStore.Images.Media.DATE_TAKEN, nowMs)
                    }
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val itemUri = contentResolver.insert(collection, values)
                if (itemUri != null) {
                    contentResolver.openOutputStream(itemUri, "w")?.use { outStream ->
                        FileInputStream(sourceFile).use { inStream ->
                            inStream.copyTo(outStream)
                        }
                        outStream.flush()
                    } ?: throw IllegalStateException("Unable to open MediaStore output stream")

                    val publishValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                        put(MediaStore.MediaColumns.DATE_MODIFIED, System.currentTimeMillis() / 1000L)
                    }
                    contentResolver.update(itemUri, publishValues, null, null)

                    var resolvedPath: String? = null
                    try {
                        @Suppress("DEPRECATION")
                        contentResolver.query(
                            itemUri,
                            arrayOf(MediaStore.MediaColumns.DATA),
                            null,
                            null,
                            null
                        )?.use { c ->
                            if (c.moveToFirst()) {
                                val idx = c.getColumnIndex(MediaStore.MediaColumns.DATA)
                                if (idx >= 0) resolvedPath = c.getString(idx)
                            }
                        }
                    } catch (_: Exception) {
                    }

                    val fallbackPublicPath = File(
                        Environment.getExternalStoragePublicDirectory(baseDir),
                        "$albumFolder/$cleanName"
                    ).absolutePath
                    val finalPath = resolvedPath ?: fallbackPublicPath

                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(finalPath),
                        arrayOf(mimeType),
                        null
                    )

                    return mapOf(
                        "success" to true,
                        "savedPath" to finalPath,
                        "uri" to itemUri.toString()
                    )
                }
            } catch (_: Exception) {
                // Fall through to legacy direct public copy + MediaScannerConnection below
            }
        }

        // Legacy Android 7-9 OR fallback path: write to public Pictures / Movies + MediaScannerConnection
        return try {
            val baseDirType = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            val targetDir = File(Environment.getExternalStoragePublicDirectory(baseDirType), albumFolder)
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            val destFile = File(targetDir, cleanName)
            FileInputStream(sourceFile).use { inStream ->
                FileOutputStream(destFile).use { outStream ->
                    inStream.copyTo(outStream)
                    outStream.flush()
                }
            }
            destFile.setLastModified(nowMs)

            @Suppress("DEPRECATION")
            val contentUri = if (isVideo) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            try {
                @Suppress("DEPRECATION")
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DATA, destFile.absolutePath)
                    put(MediaStore.MediaColumns.DISPLAY_NAME, cleanName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.SIZE, destFile.length())
                    put(MediaStore.MediaColumns.DATE_ADDED, nowSec)
                    put(MediaStore.MediaColumns.DATE_MODIFIED, nowSec)
                }
                contentResolver.insert(contentUri, values)
            } catch (_: Exception) {
            }

            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(destFile.absolutePath),
                arrayOf(mimeType),
                null
            )

            @Suppress("DEPRECATION")
            sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(destFile)))

            mapOf(
                "success" to true,
                "savedPath" to destFile.absolutePath,
                "uri" to Uri.fromFile(destFile).toString()
            )
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Failed to save to Gallery"))
        }
    }

    private fun normalizeMediaPathKey(rawPath: String): String {
        val resolved = try {
            File(rawPath).canonicalPath
        } catch (_: Exception) {
            rawPath
        }
        var normalized = resolved.replace('\\', '/').trim()
        val prefixes = listOf(
            "/sdcard/",
            "/mnt/sdcard/",
            "/storage/self/primary/",
            "/mnt/user/0/primary/"
        )
        val lower = normalized.lowercase(Locale.ROOT)
        for (prefix in prefixes) {
            if (lower.startsWith(prefix)) {
                normalized = "/storage/emulated/0/" + normalized.substring(prefix.length)
                break
            }
        }
        return normalized.lowercase(Locale.ROOT)
    }

    private fun hasNomediaInAncestors(file: File, cache: MutableMap<String, Boolean>): Boolean {
        var dir = file.parentFile
        var depth = 0
        while (dir != null && depth < 10) {
            val dirPath = dir.absolutePath
            val lowerDir = dirPath.lowercase(Locale.ROOT)
            if (lowerDir == "/storage/emulated/0" || lowerDir == "/storage" || lowerDir == "/") {
                break
            }
            val cached = cache[dirPath]
            if (cached != null) {
                if (cached) return true
            } else {
                val hasNomedia = try {
                    File(dir, ".nomedia").exists()
                } catch (_: Exception) {
                    false
                }
                cache[dirPath] = hasNomedia
                if (hasNomedia) return true
            }
            dir = dir.parentFile
            depth++
        }
        return false
    }

    private val whatsappAudioNameRegex = Regex("^(aud|ptt)-?\\d{6,8}-wa\\d+.*", RegexOption.IGNORE_CASE)

    private fun queryAllDeviceAudioTracks(): List<Map<String, Any>> {
        val tracks = ArrayList<Map<String, Any>>()
        val seenCanonicalPaths = HashSet<String>()
        val seenSignatures = HashSet<String>()
        val nomediaCache = HashMap<String, Boolean>()
        val supportedExts = setOf("mp3", "m4a", "wav", "aac", "flac", "ogg", "opus", "wma")

        val hasAudioPerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED ||
                Environment.isExternalStorageManager()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED ||
                Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }

        if (!hasAudioPerm) {
            return tracks
        }

        try {
            @Suppress("DEPRECATION")
            val projectionList = mutableListOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.DATE_MODIFIED,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.MIME_TYPE,
                MediaStore.Audio.Media.IS_MUSIC,
                MediaStore.Audio.Media.IS_RINGTONE,
                MediaStore.Audio.Media.IS_ALARM,
                MediaStore.Audio.Media.IS_NOTIFICATION
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                projectionList.add(MediaStore.Audio.Media.IS_PENDING)
            }

            val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                "(${MediaStore.Audio.Media.IS_PENDING} IS NULL OR ${MediaStore.Audio.Media.IS_PENDING} = 0)"
            } else {
                null
            }
            val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC, ${MediaStore.Audio.Media.DATE_MODIFIED} DESC"

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projectionList.toTypedArray(),
                selection,
                null,
                sortOrder
            )?.use { cursor ->
                val dataIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
                val nameIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                val titleIdx = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
                val artistIdx = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
                val albumIdx = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
                val durIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
                val sizeIdx = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
                val modIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)
                val addIdx = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_ADDED)
                val mimeIdx = cursor.getColumnIndex(MediaStore.Audio.Media.MIME_TYPE)
                val musicIdx = cursor.getColumnIndex(MediaStore.Audio.Media.IS_MUSIC)
                val ringIdx = cursor.getColumnIndex(MediaStore.Audio.Media.IS_RINGTONE)
                val alarmIdx = cursor.getColumnIndex(MediaStore.Audio.Media.IS_ALARM)
                val notifIdx = cursor.getColumnIndex(MediaStore.Audio.Media.IS_NOTIFICATION)

                while (cursor.moveToNext()) {
                    val filePath = if (dataIdx >= 0) cursor.getString(dataIdx) else null
                    if (filePath.isNullOrBlank()) continue

                    val fileObj = File(filePath)
                    if (!fileObj.exists()) continue

                    val canonicalKey = normalizeMediaPathKey(filePath)
                    if (!seenCanonicalPaths.add(canonicalKey)) continue

                    val fileName = (if (nameIdx >= 0) cursor.getString(nameIdx) else null)
                        ?.takeIf { it.isNotBlank() } ?: fileObj.name
                    val lowerName = fileName.lowercase(Locale.ROOT)
                    val lowerPath = canonicalKey
                    val isMusicFlag = if (musicIdx >= 0) cursor.getInt(musicIdx) else 0
                    val isRingtoneFlag = if (ringIdx >= 0) cursor.getInt(ringIdx) else 0
                    val isAlarmFlag = if (alarmIdx >= 0) cursor.getInt(alarmIdx) else 0
                    val isNotifFlag = if (notifIdx >= 0) cursor.getInt(notifIdx) else 0

                    // Standard Android Music Player exclusions:
                    // 1. Hidden / trashed / .nomedia folders / Android private dirs / system tones
                    if (lowerName.startsWith(".trashed-") ||
                        lowerName.startsWith(".") ||
                        lowerPath.contains("/.") ||
                        lowerPath.contains("/android/data/") ||
                        lowerPath.contains("/android/obb/") ||
                        isRingtoneFlag != 0 ||
                        isAlarmFlag != 0 ||
                        isNotifFlag != 0 ||
                        lowerPath.contains("/notifications/") ||
                        lowerPath.contains("/ringtones/") ||
                        lowerPath.contains("/alarms/") ||
                        lowerPath.contains("/ui/")) {
                        continue
                    }

                    // 2. WhatsApp Audio, WhatsApp Voice Notes, Business/GBWhatsApp & Call Recordings
                    if (lowerPath.contains("/whatsapp") ||
                        lowerPath.contains("com.whatsapp") ||
                        whatsappAudioNameRegex.matches(lowerName) ||
                        lowerPath.contains("/callrecordings") ||
                        lowerPath.contains("/call recordings") ||
                        lowerPath.contains("/call_rec") ||
                        lowerPath.contains("/callrecord") ||
                        lowerPath.contains("/voicemail")) {
                        continue
                    }

                    // 3. Respect .nomedia folders (standard Android music player trick)
                    if (hasNomediaInAncestors(fileObj, nomediaCache)) {
                        continue
                    }

                    val ext = fileName.substringAfterLast('.', "").lowercase(Locale.ROOT)
                    val mime = if (mimeIdx >= 0) (cursor.getString(mimeIdx) ?: "") else ""
                    val isAudioFormat = supportedExts.contains(ext) ||
                        mime.startsWith("audio/", ignoreCase = true) ||
                        isMusicFlag != 0
                    if (!isAudioFormat) continue

                    // Voice note codec (.opus / .amr) not explicitly flagged as music
                    if (isMusicFlag == 0 && (ext == "opus" || ext == "amr")) {
                        continue
                    }

                    val sizeBytes = if (sizeIdx >= 0) cursor.getLong(sizeIdx) else fileObj.length()
                    val effectiveSize = if (sizeBytes > 0L) sizeBytes else fileObj.length()
                    if (effectiveSize < 8 * 1024) continue

                    var durMs = if (durIdx >= 0) cursor.getLong(durIdx) else 0L
                    var artist = if (artistIdx >= 0) (cursor.getString(artistIdx) ?: "") else ""
                    var album = if (albumIdx >= 0) (cursor.getString(albumIdx) ?: "") else ""
                    var title = if (titleIdx >= 0) (cursor.getString(titleIdx) ?: "") else ""

                    if (durMs <= 0L) {
                        val retriever = MediaMetadataRetriever()
                        try {
                            retriever.setDataSource(filePath)
                            durMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                                ?.toLongOrNull() ?: 0L
                            if (artist.isBlank() || artist == "<unknown>") {
                                artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: ""
                            }
                            if (album.isBlank() || album == "<unknown>") {
                                album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM) ?: ""
                            }
                            if (title.isBlank()) {
                                title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE) ?: ""
                            }
                        } catch (_: Exception) {
                        } finally {
                            try {
                                retriever.release()
                            } catch (_: Exception) {
                            }
                        }
                    }

                    // 4. Filter short non-music sound effects/voice clips (<15s), except RoxPlayer extracted tracks
                    val isRoxExtracted = lowerPath.contains("roxplayer") || lowerPath.contains("vidimax")
                    if (!isRoxExtracted && durMs in 1L..14999L) {
                        continue
                    }

                    // 5. Deduplicate identical copies across mount aliases/duplicate folders
                    val fileSig = "${lowerName}_$effectiveSize"
                    if (!seenSignatures.add(fileSig)) {
                        continue
                    }

                    val parentFolder = fileObj.parentFile?.name?.takeIf { it.isNotBlank() } ?: "Internal"
                    if (title.isBlank()) {
                        title = fileName.substringBeforeLast('.').replace(Regex("[_-]"), " ").trim()
                            .ifBlank { fileName }
                    }
                    if (artist.isBlank() || artist == "<unknown>") {
                        artist = if (parentFolder.contains("RoxPlayer") || parentFolder.contains("VidiMax")) {
                            "Rox Extracted"
                        } else {
                            parentFolder
                        }
                    }
                    if (album.isBlank() || album == "<unknown>") {
                        album = parentFolder
                    }

                    val dateAddedSec = if (addIdx >= 0) cursor.getLong(addIdx) else 0L
                    val dateModSec = if (modIdx >= 0) cursor.getLong(modIdx) else 0L
                    val effectiveTsMs = when {
                        dateModSec > 0L -> dateModSec * 1000L
                        dateAddedSec > 0L -> dateAddedSec * 1000L
                        else -> fileObj.lastModified()
                    }

                    tracks.add(
                        mapOf(
                            "path" to filePath,
                            "title" to title.trim(),
                            "artist" to artist.trim(),
                            "album" to album.trim(),
                            "folder" to parentFolder,
                            "durationMs" to durMs.coerceAtLeast(0L),
                            "size" to effectiveSize,
                            "dateAddedMs" to effectiveTsMs
                        )
                    )
                }
            }
        } catch (_: Exception) {
        }

        return tracks
    }
}
