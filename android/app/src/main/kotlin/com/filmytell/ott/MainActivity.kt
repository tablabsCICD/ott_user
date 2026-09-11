package com.filmytell.ott

import android.os.Bundle
import android.view.WindowManager
import com.filmytell.ott.cast.CastBridgeManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val antiPiracyChannel = "com.filmytell.ott/anti_piracy"
    private var castBridgeManager: CastBridgeManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep the screen awake during playback-heavy sessions.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Google Cast Bridge
        castBridgeManager = CastBridgeManager(this).also {
            it.register(flutterEngine)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            antiPiracyChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "disableSecureScreen" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "deviceIntegrity" -> {
                    result.success(
                        mapOf(
                            "rooted" to isRootedDevice(),
                            "jailbroken" to false,
                            "emulator" to isEmulator(),
                            "screenCaptured" to false
                        )
                    )
                }
                "deviceIdentity" -> {
                    result.success(
                        mapOf(
                            "deviceName" to "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}".trim(),
                            "osVersion" to "Android ${android.os.Build.VERSION.RELEASE}"
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isRootedDevice(): Boolean {
        val buildTags = android.os.Build.TAGS ?: ""
        if (buildTags.contains("test-keys")) return true

        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )

        return rootPaths.any { File(it).exists() }
    }

    private fun isEmulator(): Boolean {
        val fingerprint = android.os.Build.FINGERPRINT.lowercase()
        val model = android.os.Build.MODEL.lowercase()
        val product = android.os.Build.PRODUCT.lowercase()
        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator") ||
            model.contains("google_sdk") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            product.contains("sdk") ||
            product.contains("emulator")
    }
}
