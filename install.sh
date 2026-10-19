#!/bin/bash
# Installs (or reinstalls) Chiri (formerly Pixel / Cherrybit):
#   curl -fsSL https://raw.githubusercontent.com/GorenCode/pixel-releases/main/install.sh | bash
# Downloads the latest Chiri from GitHub, puts it in Applications and opens it. After that it updates itself.
set -e

URL="https://github.com/GorenCode/pixel-releases/releases/latest/download/Pixel.zip"
echo "🍒 Installing Chiri…"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fL --progress-bar -o "$TMP/Pixel.zip" "$URL"
ditto -x -k "$TMP/Pixel.zip" "$TMP/unzipped"
[ -d "$TMP/unzipped/Pixel.app" ] || { echo "❌ The download didn't contain Pixel.app — try again."; exit 1; }

# Only the real Chiri: signed with Cherry's own certificate (pinned here), untouched since. A swapped download stops here.
REQ='identifier "app.mochi.notch" and certificate leaf = H"6b117ef4a3af28e4a81bcb927f28a868f19a7c30"'
codesign --verify --deep --strict -R="$REQ" "$TMP/unzipped/Pixel.app" >/dev/null 2>&1 || { echo "❌ This download isn't signed by Cherry — not installing it."; exit 1; }

# Applications if we may write there, otherwise the Applications folder in your home folder.
DEST="${PIXEL_DEST:-/Applications}"   # PIXEL_DEST / PIXEL_TEST: for testing the installer
[ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }

# Close a running copy (it may still be called Pixel), swap in the new one.
if [ -z "$PIXEL_TEST" ]; then
  osascript -e 'tell application id "app.mochi.notch" to quit' >/dev/null 2>&1 || true
  pkill -x Pixel >/dev/null 2>&1 || true
  pkill -x Cherrybit >/dev/null 2>&1 || true
  pkill -x Chiri >/dev/null 2>&1 || true
  sleep 1
fi
rm -rf "$DEST/Pixel.app" "$DEST/Cherrybit.app" "$DEST/Chiri.app"
ditto "$TMP/unzipped/Pixel.app" "$DEST/Chiri.app"
# Installed on purpose from here, so macOS doesn't need to ask about it again.
xattr -dr com.apple.quarantine "$DEST/Chiri.app" >/dev/null 2>&1 || true

[ -z "$PIXEL_TEST" ] && open "$DEST/Chiri.app"
echo "✅ Chiri is installed in $DEST — look at your notch! 🍒"
