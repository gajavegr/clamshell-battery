#!/bin/bash
# Toggle "clamshell on battery, no external display" mode by flipping
# IOPMrootDomain's SleepDisabled flag via `pmset -a disablesleep`.
#
# Passwordless because of the scoped NOPASSWD sudoers rule installed by
# ../install.sh (see ../sudoers/clamshell-battery) — it only ever allows
# exactly `pmset -a disablesleep 0` and `pmset -a disablesleep 1`, nothing else.

set -euo pipefail

PMSET=/usr/bin/pmset

is_enabled() {
  # Capture ioreg's output fully before grepping it — piping directly into
  # `grep -q` lets grep exit (and close its end of the pipe) the moment it
  # finds a match, which can SIGPIPE-kill ioreg mid-write. Under `pipefail`
  # that makes the pipeline report failure even though grep matched.
  local out
  out=$(ioreg -n IOPMrootDomain)
  grep -q '"SleepDisabled" = Yes' <<< "$out"
}

notify() {
  # best-effort desktop notification; safe to fail if osascript unavailable
  osascript -e "display notification \"$1\" with title \"Clamshell Battery Mode\"" >/dev/null 2>&1 || true
}

case "${1:-toggle}" in
  enable)
    sudo "$PMSET" -a disablesleep 1
    notify "Enabled — lid can stay closed on battery"
    ;;
  disable)
    sudo "$PMSET" -a disablesleep 0
    notify "Disabled — normal sleep behavior restored"
    ;;
  toggle)
    if is_enabled; then
      sudo "$PMSET" -a disablesleep 0
      notify "Disabled — normal sleep behavior restored"
    else
      sudo "$PMSET" -a disablesleep 1
      notify "Enabled — lid can stay closed on battery"
    fi
    ;;
  status)
    if is_enabled; then echo "enabled"; else echo "disabled"; fi
    ;;
  *)
    echo "Usage: $0 {enable|disable|toggle|status}" >&2
    exit 1
    ;;
esac
