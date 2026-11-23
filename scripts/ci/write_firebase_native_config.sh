#!/usr/bin/env bash
# Write the native Firebase files Gradle and Xcode expect.
# The API keys stay in the environment. Project ids match lib/firebase_options.dart.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import html
import json
import os
import sys
from pathlib import Path

root = Path(sys.argv[1])
android_key = os.environ.get("FIREBASE_API_KEY_ANDROID", "")
ios_key = os.environ.get("FIREBASE_API_KEY_IOS", "")

android = {
    "project_info": {
        "project_number": "202890241823",
        "project_id": "lingafriq-mobile-app",
        "storage_bucket": "lingafriq-mobile-app.appspot.com",
    },
    "client": [
        {
            "client_info": {
                "mobilesdk_app_id": "1:202890241823:android:bb7801cf2cc6e5b878722a",
                "android_client_info": {"package_name": "com.cracklog.lingafriq"},
            },
            "oauth_client": [],
            "api_key": [{"current_key": android_key}],
            "services": {"appinvite_service": {"other_platform_oauth_client": []}},
        }
    ],
    "configuration_version": "1",
}
android_path = root / "android" / "app" / "google-services.json"
android_path.write_text(json.dumps(android), encoding="utf-8")

plist = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>{html.escape(ios_key)}</string>
  <key>GCM_SENDER_ID</key>
  <string>202890241823</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>com.owlab.lingafriq</string>
  <key>PROJECT_ID</key>
  <string>lingafriq-mobile-app</string>
  <key>STORAGE_BUCKET</key>
  <string>lingafriq-mobile-app.appspot.com</string>
  <key>GOOGLE_APP_ID</key>
  <string>1:202890241823:ios:ae2190c00d638d7e78722a</string>
</dict>
</plist>
"""
(root / "GoogleService-Info.plist").write_text(plist, encoding="utf-8")
print("wrote android/app/google-services.json and GoogleService-Info.plist")
PY
