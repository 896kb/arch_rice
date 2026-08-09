#!/usr/bin/env bash
# Waybar screen-brightness module. Reads the real backlight device
# (nvidia_wmi_ec_backlight on this machine; intel_backlight is absent).
# Refreshed instantly by `rocker` via SIGRTMIN+8 after a brightness change.
BL=$(ls -d /sys/class/backlight/*/ 2>/dev/null | head -1)
cur=$(cat "$BL/brightness" 2>/dev/null || echo 0)
max=$(cat "$BL/max_brightness" 2>/dev/null || echo 1)
pct=$(( cur * 100 / max ))
printf '{"text":"󰃞 %3d%%","tooltip":"Screen brightness %d%%"}\n' "$pct" "$pct"
