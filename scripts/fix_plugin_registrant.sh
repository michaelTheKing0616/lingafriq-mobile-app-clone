#!/bin/bash
# Script to prevent problematic plugins from being registered
# This removes them from .flutter-plugins BEFORE GeneratedPluginRegistrant.java is created

echo "🔧 Removing problematic plugins from .flutter-plugins..."

# Debug: Check if file exists
if [ -f ".flutter-plugins" ]; then
  echo "📁 Found .flutter-plugins file"
  echo "📋 Contents before:"
  cat .flutter-plugins | grep -E "flutter_webrtc|workmanager" || echo "  (no problematic plugins found)"
  
  # Remove flutter_webrtc and workmanager
  grep -v "flutter_webrtc" .flutter-plugins | grep -v "workmanager" > .flutter-plugins.tmp
  mv .flutter-plugins.tmp .flutter-plugins
  
  echo "📋 Contents after:"
  cat .flutter-plugins | grep -E "flutter_webrtc|workmanager" || echo "  (successfully removed)"
  echo "✅ Removed flutter_webrtc and workmanager from .flutter-plugins"
else
  echo "⚠️  .flutter-plugins not found - will rely on Java file fix only"
  echo "📁 Current directory: $(pwd)"
  echo "📁 Files present:"
  ls -la | grep flutter || echo "  (no flutter files)"
fi

# Also fix the Java file if it already exists (belt and suspenders approach)
REGISTRANT_FILE="android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if [ ! -f "$REGISTRANT_FILE" ]; then
  echo "ℹ️  GeneratedPluginRegistrant.java not found yet (will be generated clean)"
  exit 0
fi

echo "🔧 Also fixing existing GeneratedPluginRegistrant.java..."

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

