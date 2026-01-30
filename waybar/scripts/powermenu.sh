#!/bin/bash

action=$(echo -e "Shutdown\nReboot\nCancel" | rofi -dmenu -p "Power Menu")

case "$action" in
    Shutdown)
        poweroff
        ;;
    Reboot)
        reboot
        ;;
    *)
        ;;
esac
