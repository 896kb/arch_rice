#!/bin/bash
# ASUS ROG Flow Z13 (GZ301VIC) — Intel iGPU + NVIDIA RTX 4070 dGPU, detachable
# keyboard, touchscreen + pen, IPU6 rear camera, ASUS platform controls.

PROFILE_NAME="ROG Flow Z13 (GZ301VIC)"

PROFILE_FEATURES=(
    nvidia_prime      # dGPU offload, compositor pinned to the iGPU
    asus_platform     # asusctl, fan/perf profile OSD, keyboard backlight
    keyd              # volume-rocker remap (system/keyd-default.conf)
    ipu6_camera       # rear OV13B10 on IPU6 + v4l2loopback bridge
    tablet            # accelerometer rotation, pen, on-screen keyboard, gestures
    earbuds           # Xiaomi Buds 6 widget + daemon
    backlight
)

PROFILE_PACMAN=(
    # hardware
    "iio-sensor-proxy"            # accelerometer -> auto-rotate
    "keyd"                        # volume-rocker key remap
    "v4l2loopback-dkms"           # rear IPU6 camera -> browser loopback
    "linux-headers"               # build the v4l2loopback dkms module
    "python-evdev"                # pen-screenshotd
)

PROFILE_AUR=(
    "asusctl"                     # fan/perf profile + keyboard-backlight LEDs
    "lisgd"                       # touchscreen edge gestures
    "light"                       # backlight control for the rocker's brightness mode
    "wvkbd"                       # on-screen touch keyboard
)

# Canonical colours — the repo is stored in this machine's palette, so no
# recoloured mirror is generated and the repo is deployed directly.
PROFILE_ACCENT="b5bd68"
PROFILE_ACCENT2="ffff78"
PROFILE_CURSOR_THEME="Bibata-Modern-Green"

# Lock screen: dark bus-stop clip, so a light dim keeps the clock readable.
PROFILE_LOCK_ANIM="lock-z13.gif"
PROFILE_LOCK_DIM="0.45"

# Everything in .local/bin deploys here — this is the machine they were written for.
PROFILE_BIN_EXCLUDE=()

profile_system_setup() {
    # keyd: volume-rocker / brightness key remap (config tracked in system/)
    if [[ -f "$RICE_ROOT/system/keyd-default.conf" ]]; then
        sudo mkdir -p /etc/keyd
        sudo cp "$RICE_ROOT/system/keyd-default.conf" /etc/keyd/default.conf
        sudo systemctl enable --now keyd.service 2>/dev/null \
            && print_success "keyd (volume rocker) enabled"
    fi

    rice_install_nvidia_pm

    # iio-sensor-proxy is dbus-activated (auto-rotate uses it). NOTE: on this device
    # it can hang suspend in D-state — the fix is a systemd system-sleep hook (see
    # the suspend notes in README), not here.
}
