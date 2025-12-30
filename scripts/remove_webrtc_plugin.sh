#!/bin/bash
# Remove flutter_webrtc from .flutter-plugins file
# This prevents the plugin from being compiled, avoiding deprecated API errors

FLUTTER_PLUGINS=".flutter-plugins"
if [ -f "$FLUTTER_PLUGINS" ]; then
    grep -v "flutter_webrtc" "$FLUTTER_PLUGINS" > "${FLUTTER_PLUGINS}.tmp"
    mv "${FLUTTER_PLUGINS}.tmp" "$FLUTTER_PLUGINS"
    echo "Removed flutter_webrtc from .flutter-plugins"
else
    echo ".flutter-plugins file not found"
fi

