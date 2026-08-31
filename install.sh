#!/bin/bash
# Installs:
#  1. A scoped sudoers rule so the toggle script can run `pmset -a disablesleep`
#     without a password prompt (needed since Karabiner/the menu bar app have
#     no TTY).
#  2. The Karabiner Elements complex modification (hotkey).
#  3. The native menu bar status app, registered as a LaunchAgent.
#
# All paths/usernames are filled in from this checkout's actual location and
# the current user, via the .template files — nothing here is hardcoded to
# any one machine. Safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOGGLE_SCRIPT="$REPO_DIR/bin/clamshell-toggle.sh"
CURRENT_USER="$(whoami)"

echo "== 1/3: sudoers rule =="
SUDOERS_TMP="$(mktemp)"
sed "s/{{USER}}/$CURRENT_USER/" "$REPO_DIR/sudoers/clamshell-battery.template" > "$SUDOERS_TMP"
SUDOERS_DST="/etc/sudoers.d/clamshell-battery"
if [ -f "$SUDOERS_DST" ] && sudo cmp -s "$SUDOERS_TMP" "$SUDOERS_DST" 2>/dev/null; then
  echo "already installed and up to date"
else
  echo "validating syntax..."
  sudo visudo -cf "$SUDOERS_TMP"
  echo "installing to $SUDOERS_DST (requires your password)..."
  sudo install -m 0440 -o root -g wheel "$SUDOERS_TMP" "$SUDOERS_DST"
  sudo visudo -cf "$SUDOERS_DST"
  echo "installed."
fi
rm -f "$SUDOERS_TMP"

echo
echo "== 2/3: Karabiner Elements complex modification =="
KARABINER_DIR="$HOME/.config/karabiner/assets/complex_modifications"
mkdir -p "$KARABINER_DIR"
sed "s#{{TOGGLE_SCRIPT}}#$TOGGLE_SCRIPT#" "$REPO_DIR/karabiner/clamshell_battery.json.template" \
  > "$KARABINER_DIR/clamshell_battery.json"
echo "generated into $KARABINER_DIR"
echo "NOTE: open Karabiner-Elements -> Complex Modifications -> Add Rule,"
echo "      then enable 'Toggle clamshell-on-battery mode' (one-time manual step;"
echo "      Karabiner does not auto-enable rules it discovers). If you already"
echo "      added it from an older copy of this file, remove and re-add the"
echo "      rule so it picks up the regenerated shell_command path."

echo
echo "== 3/3: menu bar status app (LaunchAgent) =="
"$REPO_DIR/menubar/build.sh"
EXECUTABLE_PATH="$REPO_DIR/menubar/build/ClamshellStatusBar"

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENT_DIR"
PLIST_DST="$LAUNCH_AGENT_DIR/com.clamshell-battery.status.plist"
sed "s#{{EXECUTABLE_PATH}}#$EXECUTABLE_PATH#" \
  "$REPO_DIR/menubar/com.clamshell-battery.status.plist.template" > "$PLIST_DST"

launchctl bootout "gui/$(id -u)/com.clamshell-battery.status" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl enable "gui/$(id -u)/com.clamshell-battery.status"
echo "menu bar app installed and running as a LaunchAgent (survives logout/restart)."

echo
echo "Done. Hotkey: Left Control + Left Shift + Left Command + L (once enabled in Karabiner)."
