package com.cracklog.lingafriq

import android.net.ConnectivityManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object DataSaverChannel {
    private const val name = "lingafriq/data_saver"

    fun register(activity: FlutterActivity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, name).setMethodCallHandler { call, result ->
            if (call.method != "isDataSaverOn") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                result.success(false)
                return@setMethodCallHandler
            }
            val manager = activity.getSystemService(ConnectivityManager::class.java)
            val enabled = manager.restrictBackgroundStatus ==
                ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED
            result.success(enabled)
        }
    }
}
