package com.vidimax.hdplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

class MainActivity: FlutterActivity() {
    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vidimax.player/system_controls").setMethodCallHandler { call, result ->
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
                else -> result.notImplemented()
            }
        }
    }
}
