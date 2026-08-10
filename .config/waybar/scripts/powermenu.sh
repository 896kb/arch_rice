#!/bin/bash
# Power menu behind the waybar ⏻ button.
#
# Uses wofi, not rofi: rofi is X11-only, so under Hyprland it rendered through
# XWayland with its own acrnm.rasi theme and missed the wofi blur layerrule —
# which is why it looked like a different (older) menu. Driven through wofi it
# inherits ~/.config/wofi/style.css, so it matches $menu exactly: same ACRNM
# artwork, same colors, same blur. (Same reasoning as emoji-picker.)

action=$(printf 'Shutdown\nReboot\nCancel\n' | wofi --show dmenu --prompt "power //")

case "$action" in
    Shutdown)
        systemctl poweroff
        ;;
    Reboot)
        systemctl reboot
        ;;
    *)
        # Cancel, Esc, or wofi dismissed — do nothing.
        ;;
esac
