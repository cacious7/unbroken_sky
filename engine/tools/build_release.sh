#!/usr/bin/env bash
# Builds the signed Google Play bundle (AAB), the itch.io web zip and runs the tests.
#
#   bash engine/tools/build_release.sh
#
# Before each Play upload, raise version/code (and usually version/name) in the
# "Android Release AAB" preset of export_presets.cfg; Play rejects a repeated code.
# Builds go in %USERPROFILE%\.unbroken_sky_build\android (outside OneDrive).
# The upload key and its password live outside the repo and outside OneDrive:
#   %USERPROFILE%\.unbroken_sky_keys\upload.keystore
#   %USERPROFILE%\.unbroken_sky_keys\upload_key_credentials.txt
set -euo pipefail
# Git Bash started from PowerShell may not have its own tools on PATH.
export PATH="/usr/bin:/mingw64/bin:$PATH"

ENGINE="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
KEYS="$HOME/.unbroken_sky_keys"
CREDENTIALS="$KEYS/upload_key_credentials.txt"

if [ ! -f "$CREDENTIALS" ]; then
	echo "Missing $CREDENTIALS - restore the upload key from backup first." >&2
	exit 1
fi
# The file may start with a UTF-8 byte-order mark (Windows PowerShell writes one).
value() { sed 's/^\xEF\xBB\xBF//' "$CREDENTIALS" | grep "^$1=" | head -1 | cut -d= -f2- | tr -d '\r'; }

cd "$ENGINE"
mkdir -p build/android build/web

echo "== tests"
"$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1 | grep -E "^(FAIL|TESTS)"

echo "== Google Play bundle (AAB)"
# Without this Gradle leaves a background daemon running and Godot never exits.
export GRADLE_OPTS="-Dorg.gradle.daemon=false"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$(value keystore)"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(value alias)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(value password)"
# The Gradle project lives outside OneDrive (see gradle_build_directory in the AAB
# preset): it grows past 1 GB and OneDrive locks its files mid-build.
install_template=""
[ -d "$HOME/.unbroken_sky_build/android/build" ] || install_template="--install-android-build-template"
"$GODOT" --headless --path . $install_template --export-release "Android Release AAB" build/android/unbroken_sky.aab
ls -la build/android/unbroken_sky.aab

echo "== web build for itch.io"
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
rm -f build/unbroken_sky_web.zip
"$GODOT" --headless --path . --script res://tools/zip_web.gd
ls -la build/unbroken_sky_web.zip
