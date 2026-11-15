package com.rox.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.media.MediaMetadata
import android.media.MediaMetadataRetriever
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import java.io.File
import java.util.concurrent.Executors

class MediaPlaybackService : Service() {

    companion object {
        const val CHANNEL_ID = "rox_media_playback_channel"
        const val NOTIFICATION_ID = 4401

        const val ACTION_UPDATE = "com.rox.player.media.UPDATE"
        const val ACTION_CLEAR = "com.rox.player.media.CLEAR"
        const val ACTION_PREV = "com.rox.player.media.PREV"
        const val ACTION_TOGGLE = "com.rox.player.media.TOGGLE"
        const val ACTION_NEXT = "com.rox.player.media.NEXT"
        const val ACTION_STOP = "com.rox.player.media.STOP"

        const val ACTION_MEDIA_EVENT = "com.rox.player.ACTION_MEDIA_EVENT"
        const val EXTRA_EVENT = "event"

        const val EXTRA_TITLE = "title"
        const val EXTRA_SUBTITLE = "subtitle"
        const val EXTRA_PATH = "path"
        const val EXTRA_MEDIA_TYPE = "mediaType"
        const val EXTRA_IS_PLAYING = "isPlaying"
        const val EXTRA_DURATION_MS = "durationMs"
        const val EXTRA_POSITION_MS = "positionMs"

        @Volatile
        var actionListener: ((String) -> Unit)? = null
    }

    private var mediaSession: MediaSession? = null
    private lateinit var notificationManager: NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private val artExecutor = Executors.newSingleThreadExecutor()

    private var currentTitle: String = "Rox Player"
    private var currentSubtitle: String = "Playing media"
    private var currentPath: String = ""
    private var currentMediaType: String = "audio"
    private var currentIsPlaying: Boolean = false
    private var currentDurationMs: Long = 0L
    private var currentPositionMs: Long = 0L

    private var cachedArtPath: String = ""
    private var cachedArtBitmap: Bitmap? = null
    private var defaultLargeIcon: Bitmap? = null
    private var isForegroundActive = false

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureNotificationChannel()

        try {
            defaultLargeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        } catch (_: Exception) {
        }

        mediaSession = MediaSession(this, "RoxPlayerMediaSession").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    dispatchEvent("play")
                }

                override fun onPause() {
                    dispatchEvent("pause")
                }

                override fun onSkipToNext() {
                    dispatchEvent("next")
                }

                override fun onSkipToPrevious() {
                    dispatchEvent("prev")
                }

                override fun onStop() {
                    dispatchEvent("stop")
                    stopPlaybackService()
                }

                override fun onSeekTo(pos: Long) {
                    currentPositionMs = pos.coerceAtLeast(0L)
                    updateSessionPlaybackState()
                    dispatchEvent("seek:$currentPositionMs")
                }
            })
            isActive = true
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PREV -> {
                dispatchEvent("prev")
                return START_NOT_STICKY
            }
            ACTION_TOGGLE -> {
                dispatchEvent("toggle")
                return START_NOT_STICKY
            }
            ACTION_NEXT -> {
                dispatchEvent("next")
                return START_NOT_STICKY
            }
            ACTION_STOP -> {
                dispatchEvent("stop")
                stopPlaybackService()
                return START_NOT_STICKY
            }
            ACTION_CLEAR -> {
                stopPlaybackService()
                return START_NOT_STICKY
            }
            ACTION_UPDATE, null -> {
                if (intent != null) {
                    currentTitle = intent.getStringExtra(EXTRA_TITLE)?.takeIf { it.isNotBlank() } ?: "Rox Player"
                    currentSubtitle = intent.getStringExtra(EXTRA_SUBTITLE)?.takeIf { it.isNotBlank() } ?: "Rox Player"
                    currentPath = intent.getStringExtra(EXTRA_PATH) ?: ""
                    currentMediaType = intent.getStringExtra(EXTRA_MEDIA_TYPE) ?: "audio"
                    currentIsPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, false)
                    currentDurationMs = intent.getLongExtra(EXTRA_DURATION_MS, 0L).coerceAtLeast(0L)
                    currentPositionMs = intent.getLongExtra(EXTRA_POSITION_MS, 0L).coerceAtLeast(0L)
                }

                // Always enter foreground synchronously within system timeout
                mediaSession?.isActive = true
                updateSessionPlaybackState()
                updateSessionMetadata()
                postNotification(asForeground = true)

                if (currentPath.isNotBlank() && currentPath != cachedArtPath) {
                    val requestedPath = currentPath
                    val requestedType = currentMediaType
                    artExecutor.execute {
                        val bmp = loadArtworkBitmap(requestedPath, requestedType)
                        mainHandler.post {
                            if (currentPath == requestedPath) {
                                cachedArtPath = requestedPath
                                cachedArtBitmap = bmp
                                updateSessionMetadata()
                                postNotification(asForeground = false)
                            }
                        }
                    }
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopPlaybackService()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        isForegroundActive = false
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
            mediaSession = null
        } catch (_: Exception) {
        }
        try {
            artExecutor.shutdownNow()
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    private fun stopPlaybackService() {
        isForegroundActive = false
        try {
            mediaSession?.isActive = false
        } catch (_: Exception) {
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            @Suppress("DEPRECATION")
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        try {
            notificationManager.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        stopSelf()
    }

    private fun dispatchEvent(event: String) {
        val listener = actionListener
        if (listener != null) {
            mainHandler.post { listener.invoke(event) }
        } else {
            val broadcast = Intent(ACTION_MEDIA_EVENT).apply {
                setPackage(packageName)
                putExtra(EXTRA_EVENT, event)
            }
            sendBroadcast(broadcast)
        }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Media Playback Controls",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Controls active audio and video playback from notification shade & lock screen"
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    setSound(null, null)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    private fun updateSessionPlaybackState() {
        val session = mediaSession ?: return
        val actions = PlaybackState.ACTION_PLAY or
            PlaybackState.ACTION_PAUSE or
            PlaybackState.ACTION_PLAY_PAUSE or
            PlaybackState.ACTION_SKIP_TO_PREVIOUS or
            PlaybackState.ACTION_SKIP_TO_NEXT or
            PlaybackState.ACTION_STOP or
            PlaybackState.ACTION_SEEK_TO

        val stateCode = if (currentIsPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED
        val state = PlaybackState.Builder()
            .setActions(actions)
            .setState(stateCode, currentPositionMs, if (currentIsPlaying) 1.0f else 0.0f)
            .build()
        session.setPlaybackState(state)
    }

    private fun updateSessionMetadata() {
        val session = mediaSession ?: return
        val art = if (currentPath == cachedArtPath && cachedArtBitmap != null) {
            cachedArtBitmap
        } else {
            defaultLargeIcon
        }
        val metaBuilder = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, currentTitle)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, currentSubtitle)
            .putString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE, currentTitle)
            .putString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE, currentSubtitle)
        if (currentDurationMs > 0) {
            metaBuilder.putLong(MediaMetadata.METADATA_KEY_DURATION, currentDurationMs)
        }
        if (art != null) {
            metaBuilder.putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, art)
            metaBuilder.putBitmap(MediaMetadata.METADATA_KEY_ART, art)
        }
        session.setMetadata(metaBuilder.build())
    }

    private fun buildServiceAction(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MediaPlaybackService::class.java).apply {
            this.action = action
        }
        return PendingIntent.getService(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            500,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevPending = buildServiceAction(ACTION_PREV, 501)
        val togglePending = buildServiceAction(ACTION_TOGGLE, 502)
        val nextPending = buildServiceAction(ACTION_NEXT, 503)
        val stopPending = buildServiceAction(ACTION_STOP, 504)

        val toggleIconRes = if (currentIsPlaying) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }
        val toggleLabel = if (currentIsPlaying) "Pause" else "Play"

        val prevAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_media_previous),
            "Previous",
            prevPending
        ).build()

        val toggleAction = Notification.Action.Builder(
            Icon.createWithResource(this, toggleIconRes),
            toggleLabel,
            togglePending
        ).build()

        val nextAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_media_next),
            "Next",
            nextPending
        ).build()

        val stopAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
            "Close",
            stopPending
        ).build()

        val art = if (currentPath == cachedArtPath && cachedArtBitmap != null) {
            cachedArtBitmap
        } else {
            defaultLargeIcon
        }

        val mediaStyle = Notification.MediaStyle()
            .setShowActionsInCompactView(0, 1, 2)
        mediaSession?.let { mediaStyle.setMediaSession(it.sessionToken) }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.drawable.ic_stat_rox)
            .setContentTitle(currentTitle)
            .setContentText(currentSubtitle)
            .setSubText("Rox Player")
            .setContentIntent(contentPendingIntent)
            .setDeleteIntent(stopPending)
            .setOngoing(currentIsPlaying)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(prevAction)
            .addAction(toggleAction)
            .addAction(nextAction)
            .addAction(stopAction)
            .setStyle(mediaStyle)

        if (art != null) {
            builder.setLargeIcon(art)
        }

        return builder.build()
    }

    private fun postNotification(asForeground: Boolean) {
        val notification = buildNotification()
        try {
            if (asForeground || !isForegroundActive) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                isForegroundActive = true
            } else {
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            try {
                notificationManager.notify(NOTIFICATION_ID, notification)
            } catch (_: Exception) {
            }
        }
    }

    private fun loadArtworkBitmap(path: String, mediaType: String): Bitmap? {
        if (path.isBlank() || path.startsWith("http://") || path.startsWith("https://")) {
            return null
        }
        val file = File(path)
        if (!file.exists()) return null

        if (mediaType == "video") {
            val retriever = MediaMetadataRetriever()
            return try {
                retriever.setDataSource(path)
                val frame = retriever.getFrameAtTime(1_000_000L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    ?: retriever.frameAtTime
                downscaleBitmap(frame, 384)
            } catch (_: Exception) {
                null
            } finally {
                try {
                    retriever.release()
                } catch (_: Exception) {
                }
            }
        }

        // Audio artwork: embeddedPicture -> MediaStore thumbnail
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val embedded = retriever.embeddedPicture
            if (embedded != null && embedded.isNotEmpty()) {
                val decoded = decodeSampledBytes(embedded, 384)
                if (decoded != null) return decoded
            }
        } catch (_: Exception) {
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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
                        val bmp = try {
                            contentResolver.loadThumbnail(audioUri, Size(320, 320), null)
                        } catch (_: Exception) {
                            null
                        }
                        if (bmp != null) return bmp
                        if (albumId > 0) {
                            val albumUri = ContentUris.withAppendedId(
                                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                                albumId
                            )
                            return try {
                                contentResolver.loadThumbnail(albumUri, Size(320, 320), null)
                            } catch (_: Exception) {
                                null
                            }
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun decodeSampledBytes(bytes: ByteArray, maxSize: Int): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            val maxDim = maxOf(bounds.outWidth, bounds.outHeight)
            var sampleSize = 1
            while (maxDim / sampleSize > maxSize) {
                sampleSize *= 2
            }
            val opts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
        } catch (_: Exception) {
            null
        }
    }

    private fun downscaleBitmap(bmp: Bitmap?, maxDim: Int): Bitmap? {
        if (bmp == null) return null
        val w = bmp.width
        val h = bmp.height
        if (w <= maxDim && h <= maxDim) return bmp
        val scale = maxDim.toFloat() / maxOf(w, h).toFloat()
        val nw = (w * scale).toInt().coerceAtLeast(1)
        val nh = (h * scale).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(bmp, nw, nh, true)
        if (scaled != bmp) bmp.recycle()
        return scaled
    }
}
