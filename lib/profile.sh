#!/bin/bash
# Host-profile detection for arch_rice.
#
# Sourced by install.sh. Picks a profile describing what hardware this machine
# has, so one repo can serve several machines without per-host branches.
#
# Resolution order (first hit wins):
#   1. $RICE_PROFILE            — env override
#   2. --profile=<name>         — install.sh flag (exports RICE_PROFILE)
#   3. ~/.config/rice-profile   — a file containing just the profile name
#   4. DMI autodetection        — /sys/class/dmi/id/*
#   5. "generic"                — portable subset only
#
# Profiles live in profiles/<name>.sh and declare:
#   PROFILE_NAME         display name
#   PROFILE_FEATURES     feature flags (see rice_has_feature)
#   PROFILE_PACMAN       extra repo packages
#   PROFILE_AUR          extra AUR packages
#   PROFILE_BIN_EXCLUDE  ~/.local/bin scripts NOT to deploy here
#   profile_system_setup() optional hook, run late in install.sh

RICE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICE_ROOT="$(dirname "$RICE_LIB_DIR")"

# Read a DMI field, empty string if unreadable.
_dmi() { cat "/sys/class/dmi/id/$1" 2>/dev/null || true; }

# Guess the profile from firmware identifiers.
rice_detect_profile() {
    local vendor product board family
    vendor="$(_dmi sys_vendor)"
    product="$(_dmi product_name)"
    board="$(_dmi board_name)"
    family="$(_dmi product_family)"
    local all="$vendor $product $board $family"

    case "$all" in
        # ROG Flow Z13 GZ301VIC — board_name is the reliable one, product_name
        # is doubled ("GZ301VIC_GZ301VIC") on this firmware.
        *GZ301*|*"Flow Z13"*) echo "z13" ;;
        # Xiaomi/Redmi laptops report sys_vendor "Timi" (Timi Personal Computing),
        # not "Xiaomi" — match both plus the marketing name.
        *Timi*|*TIMI*|*Xiaomi*|*"Book Pro"*) echo "xiaomi" ;;
        *) echo "generic" ;;
    esac
}

# Resolve the profile name honouring every override.
rice_resolve_profile() {
    if [[ -n "${RICE_PROFILE:-}" ]]; then
        echo "$RICE_PROFILE"
    elif [[ -r "$HOME/.config/rice-profile" ]]; then
        tr -d '[:space:]' < "$HOME/.config/rice-profile"
    else
        rice_detect_profile
    fi
}

# Source profiles/<name>.sh, falling back to generic if it doesn't exist.
rice_load_profile() {
    local name="${1:-$(rice_resolve_profile)}"
    local file="$RICE_ROOT/profiles/$name.sh"

    if [[ ! -r "$file" ]]; then
        echo "profile '$name' not found in $RICE_ROOT/profiles, falling back to generic" >&2
        name="generic"
        file="$RICE_ROOT/profiles/generic.sh"
    fi

    PROFILE_NAME=""
    PROFILE_FEATURES=()
    PROFILE_PACMAN=()
    PROFILE_AUR=()
    PROFILE_BIN_EXCLUDE=()
    unset -f profile_system_setup 2>/dev/null || true

    # shellcheck source=/dev/null
    source "$file"

    RICE_PROFILE="$name"
    export RICE_PROFILE
}

# rice_has_feature nvidia_prime && ...
rice_has_feature() {
    local want="$1" f
    for f in "${PROFILE_FEATURES[@]}"; do
        [[ "$f" == "$want" ]] && return 0
    done
    return 1
}

# rice_bin_excluded auto-rotate && continue
rice_bin_excluded() {
    local want="$1" f
    for f in "${PROFILE_BIN_EXCLUDE[@]}"; do
        [[ "$f" == "$want" ]] && return 0
    done
    return 1
}

# PCI address (0000:01:00.0 form) of the first NVIDIA display-class device.
# Empty + non-zero exit if there isn't one. Used by prime/offload tooling so
# nothing has to hardcode a bus address that differs between machines.
rice_nvidia_pci() {
    local d
    for d in /sys/bus/pci/devices/*; do
        [[ "$(cat "$d/vendor" 2>/dev/null)" == "0x10de" ]] || continue
        case "$(cat "$d/class" 2>/dev/null)" in
            0x030*) basename "$d"; return 0 ;;
        esac
    done
    return 1
}
