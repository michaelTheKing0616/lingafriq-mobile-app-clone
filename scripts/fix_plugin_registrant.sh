#!/bin/bash
# Script to fix GeneratedPluginRegistrant.java by commenting out problematic plugin registrations
# This must run RIGHT BEFORE the build command, after all flutter pub get operations

echo "🔧 Fixing GeneratedPluginRegistrant.java..."

REGISTRANT_FILE="android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if [ ! -f "$REGISTRANT_FILE" ]; then
  echo "⚠️  GeneratedPluginRegistrant.java not found - will be generated during build"
  exit 0
fi

echo "📁 Found $REGISTRANT_FILE"

# Make file writable first (in case it was made read-only before)
chmod 644 "$REGISTRANT_FILE"

# Use perl for reliable in-place editing (works on Linux and Mac)
# Comment out flutter_webrtc registration
perl -i -pe 's/^(\s+)(flutterEngine\.getPlugins\(\)\.add\(new com\.cloudwebrtc\.webrtc\.FlutterWebRTCPlugin\(\)\);)/$1\/\/ $2 \/\/ COMMENTED - Build fix/g' "$REGISTRANT_FILE"

perl -i -pe 's/^(\s+)(Log\.e\(TAG, "Error registering plugin flutter_webrtc)/$1\/\/ $2/g' "$REGISTRANT_FILE"

# Comment out workmanager registration  
perl -i -pe 's/^(\s+)(flutterEngine\.getPlugins\(\)\.add\(new dev\.fluttercommunity\.workmanager\.WorkmanagerPlugin\(\)\);)/$1\/\/ $2 \/\/ COMMENTED - Build fix/g' "$REGISTRANT_FILE"

perl -i -pe 's/^(\s+)(Log\.e\(TAG, "Error registering plugin workmanager)/$1\/\/ $2/g' "$REGISTRANT_FILE"

# Also comment out the import statements to prevent "package does not exist" errors
perl -i -pe 's/^(import com\.cloudwebrtc\.webrtc\.FlutterWebRTCPlugin;)/\/\/ $1 \/\/ COMMENTED - Build fix/g' "$REGISTRANT_FILE"

perl -i -pe 's/^(import dev\.fluttercommunity\.workmanager\.WorkmanagerPlugin;)/\/\/ $1 \/\/ COMMENTED - Build fix/g' "$REGISTRANT_FILE"

echo "✅ GeneratedPluginRegistrant.java fixed successfully"

# Make file READ-ONLY to prevent flutter build from regenerating it
chmod 444 "$REGISTRANT_FILE"
echo "🔒 Made file read-only to prevent regeneration"

# Show what we changed (for debugging)
echo "📋 Verifying changes:"
grep -n "flutter_webrtc\|workmanager" "$REGISTRANT_FILE" | head -15 || echo "No matches found"

