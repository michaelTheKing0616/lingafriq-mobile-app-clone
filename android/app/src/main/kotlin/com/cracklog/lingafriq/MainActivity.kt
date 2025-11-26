package com.cracklog.lingafriq

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for all Android versions
        // This is the modern, non-deprecated way (works on all API levels)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // For Android 15+ (API 35+), edge-to-edge is enabled by default when targeting SDK 35
        // The deprecated APIs (setStatusBarColor, setNavigationBarColor, etc.) 
        // are automatically handled by the system in edge-to-edge mode
        // We've removed those deprecated calls from Flutter code
        
        // Enable immersive mode for navigation bar (hide by default, swipe up to show)
        // This prevents buttons from being hidden by the navigation bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            // Hide navigation bar by default (immersive mode)
            windowInsetsController.hide(WindowInsetsCompat.Type.navigationBars())
            // Allow swipe up to show navigation bar temporarily
            windowInsetsController.systemBarsBehavior = 
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        } else {
            // For older versions, use legacy immersive mode
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
        
        super.onCreate(savedInstanceState)
    }
}
