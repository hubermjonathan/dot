#!/usr/bin/env bash
# Remap macOS native Window Tiling hotkeys to Ctrl+Option chords.
# Idempotent: deletes each entry before rewriting.
# Run again after macOS upgrades — Apple's tiling action IDs are not
# officially documented and could change.
#
# Modifier masks:
#   Ctrl+Option       = 786432 (0xC0000)
#   Ctrl+Option+Shift = 917504 (0xE0000)
# Virtual keycodes: Left=123, Right=124, Down=125, Up=126, Return=36

set -euo pipefail

PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
PB=/usr/libexec/PlistBuddy

set_hotkey() {
  local id=$1 char=$2 vkey=$3 mods=$4
  $PB -c "Delete :AppleSymbolicHotKeys:$id" "$PLIST" 2>/dev/null || true
  $PB -c "Add :AppleSymbolicHotKeys:$id dict" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:enabled bool true" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value dict" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value:type string standard" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value:parameters array" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value:parameters: integer $char" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value:parameters: integer $vkey" "$PLIST"
  $PB -c "Add :AppleSymbolicHotKeys:$id:value:parameters: integer $mods" "$PLIST"
}

# Halves: Ctrl+Opt+Arrow
set_hotkey 240 65535 123 786432  # Left half
set_hotkey 241 65535 124 786432  # Right half
set_hotkey 242 65535 126 786432  # Top half
set_hotkey 243 65535 125 786432  # Bottom half

# Quarters: Ctrl+Opt+Shift+Arrow (clockwise from top-left)
set_hotkey 244 65535 126 917504  # Top-left  (Up)
set_hotkey 245 65535 124 917504  # Top-right (Right)
set_hotkey 247 65535 125 917504  # Bottom-right (Down)
set_hotkey 246 65535 123 917504  # Bottom-left (Left)

# Fill: Ctrl+Opt+Return
set_hotkey 237 13 36 786432

# Flush so System Settings reflects the change. Full effect requires
# logging out and back in.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "Window tiling hotkeys updated. Log out and back in for changes to take effect."
