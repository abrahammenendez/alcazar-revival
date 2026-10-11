#!/usr/bin/env bash
# Rebuilds Alcazar 1.2.13 so it installs on current Android, with every book unlocked.
set -euo pipefail

readonly ORIGINAL_SHA256=50621158ef2e37ad0b0d04633cb11dbfc5ac00531844e3ce918a8154082391b8
readonly TARGET_SDK=34
readonly OUT=build/alcazar-1.2.13-revival.apk

usage() {
  echo "Usage: $0 <original apk> <keystore> [key alias]" >&2
  exit 64
}

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d ' ' -f 1
}

# Prefers the tool on PATH, then the newest build-tools in the Android SDK.
build_tool() {
  if command -v "$1" >/dev/null; then
    command -v "$1"
    return
  fi
  local sdk=${ANDROID_HOME:?put $1 on PATH or set ANDROID_HOME}
  local dir
  dir=$(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
  [[ -x $dir/$1 ]] || { echo "$1 not found in $sdk/build-tools" >&2; exit 1; }
  echo "$dir/$1"
}

# Replaces a literal string that must occur exactly once, so an edit that stops matching fails the build.
replace_once() {
  FROM=$2 TO=$3 perl -0pi -e '
    my $n = () = /\Q$ENV{FROM}\E/g;
    die "$ARGV: expected one \"$ENV{FROM}\", found $n\n" if $n != 1;
    s/\Q$ENV{FROM}\E/$ENV{TO}/;
  ' "$1"
}

[[ $# -eq 2 || $# -eq 3 ]] || usage
apk=$1
keystore=$2
alias=${3:-}

if [[ $(sha256 "$apk") != "$ORIGINAL_SHA256" ]]; then
  echo "$apk is not the original Alcazar 1.2.13 APK (SHA-256 mismatch)" >&2
  exit 1
fi

zipalign=$(build_tool zipalign)
apksigner=$(build_tool apksigner)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# --no-src copies classes.dex as it is instead of disassembling and reassembling it.
apktool decode --no-src --output "$work/app" "$apk"

# Android 14 and later refuse to install apps that target API 19. Above 34, Android forces
# edge-to-edge layout (35) and predictive back (36), which this WebView game never handled.
replace_once "$work/app/apktool.yml" "targetSdkVersion: 19" "targetSdkVersion: $TARGET_SDK"

# Apps that target API 31 or later must declare whether an activity with intent filters is exported.
replace_once "$work/app/AndroidManifest.xml" "<activity " '<activity android:exported="true" '

# The books were Google Play in-app purchases, and the game is no longer on Play.
replace_once "$work/app/assets/www/public/alcazar-min.js" \
  "if (window.SCREENSHOT || window.UNLOCK_ALL) {" "if (true) {"

apktool build --output "$work/unsigned.apk" "$work/app"
"$zipalign" -f -p 4 "$work/unsigned.apk" "$work/aligned.apk"

mkdir -p "$(dirname "$OUT")"
"$apksigner" sign --ks "$keystore" ${alias:+--ks-key-alias "$alias"} \
  --v4-signing-enabled false --out "$OUT" "$work/aligned.apk"

echo "Built $OUT"
