#!/bin/bash

# Network info script for waybar with public IP in tooltip

# Cache public IP (refresh every 5 minutes to avoid too many requests)
CACHE_FILE="/tmp/waybar-public-ip"
CACHE_MAX_AGE=300

get_public_ip() {
    if [[ -f "$CACHE_FILE" ]]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    # Try multiple services in case one is down
    public_ip=$(curl -s --max-time 2 ifconfig.me 2>/dev/null || \
                curl -s --max-time 2 icanhazip.com 2>/dev/null || \
                curl -s --max-time 2 ipinfo.io/ip 2>/dev/null || \
                echo "N/A")
    echo "$public_ip" > "$CACHE_FILE"
    echo "$public_ip"
}

# Get default interface
iface=$(ip route | grep default | awk '{print $5}' | head -n1)

if [[ -z "$iface" ]]; then
    echo '{"text": "󰤭", "tooltip": "Disconnected"}'
    exit 0
fi

# Get local IP
local_ip=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
gateway=$(ip route | grep default | awk '{print $3}' | head -n1)

# Determine connection type
if [[ "$iface" == wl* || "$iface" == wlan* ]]; then
    # WiFi
    essid=$(iwgetid -r 2>/dev/null || echo "Unknown")
    signal=$(awk 'NR==3 {print int($3 * 100 / 70)}' /proc/net/wireless 2>/dev/null || echo "")
    text="󰤨 ${essid}"
    conn_type="WiFi"
    [[ -n "$signal" ]] && conn_type="WiFi (${signal}%)"
else
    # Ethernet
    text="󰈀 ${local_ip}"
    conn_type="Ethernet"
fi

# Get public IP (cached)
public_ip=$(get_public_ip)

# Build tooltip
tooltip="${conn_type}\\nInterface: ${iface}\\nLocal IP: ${local_ip}\\nGateway: ${gateway}\\nPublic IP: ${public_ip}"

echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\"}"
