#!/bin/bash
# Fallback profile: unknown hardware. Deploys the portable subset only —
# terminal, editor, launcher, notifications, bar, theming — and assumes nothing
# about GPUs, sensors, cameras or vendor platform controls.

PROFILE_NAME="Generic"

PROFILE_FEATURES=(
    backlight
)

PROFILE_PACMAN=()
PROFILE_AUR=()

PROFILE_BIN_EXCLUDE=(
    auto-rotate
    touch-gestures
    wvkbd-toggle
    pen-screenshotd
    penbtn
    cam-clip
    cam-fullscreen
    cam-geometry
    cam-reorient
    camwidget.lua
    frontcam-widget
    rearcam-bridge
    rearcam-status
    rearcam-widget
    fan-profile-osd
    kbd-backlight
    rocker
    gpu-run
    prime-run
)

profile_system_setup() {
    :
}
