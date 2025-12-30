#!/bin/bash
# Remove flutter_webrtc from .flutter-plugins file
# This prevents the plugin from being compiled, avoiding deprecated API errors

FLUTTER_PLUGINS=".flutter-plugins"
FLUTTER_PLUGINS_DEPENDENCIES=".flutter-plugins-dependencies"

# Remove from .flutter-plugins
if [ -f "$FLUTTER_PLUGINS" ]; then
    grep -v "flutter_webrtc" "$FLUTTER_PLUGINS" > "${FLUTTER_PLUGINS}.tmp"
    mv "${FLUTTER_PLUGINS}.tmp" "$FLUTTER_PLUGINS"
    echo "✅ Removed flutter_webrtc from .flutter-plugins"
else
    echo "⚠️ .flutter-plugins file not found"
fi

# Also remove from .flutter-plugins-dependencies if it exists
if [ -f "$FLUTTER_PLUGINS_DEPENDENCIES" ]; then
    # Use a more robust method to remove the plugin entry
    python3 -c "
import json
import sys
try:
    with open('$FLUTTER_PLUGINS_DEPENDENCIES', 'r') as f:
        data = json.load(f)
    
    # Remove flutter_webrtc from all sections
    if 'plugins' in data:
        data['plugins'] = {k: v for k, v in data['plugins'].items() if 'flutter_webrtc' not in k.lower()}
    if 'plugin_dependencies' in data:
        data['plugin_dependencies'] = {k: v for k, v in data['plugin_dependencies'].items() if 'flutter_webrtc' not in k.lower()}
    
    with open('$FLUTTER_PLUGINS_DEPENDENCIES', 'w') as f:
        json.dump(data, f, indent=2)
    print('✅ Removed flutter_webrtc from .flutter-plugins-dependencies')
except Exception as e:
    # If JSON parsing fails, try simple grep removal
    grep -v -i 'flutter_webrtc' '$FLUTTER_PLUGINS_DEPENDENCIES' > '${FLUTTER_PLUGINS_DEPENDENCIES}.tmp'
    mv '${FLUTTER_PLUGINS_DEPENDENCIES}.tmp' '$FLUTTER_PLUGINS_DEPENDENCIES'
    print('✅ Removed flutter_webrtc from .flutter-plugins-dependencies (fallback method)')
" 2>/dev/null || {
    # Fallback to grep if python3 is not available
    if [ -f "$FLUTTER_PLUGINS_DEPENDENCIES" ]; then
        grep -v -i 'flutter_webrtc' "$FLUTTER_PLUGINS_DEPENDENCIES" > "${FLUTTER_PLUGINS_DEPENDENCIES}.tmp"
        mv "${FLUTTER_PLUGINS_DEPENDENCIES}.tmp" "$FLUTTER_PLUGINS_DEPENDENCIES"
        echo "✅ Removed flutter_webrtc from .flutter-plugins-dependencies (grep method)"
    fi
}
fi

