#!/usr/bin/env bash
#
# take_screenshots.sh — Automated screenshot capture for ComicRow
#
# Connects to a running phone emulator and tablet emulator, configures an OPDS
# server, and captures screenshots of key screens.
#
# Usage:
#   ./take_screenshots.sh <server_name> <server_url> <username> <password>
#
# Example:
#   ./take_screenshots.sh "Demo OPDS" "https://opds.example.com" "user" "pass"
#
# Requirements:
#   - Two Android emulators running (phone + tablet)
#   - ComicRow debug APK installed on both
#   - adb available on PATH
#
# Output: screenshots/ directory in the project root

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────

if [ $# -lt 4 ]; then
  echo "Usage: $0 <server_name> <server_url> <username> <password>"
  echo ""
  echo "Example:"
  echo "  $0 \"Demo OPDS\" \"https://opds.example.com\" \"user\" \"pass\""
  exit 1
fi

SERVER_NAME="$1"
SERVER_URL="$2"
USERNAME="$3"
PASSWORD="$4"

# adb text input needs %s for spaces
ADB_SERVER_NAME="${SERVER_NAME// /%s}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/screenshots"
mkdir -p "$OUT_DIR"

# ── Discover emulators ────────────────────────────────────────────────────────

echo "==> Discovering emulators..."

DEVICES=()
while IFS= read -r line; do
  serial=$(echo "$line" | awk '{print $1}')
  if [[ "$serial" == emulator-* ]]; then
    DEVICES+=("$serial")
  fi
done < <(adb devices | tail -n +2)

if [ ${#DEVICES[@]} -lt 1 ]; then
  echo "ERROR: No emulators found. Start at least one emulator."
  exit 1
fi

PHONE="${DEVICES[0]}"
echo "  Phone: $PHONE"

TABLET=""
if [ ${#DEVICES[@]} -ge 2 ]; then
  TABLET="${DEVICES[1]}"
  echo "  Tablet: $TABLET"
else
  echo "  No tablet emulator found — skipping tablet screenshots."
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

adb_phone() { adb -s "$PHONE" "$@"; }
adb_tablet() { adb -s "$TABLET" "$@"; }

wait_sec() { sleep "$1"; }

screenshot() {
  local serial="$1" name="$2"
  adb -s "$serial" exec-out screencap -p > "$OUT_DIR/$name"
  echo "  📸 $name"
}

# Dump UI, parse for bounds of an element by content-desc substring
# Returns: x_center y_center
find_element() {
  local serial="$1" desc="$2"
  local xml
  xml=$(adb -s "$serial" shell "uiautomator dump /dev/tty" 2>/dev/null || true)
  # Extract bounds for matching content-desc
  local bounds
  bounds=$(echo "$xml" | grep -oP "content-desc=\"[^\"]*${desc}[^\"]*\"[^>]*bounds=\"\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]\"" | head -1 | grep -oP 'bounds="\[\K[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+' | head -1)
  if [ -z "$bounds" ]; then
    echo ""
    return
  fi
  local x1 y1 x2 y2
  x1=$(echo "$bounds" | cut -d',' -f1)
  y1=$(echo "$bounds" | cut -d',' -f2 | cut -d']' -f1)
  x2=$(echo "$bounds" | cut -d'[' -f2 | cut -d',' -f1)
  y2=$(echo "$bounds" | cut -d'[' -f2 | cut -d',' -f2 | cut -d']' -f1)
  # Fallback if parsing failed
  if [ -z "$x2" ] || [ -z "$y2" ]; then
    echo ""
    return
  fi
  local cx=$(( (x1 + x2) / 2 ))
  local cy=$(( (y1 + y2) / 2 ))
  echo "$cx $cy"
}

tap_element() {
  local serial="$1" desc="$2"
  local coords
  coords=$(find_element "$serial" "$desc")
  if [ -z "$coords" ]; then
    echo "  WARNING: Could not find element '$desc' — trying fallback"
    return 1
  fi
  local cx cy
  cx=$(echo "$coords" | cut -d' ' -f1)
  cy=$(echo "$coords" | cut -d' ' -f2)
  adb -s "$serial" shell "input tap $cx $cy"
  return 0
}

wait_for_element() {
  local serial="$1" desc="$2" timeout="${3:-15}"
  local elapsed=0
  while [ $elapsed -lt "$timeout" ]; do
    local coords
    coords=$(find_element "$serial" "$desc")
    if [ -n "$coords" ]; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  echo "  WARNING: Timed out waiting for '$desc'"
  return 1
}

# ── Fill form and save server ─────────────────────────────────────────────────

setup_server() {
  local serial="$1"
  echo "  Clearing app data..."
  adb -s "$serial" shell "pm clear com.nadiar.comicrow" > /dev/null

  echo "  Launching app..."
  adb -s "$serial" shell "am start -n com.nadiar.comicrow/.MainActivity" > /dev/null
  wait_sec 4

  echo "  Waiting for Add Server screen..."
  wait_for_element "$serial" "Add Server" 10

  echo "  Filling form..."
  # Dump UI to find field positions
  local xml
  xml=$(adb -s "$serial" shell "uiautomator dump /dev/tty" 2>/dev/null || true)

  # Extract EditText bounds (4 fields: name, url, username, password)
  local fields=()
  while IFS= read -r b; do
    local x1 y1 x2 y2
    x1=$(echo "$b" | grep -oP '^\[?\K[0-9]+' | head -1)
    y1=$(echo "$b" | grep -oP ',[0-9]+' | head -1 | tr -d ',')
    x2=$(echo "$b" | grep -oP '\]\[\K[0-9]+')
    y2=$(echo "$b" | grep -oP '\]\[[0-9]+,\K[0-9]+')
    local cx=$(( (x1 + x2) / 2 ))
    local cy=$(( (y1 + y2) / 2 ))
    fields+=("$cx,$cy")
  done < <(echo "$xml" | grep -oP 'class="android.widget.EditText"[^>]*bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | grep -oP 'bounds="\K\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]')

  if [ ${#fields[@]} -lt 4 ]; then
    echo "  ERROR: Found only ${#fields[@]} text fields, expected 4"
    return 1
  fi

  # Fill each field: tap, wait, type
  local values=("$ADB_SERVER_NAME" "$SERVER_URL" "$USERNAME" "$PASSWORD")
  local names=("Server name" "URL" "Username" "Password")
  for i in 0 1 2 3; do
    local cx cy
    cx=$(echo "${fields[$i]}" | cut -d',' -f1)
    cy=$(echo "${fields[$i]}" | cut -d',' -f2)
    adb -s "$serial" shell "input tap $cx $cy"
    wait_sec 1
    adb -s "$serial" shell "input text '${values[$i]}'"
    wait_sec 0.5
    echo "    Filled ${names[$i]}"
  done

  # Dismiss keyboard
  adb -s "$serial" shell "input keyevent 111"
  wait_sec 0.5

  # Tap Test Connection
  echo "  Testing connection..."
  tap_element "$serial" "Test Connection"
  wait_sec 1
  wait_for_element "$serial" "Connected" 15

  # Tap Save Server
  echo "  Saving server..."
  wait_sec 1
  tap_element "$serial" "Save Server"
  wait_sec 3

  # Wait for Library to load
  wait_for_element "$serial" "Library" 10
  echo "  Server configured ✓"
}

# ── Phone screenshots ─────────────────────────────────────────────────────────

capture_phone() {
  local S="$PHONE"
  echo ""
  echo "==> Phone screenshots"

  setup_server "$S"

  # 1. Library
  wait_sec 2
  screenshot "$S" "phone_library.png"

  # 2. Reader — tap first comic
  echo "  Opening comic..."
  # Find first Publication ImageView and tap it
  local xml
  xml=$(adb -s "$S" shell "uiautomator dump /dev/tty" 2>/dev/null || true)
  local first_comic
  first_comic=$(echo "$xml" | grep -oP 'class="android.widget.ImageView"[^>]*content-desc="[^"]*Publication"[^>]*bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | head -1 | grep -oP 'bounds="\K\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]')
  if [ -n "$first_comic" ]; then
    local x1 y1 x2 y2
    x1=$(echo "$first_comic" | grep -oP '^\[?\K[0-9]+' | head -1)
    y1=$(echo "$first_comic" | grep -oP ',[0-9]+' | head -1 | tr -d ',')
    x2=$(echo "$first_comic" | grep -oP '\]\[\K[0-9]+')
    y2=$(echo "$first_comic" | grep -oP '\]\[[0-9]+,\K[0-9]+')
    local cx=$(( (x1 + x2) / 2 ))
    local cy=$(( (y1 + y2) / 2 ))
    adb -s "$S" shell "input tap $cx $cy"
  fi
  wait_sec 3

  # Tap Read
  tap_element "$S" "Read"
  wait_sec 5

  # 3. Reader with controls
  screenshot "$S" "phone_reader.png"

  # 4. Swipe to page 4, tap center to hide controls
  local screen_w screen_h
  screen_w=$(adb -s "$S" shell "wm size" | grep -oP '[0-9]+x[0-9]+' | cut -dx -f1)
  screen_h=$(adb -s "$S" shell "wm size" | grep -oP '[0-9]+x[0-9]+' | cut -dx -f2)
  local mid_y=$((screen_h / 2))
  local swipe_from=$((screen_w * 3 / 4))
  local swipe_to=$((screen_w / 4))

  adb -s "$S" shell "input swipe $swipe_from $mid_y $swipe_to $mid_y 300"
  wait_sec 1
  adb -s "$S" shell "input swipe $swipe_from $mid_y $swipe_to $mid_y 300"
  wait_sec 1
  adb -s "$S" shell "input swipe $swipe_from $mid_y $swipe_to $mid_y 300"
  wait_sec 2
  # Tap center to hide controls
  adb -s "$S" shell "input tap $((screen_w / 2)) $mid_y"
  wait_sec 2

  screenshot "$S" "phone_reader_page.png"

  # 5. Back to library
  adb -s "$S" shell "input keyevent 4"
  wait_sec 2
  # If we get a detail sheet, press back again
  local check
  check=$(find_element "$S" "Library")
  if [ -z "$check" ]; then
    adb -s "$S" shell "input keyevent 4"
    wait_sec 2
  fi

  # 6. Settings
  tap_element "$S" "Settings"
  wait_sec 2
  screenshot "$S" "phone_settings.png"

  # 7. Navigate back to Library for drawer
  # Tap Libraries to open drawer, then tap server to go to Library
  tap_element "$S" "Libraries"
  wait_sec 1
  # Find the server entry in drawer and tap it
  local server_coords
  server_coords=$(find_element "$S" "$SERVER_NAME")
  if [ -n "$server_coords" ]; then
    local cx cy
    cx=$(echo "$server_coords" | cut -d' ' -f1)
    cy=$(echo "$server_coords" | cut -d' ' -f2)
    adb -s "$S" shell "input tap $cx $cy"
    wait_sec 2
  fi

  # Verify on Library
  wait_for_element "$S" "Library" 5

  # 8. Open drawer from Library and screenshot
  tap_element "$S" "Libraries"
  wait_sec 2
  screenshot "$S" "phone_drawer.png"

  echo "  Phone screenshots complete ✓"
}

# ── Tablet screenshots ────────────────────────────────────────────────────────

capture_tablet() {
  if [ -z "$TABLET" ]; then
    echo ""
    echo "==> Skipping tablet (no second emulator)"
    return
  fi

  local S="$TABLET"
  echo ""
  echo "==> Tablet screenshots"

  setup_server "$S"

  # Verify on Library
  wait_for_element "$S" "Library" 5

  # Open drawer from Library
  tap_element "$S" "Libraries"
  wait_sec 2
  screenshot "$S" "tablet_drawer.png"

  echo "  Tablet screenshots complete ✓"
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo "ComicRow Screenshot Generator"
echo "=============================="
echo "Server: $SERVER_NAME"
echo "URL:    $SERVER_URL"
echo "Output: $OUT_DIR"
echo ""

# Clean old screenshots
rm -f "$OUT_DIR"/*.png

capture_phone
capture_tablet

echo ""
echo "==> All done! Screenshots saved to: $OUT_DIR"
ls -la "$OUT_DIR"/*.png 2>/dev/null || echo "  (no screenshots found)"
