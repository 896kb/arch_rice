#!/bin/bash

status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ]; then
    echo "󰏤"
elif [ "$status" = "Paused" ]; then
    echo "󰐊"
else
    echo "󰐊"  # Show pause icon when no player is running
fi
