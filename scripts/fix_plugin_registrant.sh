#!/bin/bash
# Script to fix GeneratedPluginRegistrant.java after flutter pub get
# This comments out problematic plugin registrations that cause build failures

REGISTRANT_FILE="android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if [ ! -f "$REGISTRANT_FILE" ]; then
  echo "❌ GeneratedPluginRegistrant.java not found at $REGISTRANT_FILE"
  exit 1
fi

echo "🔧 Fixing GeneratedPluginRegistrant.java..."

# Comment out flutter_webrtc registration
sed -i 's/flutterEngine\.getPlugins()\.add(new com\.cloudwebrtc\.webrtc\.FlutterWebRTCPlugin());/\/\/ flutterEngine.getPlugins().add(new com.cloudwebrtc.webrtc.FlutterWebRTCPlugin()); \/\/ COMMENTED - Build issue, LiveKit handles WebRTC internally/g' "$REGISTRANT_FILE"

sed -i 's/Log\.e(TAG, "Error registering plugin flutter_webrtc.*/\/\/ Log.e(TAG, "Error registering plugin flutter_webrtc..."); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

# Comment out workmanager registration
sed -i 's/flutterEngine\.getPlugins()\.add(new dev\.fluttercommunity\.workmanager\.WorkmanagerPlugin());/\/\/ flutterEngine.getPlugins().add(new dev.fluttercommunity.workmanager.WorkmanagerPlugin()); \/\/ COMMENTED - Build issue, background tasks handled differently/g' "$REGISTRANT_FILE"

sed -i 's/Log\.e(TAG, "Error registering plugin workmanager.*/\/\/ Log.e(TAG, "Error registering plugin workmanager..."); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

echo "✅ GeneratedPluginRegistrant.java fixed successfully"

