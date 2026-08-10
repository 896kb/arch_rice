#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Pin Hyprland to the Intel iGPU so the NVIDIA dGPU can runtime-suspend (~0W).
# Resolved dynamically here (DRM card numbers can change across kernel updates,
# and AQ_DRM_DEVICES is colon-separated so a by-path value would break it).
# Set before `start-hyprland` so the compositor inherits it.
for _card in /sys/class/drm/card[0-9]; do
    if [[ "$(basename "$(readlink -f "$_card/device/driver" 2>/dev/null)")" == i915 ]]; then
        export AQ_DRM_DEVICES="/dev/dri/$(basename "$_card")"
        break
    fi
done
unset _card
