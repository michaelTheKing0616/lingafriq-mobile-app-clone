#!/bin/bash
# Script to fix GeneratedPluginRegistrant.java after flutter pub get
# This comments out problematic plugin registrations that cause build failures

REGISTRANT_FILE="android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if [ ! -f "$REGISTRANT_FILE" ]; then
  echo "❌ GeneratedPluginRegistrant.java not found at $REGISTRANT_FILE"
  exit 1
fi

echo "🔧 Fixing GeneratedPluginRegistrant.java..."

# Use perl for more reliable in-place editing (works on both Linux and Mac)
# Comment out flutter_webrtc registration
perl -i -pe 's/(\s+)flutterEngine\.getPlugins\(\)\.add\(new com\.cloudwebrtc\.webrtc\.FlutterWebRTCPlugin\(\)\);/$1\/\/ flutterEngine.getPlugins().add(new com.cloudwebrtc.webrtc.FlutterWebRTCPlugin()); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

perl -i -pe 's/(\s+)Log\.e\(TAG, "Error registering plugin flutter_webrtc.*/$1\/\/ Log.e(TAG, "Error registering plugin flutter_webrtc..."); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

# Comment out workmanager registration
perl -i -pe 's/(\s+)flutterEngine\.getPlugins\(\)\.add\(new dev\.fluttercommunity\.workmanager\.WorkmanagerPlugin\(\)\);/$1\/\/ flutterEngine.getPlugins().add(new dev.fluttercommunity.workmanager.WorkmanagerPlugin()); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

perl -i -pe 's/(\s+)Log\.e\(TAG, "Error registering plugin workmanager.*/$1\/\/ Log.e(TAG, "Error registering plugin workmanager..."); \/\/ COMMENTED/g' "$REGISTRANT_FILE"

echo "✅ GeneratedPluginRegistrant.java fixed successfully"

# Show what we changed (for debugging)
echo "📋 Verifying changes:"
grep -n "flutter_webrtc\|workmanager" "$REGISTRANT_FILE" | head -10 || echo "No matches found (good - means they're commented out)"

