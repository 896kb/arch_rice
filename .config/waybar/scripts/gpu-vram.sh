#!/bin/bash

# VRAM usage script for waybar with JSON output for tooltips
# Supports NVIDIA (nvidia-smi) and AMD (via sysfs)

if command -v nvidia-smi &> /dev/null; then
    # Only poll the dGPU if it's awake AND actually in use (fuser detects an open
    # handle). Otherwise show 'zzz' and don't touch it, so it can suspend / stay
    # suspended (polling an idle-but-active dGPU would block it from sleeping).
    if [[ "$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null)" != "active" ]] || ! fuser -s /dev/nvidia0 2>/dev/null; then
        echo "{\"text\": \"zzz\", \"tooltip\": \"dGPU asleep (no GPU app running)\", \"class\": \"asleep\"}"
        exit 0
    fi
    # NVIDIA GPU - get used/total memory in MiB
    mem_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [[ -n "$mem_info" ]]; then
        used=$(echo "$mem_info" | cut -d',' -f1 | tr -d ' ')
        total=$(echo "$mem_info" | cut -d',' -f2 | tr -d ' ')
        if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
            percent=$((used * 100 / total))
            used_gb=$(awk "BEGIN {printf \"%.1f\", $used/1024}")
            total_gb=$(awk "BEGIN {printf \"%.1f\", $total/1024}")
            echo "{\"text\": \"${percent}%\", \"tooltip\": \"VRAM Usage\\n${used_gb} / ${total_gb} GB (${percent}%)\"}"
        else
            echo "{\"text\": \"N/A\", \"tooltip\": \"VRAM not available\"}"
        fi
    else
        echo "{\"text\": \"N/A\", \"tooltip\": \"VRAM not available\"}"
    fi
elif [[ -f /sys/class/drm/card0/device/mem_info_vram_used ]]; then
    # AMD GPU (amdgpu driver)
    used=$(cat /sys/class/drm/card0/device/mem_info_vram_used 2>/dev/null)
    total=$(cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null)
    if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
        percent=$((used * 100 / total))
        used_gb=$(awk "BEGIN {printf \"%.1f\", $used/1073741824}")
        total_gb=$(awk "BEGIN {printf \"%.1f\", $total/1073741824}")
        echo "{\"text\": \"${percent}%\", \"tooltip\": \"VRAM Usage\\n${used_gb} / ${total_gb} GB (${percent}%)\"}"
    else
        echo "{\"text\": \"N/A\", \"tooltip\": \"VRAM not available\"}"
    fi
else
    echo "{\"text\": \"N/A\", \"tooltip\": \"No GPU detected\"}"
fi
