# clamshell-battery

Run an Apple Silicon MacBook with the lid closed and **no external display**, on
battery — normally macOS forces sleep in this situation since "real" clamshell
mode requires an external display (and used to require an external
keyboard/mouse too).

This works by toggling `IOPMrootDomain`'s `SleepDisabled` flag via
`pmset -a disablesleep`, which disables *all* system sleep, not just the
lid-close case. There is no display to warn you of thermal issues once the lid
is shut, so keep the fans up (e.g. via a fan-control app) and don't leave it
closed unattended for long stretches.

## Contents

- `bin/clamshell-toggle.sh` — `enable` / `disable` / `toggle` / `status`
- `sudoers/clamshell-battery.template` — scoped NOPASSWD rule, allows only the
  exact `pmset -a disablesleep 0` / `1` commands as root, nothing else
- `karabiner/clamshell_battery.json.template` — Karabiner Elements complex
  modification, binds toggle to `Left Control + Left Shift + Left Command + L`
- `menubar/` — a small native Swift menu bar app (🔓/🔒 status, separate
  Enable/Disable menu items), plus a LaunchAgent template to run it in the
  background permanently
- `install.sh` — fills in the `.template` files with this checkout's actual
  path and the current user, and wires everything up

Nothing under version control hardcodes a machine-specific path or username —
`install.sh` generates the real, installed copies (in `/etc/sudoers.d/`,
`~/.config/karabiner/...`, `~/Library/LaunchAgents/...`) from these templates
at install time.

## Install

```
./install.sh
```

This will:
1. Prompt for your password once to install the sudoers rule.
2. Generate the Karabiner complex modification into your Karabiner assets
   folder.
3. Build the menu bar app and register it as a LaunchAgent (auto-starts at
   login, survives restarts).

Then, one-time manual step: open Karabiner-Elements → Complex Modifications →
Add Rule → enable "Toggle clamshell-on-battery mode" (Karabiner doesn't
auto-enable rules it discovers, and won't pick up a regenerated path if you'd
already added an older copy — remove and re-add the rule in that case).

## Usage

- Hotkey: `Left Control + Left Shift + Left Command + L`
- Menu bar: click the 🔓/🔒 icon, click Enable or Disable
- CLI: `bin/clamshell-toggle.sh {enable|disable|toggle|status}`

Always flip it back to `disable` when you're done — leaving `disablesleep`
set means the Mac won't sleep even sitting open on your desk.
