# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter WebRTC - Keep deprecated embedding API classes
-keep class io.flutter.plugin.common.PluginRegistry$Registrar { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn io.flutter.plugin.common.PluginRegistry$Registrar

# Keep all WebRTC related classes
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep LiveKit classes
-keep class io.livekit.** { *; }
-dontwarn io.livekit.**

# Google ML Kit Text Recognition - suppress missing optional script recognizers
# The plugin references Chinese/Devanagari/Japanese/Korean recognizers but
# they are optional dependencies we don't bundle (we only use Latin script).
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
