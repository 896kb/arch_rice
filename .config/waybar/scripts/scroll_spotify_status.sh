#!/bin/bash

# Kill any existing zscroll processes for this script to prevent duplicates
pkill -f "zscroll.*spotify" 2>/dev/null

# Function to get spotify info
get_spotify_info() {
    playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null
}

# Check if player is running
if ! playerctl status &>/dev/null; then
    echo ""
    exit 0
fi

# Get current song
current_song=$(get_spotify_info)

if [ -z "$current_song" ]; then
    echo ""
else
    # Use zscroll with error suppression
    echo "$current_song" | zscroll -l 30 -d 0.3 -s 1 2>/dev/null &
    
    # Alternative without zscroll if it keeps causing issues:
    # Truncate to 30 chars
    # if [ ${#current_song} -gt 30 ]; then
    #     echo "${current_song:0:27}..."
    # else
    #     echo "$current_song"
    # fi
fi

