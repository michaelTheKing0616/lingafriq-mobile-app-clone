#!/usr/bin/env bash
# Build a sideloadable Flutter *release* APK (stable channel / production backend).
#
# Output:
#   build/app/outputs/flutter-apk/app-release.apk
#   dist/lingafriq-<version>-release.apk  (copy)
#
# Signing:
#   Uses android/key.properties + a JKS if present (Play upload key).
#   Otherwise generates a local sideload keystore (gitignored) so the APK
#   is installable. That sideload signature will NOT match Play Store.
#
# Usage (from repo root):
#   ./scripts/build_stable_apk.sh
#
# Optional env:
#   BACKEND_URL, CDN_URL, WS_URL, APP_WEB_URL, CERTIFICATE_PIN_HASHES
#   ANDROID_HOME / ANDROID_SDK_ROOT, FLUTTER_HOME, JAVA_HOME

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
export PATH="$JAVA_HOME/bin:$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

BACKEND_URL="${BACKEND_URL:-https://admin.lingafriq.com}"
CDN_URL="${CDN_URL:-https://admin.lingafriq.com}"
WS_URL="${WS_URL:-wss://admin.lingafriq.com}"
APP_WEB_URL="${APP_WEB_URL:-https://lingafriq.com}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter not found. Install Flutter 3.35.x (stable) and add it to PATH." >&2
  exit 1
fi

if [ ! -d "$ANDROID_HOME/platforms" ]; then
  echo "ERROR: Android SDK not found at $ANDROID_HOME" >&2
  exit 1
fi

VERSION_LINE="$(grep '^version:' pubspec.yaml | sed 's/version: //')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

echo "==> Flutter $(flutter --version | head -n 1)"
echo "==> Java $($JAVA_HOME/bin/java -version 2>&1 | head -n 1)"
echo "==> Version ${VERSION_NAME}+${BUILD_NUMBER}"
echo "==> Backend ${BACKEND_URL}"

# Flutter / Android local.properties
if [ ! -f android/local.properties ]; then
  {
    echo "sdk.dir=${ANDROID_HOME}"
    echo "flutter.sdk=${FLUTTER_HOME}"
  } > android/local.properties
fi

# Sideload signing if Play keystore is not configured
if [ ! -f android/key.properties ]; then
  KEYSTORE_PATH="android/app/sideload-release.jks"
  if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "==> Generating gitignored sideload keystore (not the Play Store key)"
    mkdir -p android/app
    keytool -genkeypair -batch \
      -keystore "$KEYSTORE_PATH" \
      -storetype JKS \
      -keyalg RSA -keysize 2048 -validity 10000 \
      -alias lingafriq_sideload \
      -storepass lingafriq-sideload \
      -keypass lingafriq-sideload \
      -dname "CN=LingAfriq Sideload, OU=Mobile, O=LingAfriq, C=US"
  fi
  cat > android/key.properties <<EOF
storePassword=lingafriq-sideload
keyPassword=lingafriq-sideload
keyAlias=lingafriq_sideload
storeFile=app/sideload-release.jks
EOF
  echo "==> Wrote android/key.properties for sideload signing"
else
  echo "==> Using existing android/key.properties"
fi

chmod +x android/gradlew || true

echo "==> flutter pub get"
flutter pub get

BUILD_ARGS=(
  apk
  --release
  --target-platform=android-arm,android-arm64
  --split-debug-info=build/symbols
  --build-name="$VERSION_NAME"
  --build-number="$BUILD_NUMBER"
  --dart-define="BACKEND_URL=${BACKEND_URL}"
  --dart-define="CDN_URL=${CDN_URL}"
  --dart-define="WS_URL=${WS_URL}"
  --dart-define="APP_WEB_URL=${APP_WEB_URL}"
)

if [ -n "${CERTIFICATE_PIN_HASHES:-}" ]; then
  BUILD_ARGS+=(--dart-define="CERTIFICATE_PIN_HASHES=${CERTIFICATE_PIN_HASHES}")
fi

echo "==> flutter build ${BUILD_ARGS[*]}"
flutter build "${BUILD_ARGS[@]}"

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_SRC" ]; then
  echo "ERROR: APK not produced at $APK_SRC" >&2
  exit 1
fi

mkdir -p dist
APK_DST="dist/lingafriq-${VERSION_NAME}+${BUILD_NUMBER}-release.apk"
cp -f "$APK_SRC" "$APK_DST"

echo
echo "✅ Stable release APK"
echo "   $APK_DST"
ls -lh "$APK_SRC" "$APK_DST"
aapt dump badging "$APK_SRC" 2>/dev/null | head -n 8 || \
  "$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging "$APK_SRC" 2>/dev/null | head -n 8 || true
