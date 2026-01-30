#!/bin/bash

# CPU info script for waybar with temperature and per-core usage in tooltip
# Uses delta calculation for accurate dynamic usage

CACHE_FILE="/tmp/waybar-cpu-stat"

# Read current /proc/stat
declare -A curr_total curr_idle
while read -r cpu user nice system idle iowait irq softirq steal rest; do
    if [[ "$cpu" =~ ^cpu([0-9]*)$ ]]; then
        core="${BASH_REMATCH[1]}"
        [[ -z "$core" ]] && core="total"
        curr_total[$core]=$((user + nice + system + idle + iowait + irq + softirq + steal))
        curr_idle[$core]=$idle
    fi
done < /proc/stat

# Read previous values if cache exists
declare -A prev_total prev_idle
if [[ -f "$CACHE_FILE" ]]; then
    while IFS=',' read -r core total idle; do
        prev_total[$core]=$total
        prev_idle[$core]=$idle
    done < "$CACHE_FILE"
fi

# Save current values for next run
> "$CACHE_FILE"
for core in "${!curr_total[@]}"; do
    echo "${core},${curr_total[$core]},${curr_idle[$core]}" >> "$CACHE_FILE"
done

# Calculate usage
calc_usage() {
    local core=$1
    if [[ -n "${prev_total[$core]}" ]]; then
        local total_delta=$((curr_total[$core] - prev_total[$core]))
        local idle_delta=$((curr_idle[$core] - prev_idle[$core]))
        if [[ $total_delta -gt 0 ]]; then
            echo $(( (total_delta - idle_delta) * 100 / total_delta ))
            return
        fi
    fi
    echo "0"
}

# Get overall usage
usage=$(calc_usage "total")

# Get per-core usage
core_usage=""
for i in $(seq 0 $(($(nproc) - 1))); do
    core_pct=$(calc_usage "$i")
    core_usage="${core_usage}Core ${i}: $(printf '%3s' "${core_pct}")%\\n"
done

# Get CPU temperature
temp=""
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    temp=$((temp_raw / 1000))
elif command -v sensors &> /dev/null; then
    temp=$(sensors 2>/dev/null | grep -E '(Core 0|Tctl|CPU)' | head -n1 | grep -oP '\+\K[0-9.]+' | cut -d. -f1)
fi

# Get CPU model name
cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//' | sed 's/(R)//g' | sed 's/(TM)//g')

# Get core count
cores=$(nproc)

# Build tooltip
tooltip="${cpu_model}\\nCores: ${cores}"
[[ -n "$temp" ]] && tooltip="${tooltip}  |  Temp: ${temp}°C"
tooltip="${tooltip}\\n\\n${core_usage%\\n}"

echo "{\"text\": \"${usage}%\", \"tooltip\": \"${tooltip}\"}"
