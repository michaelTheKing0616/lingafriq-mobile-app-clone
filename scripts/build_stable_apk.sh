#!/usr/bin/env bash
# Build a sideloadable Flutter *release* APK for external testers.
#
# Defaults (tester-friendly):
#   - Dual phone ABIs: armeabi-v7a + arm64-v8a (no x86)
#   - Sideload signing if Play keystore is missing
#   - R8 minify/shrink OFF (avoids common release-crash class of bugs)
#   - Production backend URLs
#
# Output:
#   build/app/outputs/flutter-apk/app-release.apk
#   dist/lingafriq-<version>-phone-release.apk
#
# Usage (from repo root):
#   ./scripts/build_stable_apk.sh
#
# Optional env:
#   BACKEND_URL, CDN_URL, WS_URL, APP_WEB_URL, CERTIFICATE_PIN_HASHES
#   LINGAFRIQ_ABI_FILTERS   (default: armeabi-v7a,arm64-v8a)
#   LINGAFRIQ_SIDELOAD_NO_MINIFY=true (default) — disables R8 via Gradle property
#   ANDROID_HOME / ANDROID_SDK_ROOT, FLUTTER_HOME, JAVA_HOME

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Prefer an explicit JAVA_HOME; otherwise probe common JDK 17 locations.
if [ -z "${JAVA_HOME:-}" ]; then
  if [ -x "$HOME/jdks/temurin-17.jdk/Contents/Home/bin/java" ]; then
    JAVA_HOME="$HOME/jdks/temurin-17.jdk/Contents/Home"
  elif [ -x /usr/lib/jvm/java-17-openjdk-amd64/bin/java ]; then
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
  elif command -v /usr/libexec/java_home >/dev/null 2>&1; then
    JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  fi
fi
export JAVA_HOME="${JAVA_HOME:-}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

BACKEND_URL="${BACKEND_URL:-https://admin.lingafriq.com}"
CDN_URL="${CDN_URL:-https://admin.lingafriq.com}"
WS_URL="${WS_URL:-wss://admin.lingafriq.com}"
APP_WEB_URL="${APP_WEB_URL:-https://lingafriq.com}"
LINGAFRIQ_ABI_FILTERS="${LINGAFRIQ_ABI_FILTERS:-armeabi-v7a,arm64-v8a}"
LINGAFRIQ_SIDELOAD_NO_MINIFY="${LINGAFRIQ_SIDELOAD_NO_MINIFY:-true}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter not found. Install Flutter (stable) and add it to PATH." >&2
  exit 1
fi

if [ ! -d "$ANDROID_HOME/platforms" ]; then
  echo "ERROR: Android SDK not found at $ANDROID_HOME" >&2
  exit 1
fi

if [ -z "$JAVA_HOME" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  echo "ERROR: JAVA_HOME must point at a JDK 17 install." >&2
  exit 1
fi

VERSION_LINE="$(grep '^version:' pubspec.yaml | sed 's/version: //')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

echo "==> Flutter $(flutter --version 2>/dev/null | head -n 1)"
echo "==> Java $($JAVA_HOME/bin/java -version 2>&1 | head -n 1)"
echo "==> Version ${VERSION_NAME}+${BUILD_NUMBER}"
echo "==> Backend ${BACKEND_URL}"
echo "==> ABI filters ${LINGAFRIQ_ABI_FILTERS}"
echo "==> Sideload no-minify ${LINGAFRIQ_SIDELOAD_NO_MINIFY}"

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
    keytool -genkeypair -noprompt \
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

# Phone ABIs only (exclude emulator x86). Play AAB path is unchanged when unset.
export ORG_GRADLE_PROJECT_lingafriqAbiFilters="$LINGAFRIQ_ABI_FILTERS"
export ORG_GRADLE_PROJECT_lingafriqSideloadNoMinify="$LINGAFRIQ_SIDELOAD_NO_MINIFY"

# Map ABI filters → flutter --target-platform
TARGET_PLATFORMS=()
IFS=',' read -r -a ABI_LIST <<< "$LINGAFRIQ_ABI_FILTERS"
for abi in "${ABI_LIST[@]}"; do
  abi="$(echo "$abi" | tr -d '[:space:]')"
  case "$abi" in
    armeabi-v7a) TARGET_PLATFORMS+=("android-arm") ;;
    arm64-v8a) TARGET_PLATFORMS+=("android-arm64") ;;
    x86_64) TARGET_PLATFORMS+=("android-x64") ;;
    x86) ;; # Flutter no longer ships 32-bit x86
  esac
done
if [ "${#TARGET_PLATFORMS[@]}" -eq 0 ]; then
  TARGET_PLATFORMS=("android-arm" "android-arm64")
fi
TARGET_PLATFORM_CSV="$(IFS=,; echo "${TARGET_PLATFORMS[*]}")"

BUILD_ARGS=(
  apk
  --release
  --target-platform="$TARGET_PLATFORM_CSV"
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
  ls -la build/app/outputs/flutter-apk 2>/dev/null || true
  exit 1
fi

mkdir -p dist
ABI_LABEL="$(echo "$LINGAFRIQ_ABI_FILTERS" | tr ',' '-' | tr -d '[:space:]')"
APK_DST="dist/lingafriq-${VERSION_NAME}+${BUILD_NUMBER}-phone-release.apk"

BUILD_TOOLS=""
for ver in 35.0.0 36.0.0 34.0.0; do
  if [ -x "$ANDROID_HOME/build-tools/$ver/apksigner" ]; then
    BUILD_TOOLS="$ANDROID_HOME/build-tools/$ver"
    break
  fi
done
if [ -z "$BUILD_TOOLS" ]; then
  echo "ERROR: apksigner not found under $ANDROID_HOME/build-tools" >&2
  exit 1
fi

STORE_FILE="$(grep '^storeFile=' android/key.properties | cut -d= -f2-)"
STORE_PASS="$(grep '^storePassword=' android/key.properties | cut -d= -f2-)"
KEY_PASS="$(grep '^keyPassword=' android/key.properties | cut -d= -f2-)"
KEY_ALIAS="$(grep '^keyAlias=' android/key.properties | cut -d= -f2-)"
if [[ "$STORE_FILE" != /* ]]; then
  STORE_FILE="android/${STORE_FILE}"
fi

WORK="$(mktemp -d)"
cp -f "$APK_SRC" "$WORK/in.apk"
# Drop ABI trees that are not in the keep list (plugin AARs may still ship extras).
KEEP=",${LINGAFRIQ_ABI_FILTERS},"
for abi in armeabi armeabi-v7a arm64-v8a x86 x86_64; do
  if [[ "$KEEP" != *",$abi,"* ]]; then
    zip -d "$WORK/in.apk" "lib/${abi}/*" >/dev/null 2>&1 || true
  fi
done
zip -d "$WORK/in.apk" "META-INF/*.SF" "META-INF/*.RSA" "META-INF/*.DSA" "META-INF/*.EC" >/dev/null 2>&1 || true
"$BUILD_TOOLS/zipalign" -f -p 4 "$WORK/in.apk" "$WORK/aligned.apk"
"$BUILD_TOOLS/apksigner" sign \
  --ks "$STORE_FILE" \
  --ks-pass "pass:${STORE_PASS}" \
  --key-pass "pass:${KEY_PASS}" \
  --ks-key-alias "$KEY_ALIAS" \
  --v1-signing-enabled true \
  --v2-signing-enabled true \
  --v3-signing-enabled true \
  --out "$APK_DST" \
  "$WORK/aligned.apk"
"$BUILD_TOOLS/apksigner" verify --verbose "$APK_DST" >/dev/null
rm -rf "$WORK"

SHA256="$(shasum -a 256 "$APK_DST" | awk '{print $1}')"
echo "$SHA256  $(basename "$APK_DST")" > "${APK_DST}.sha256"

echo
echo "✅ Tester sideload APK (${ABI_LABEL})"
echo "   $APK_DST"
echo "   sha256: $SHA256"
ls -lh "$APK_SRC" "$APK_DST"
"$BUILD_TOOLS/aapt" dump badging "$APK_DST" | head -n 8 || true
echo
echo "Install notes for testers:"
echo "  1) Uninstall any existing LingAfriq (Play Store signature differs)."
echo "  2) Enable Install unknown apps for your file manager/browser."
echo "  3) Install this APK (armeabi-v7a + arm64-v8a phones)."
