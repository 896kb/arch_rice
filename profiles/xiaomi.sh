#!/bin/bash
# Xiaomi Book Pro 2022 (Timi) — Intel Alder Lake-P iGPU + NVIDIA dGPU
# (MX550 / RTX 2050), clamshell, no touchscreen, no pen, no ASUS platform.

PROFILE_NAME="Xiaomi Book Pro 2022"

PROFILE_FEATURES=(
    nvidia_prime      # dGPU offload, compositor pinned to the iGPU
    earbuds           # Xiaomi Buds 6 widget + daemon (they travel with you)
    backlight
)

PROFILE_PACMAN=(
    # NVIDIA — dkms, NOT the prebuilt `nvidia` package: this machine runs both
    # `linux` and `linux-lts`, and the prebuilt module only matches one of them.
    "nvidia-dkms"
    "nvidia-utils"
    "nvidia-settings"
    "linux-headers"
    "linux-lts-headers"

    # Intel graphics / video acceleration on Alder Lake-P
    "intel-media-driver"
    "libva-utils"
    "vulkan-intel"

    # Audio firmware — these chassis use SOF + Cirrus speaker amps
    "sof-firmware"
    "alsa-ucm-conf"

    # Power management (no ASUS platform_profile here, so EPP is the only knob)
    "power-profiles-daemon"
    "thermald"
)

PROFILE_AUR=()

# Pink accents instead of the committed green. ACCENT2 is ACCENT tinted 45%
# toward white so it keeps the hue while matching the luminance of the yellow it
# replaces — that yellow is used as a BACKGROUND behind black text (wofi
# selection, waybar highlights), so a dark pink there would be unreadable.
PROFILE_ACCENT="ff5f9e"
PROFILE_ACCENT2="ffa7ca"
PROFILE_CURSOR_THEME="Bibata-Modern-Pink"

# Lock screen: bright train-bridge clip, meant to be seen undimmed.
PROFILE_LOCK_ANIM="lock-xiaomi.gif"
PROFILE_LOCK_DIM="0"

# Z13-only tooling: tablet/pen/rotation, IPU6 rear camera, ASUS platform.
PROFILE_BIN_EXCLUDE=(
    # accelerometer / tablet
    auto-rotate
    touch-gestures
    wvkbd-toggle
    pen-screenshotd
    penbtn
    # IPU6 rear/front camera widgets + v4l2loopback bridge
    cam-clip
    cam-fullscreen
    cam-geometry
    cam-reorient
    camwidget.lua
    frontcam-widget
    rearcam-bridge
    rearcam-status
    rearcam-widget
    # ASUS platform
    fan-profile-osd
    kbd-backlight
    rocker
)

profile_system_setup() {
    rice_install_nvidia_pm

    sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null \
        && print_success "power-profiles-daemon enabled"
    sudo systemctl enable --now thermald.service 2>/dev/null \
        && print_success "thermald enabled"
}
