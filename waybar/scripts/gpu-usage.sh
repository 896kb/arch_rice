#!/bin/bash

# GPU usage script for waybar with JSON output for tooltips
# Supports NVIDIA (nvidia-smi) and AMD (via sysfs)

if command -v nvidia-smi &> /dev/null; then
    # NVIDIA GPU
    info=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [[ -n "$info" ]]; then
        usage=$(echo "$info" | cut -d',' -f1 | tr -d ' ')
        temp=$(echo "$info" | cut -d',' -f2 | tr -d ' ')
        name=$(echo "$info" | cut -d',' -f3 | sed 's/^ *//')
        echo "{\"text\": \"${usage}%\", \"tooltip\": \"${name}\\nUsage: ${usage}%\\nTemp: ${temp}°C\"}"
    else
        echo "{\"text\": \"N/A\", \"tooltip\": \"GPU not available\"}"
    fi
elif [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
    # AMD GPU (amdgpu driver)
    usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null)
    temp=""
    if [[ -f /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input ]]; then
        temp_raw=$(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
        temp=$((temp_raw / 1000))
    fi
    name=$(cat /sys/class/drm/card0/device/product_name 2>/dev/null || echo "AMD GPU")
    tooltip="${name}\\nUsage: ${usage}%"
    [[ -n "$temp" ]] && tooltip="${tooltip}\\nTemp: ${temp}°C"
    echo "{\"text\": \"${usage}%\", \"tooltip\": \"${tooltip}\"}"
else
    echo "{\"text\": \"N/A\", \"tooltip\": \"No GPU detected\"}"
fi
