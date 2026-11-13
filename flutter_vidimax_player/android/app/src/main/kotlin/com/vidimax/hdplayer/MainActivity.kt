package com.vidimax.hdplayer

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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

    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_PIP_CONTROL) return
            val control = intent.getStringExtra(EXTRA_CONTROL_TYPE) ?: return
            methodChannel?.invokeMethod("onPipAction", control)
        }
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(ACTION_PIP_CONTROL)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipActionReceiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(pipActionReceiver)
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
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

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isPlayerActive && isVideoPlaying) {
            triggerPictureInPicture()
        }
    }

    @Suppress("DEPRECATION")
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
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
