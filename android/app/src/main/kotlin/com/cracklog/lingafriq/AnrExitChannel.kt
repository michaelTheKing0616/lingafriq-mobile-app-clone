package com.cracklog.lingafriq

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object AnrExitChannel {
    private const val name = "lingafriq/anr_exits"

    fun register(activity: FlutterActivity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, name).setMethodCallHandler { call, result ->
            if (call.method != "previousAnrs") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                result.success(emptyList<Map<String, Any>>())
                return@setMethodCallHandler
            }
            val manager = activity.getSystemService(ActivityManager::class.java)
            val exits = manager.getHistoricalProcessExitReasons(activity.packageName, 0, 16)
            val anrs = exits
                .filter { it.reason == ApplicationExitInfo.REASON_ANR }
                .map { exit ->
                    mapOf(
                        "timestamp" to exit.timestamp,
                        "description" to (exit.description ?: "anr"),
                    )
                }
            result.success(anrs)
        }
    }
}
