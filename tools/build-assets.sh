#!/usr/bin/env bash
# Regenerate the rice's binary assets from their originals.
#
# The lock animations and wallpapers are committed as finished files, but they
# are DERIVED — and the derivation is fiddly enough that rebuilding it from
# memory later would be painful. This script is the record.
#
#   ./tools/build-assets.sh lock-z13
#   ./tools/build-assets.sh lock-xiaomi
#   ./tools/build-assets.sh wallpaper-z13
#   ./tools/build-assets.sh wallpaper-xiaomi
#   ./tools/build-assets.sh all
#
# Sources are expected in ~/Downloads (they are NOT committed — 4K masters are
# 5-11MB each and only needed when rebuilding).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${SRC_DIR:-$HOME/Downloads}"
LOCK="$REPO/.config/quickshell/lock"
CONF="$REPO/.config"

need() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
need ffmpeg; need magick

# --- lock animations --------------------------------------------------------
# GIF, not video. QtMultimedia loads its plugin on the MAIN THREAD and blocks it
# for ~3.3s, which froze the lock and swallowed keystrokes typed during that
# window. AnimatedImage goes through QtQuick's image pipeline: ready in ~112ms
# with zero blocking. Measured, see the lock commit.
#
# 640x400 is chosen so the nearest-neighbour upscale is an exact integer on both
# panels: 4x to the Z13's 2560x1600, 6x to the Xiaomi's 3840x2400. A non-integer
# factor makes pixel blocks alternate widths, which is very visible on pixel art.
#
# The source is 16:9 and both panels are 16:10, so crop width to 3456 (=2160*1.6)
# rather than letting the surface crop at runtime.
build_lock() { # <source-file> <output-name> <fps> <colors>
    local src="$SRC/$1" out="$LOCK/$2" fps="$3" colors="$4"
    [ -f "$src" ] || { echo "source not found: $src" >&2; return 1; }
    echo "building $2 from $1 (${fps}fps, ${colors} colours)"
    # TWO passes, deliberately. Going straight from the 4K master to GIF keeps
    # all the high-frequency detail, which eats palette entries: 2.9M versus
    # 1.5M, measured, at identical settings. The h264 CRF-28 intermediate is
    # doing denoise work — lossy quantisation flattens exactly the noise that
    # GIF cannot encode cheaply. Palette/fps tuning cannot substitute: dropping
    # to 64 colours at 12fps only reaches 1.8M and visibly degrades.
    # Do not "simplify" this into a single ffmpeg invocation.
    local mid; mid="$(mktemp --suffix=.mp4)"
    ffmpeg -y -v error -i "$src" \
        -vf "crop=3456:2160,scale=1280:800:flags=area" -an \
        -c:v libx264 -crf 28 -preset slow -pix_fmt yuv420p "$mid"
    ffmpeg -y -v error -i "$mid" \
        -vf "fps=$fps,scale=640:400:flags=area,split[a][b];[a]palettegen=max_colors=$colors[p];[b][p]paletteuse=dither=none" \
        "$out"
    rm -f "$mid"
    echo "  -> $(du -h "$out" | cut -f1)"
}

# --- wallpapers -------------------------------------------------------------
# The Z13 wallpaper is the ACRNM scene hue-rotated from red to the accent green,
# dimmed, with three accent marks along the bottom.
#
# The rotation is +66 degrees because the source reds sit at hue ~0 and #b5bd68
# is at 66. It is applied ONLY inside a mask of red-ish saturated pixels: a
# global rotation also drags the teal signage to purple, which fights the rice.
#
# Marks are the wallpaper's own glyph, 363x94, recoloured by using its luminance
# as an alpha channel so only the strokes are drawn (cropping it straight out of
# the old opaque-black wallpaper brought a black box with it).
#
# Placement: symmetric 120px margins, middle mark exactly canvas-centred, and all
# three sit 120px above the waybar — which is height 27 + margin 4 = 31 logical
# = 39 physical px at scale 1.25. Marks are composited AFTER the dim so they stay
# at full strength.
build_wallpaper_z13() {
    local src="$SRC/wallpaper-acrnm.jpg" out="$CONF/background-z13.jpg"
    [ -f "$src" ] || { echo "source not found: $src" >&2; return 1; }
    local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
    local hue; hue="$(python3 -c 'print(100+66/1.8)')"   # -modulate: 100 = no shift, +1 = +1.8deg

    magick "$src" -gravity center -crop 2880x1800+0+0 +repage -resize 2560x1600 "$tmp/base.png"
    magick "$tmp/base.png" -colorspace HSL -channel R -separate +channel \
        -fx "(u<=0.11||u>=0.89)?1:0" "$tmp/m-hue.png"
    magick "$tmp/base.png" -colorspace HSL -channel G -separate +channel \
        -fx "u>0.15?1:0" "$tmp/m-sat.png"
    magick "$tmp/m-hue.png" "$tmp/m-sat.png" -compose Multiply -composite -blur 0x1 "$tmp/mask.png"
    magick "$tmp/base.png" -modulate 100,100,"$hue" "$tmp/rot.png"
    magick "$tmp/base.png" "$tmp/rot.png" "$tmp/mask.png" -compose over -composite "$tmp/greened.png"
    magick "$tmp/greened.png" -modulate 70,100,100 "$tmp/dimmed.png"

    # Marks: luminance -> alpha, so only the strokes survive.
    # The glyph is its OWN tracked asset. It used to be cropped out of
    # background.png at a fixed offset, which broke silently the moment that
    # wallpaper changed — the rebuild produced a wallpaper with no marks at all
    # and nothing errored.
    magick "$CONF/acrnm-mark.png" \
        -background black -alpha remove -alpha off -colorspace gray "$tmp/lum.png"
    local i=0
    for pair in "ffffff:120" "ffff78:1098" "b5bd68:2077"; do
        magick -size 363x94 xc:"#${pair%%:*}" "$tmp/lum.png" -alpha off \
            -compose CopyOpacity -composite "$tmp/mark-$i.png"
        i=$((i+1))
    done
    magick "$tmp/dimmed.png" \
        "$tmp/mark-0.png" -geometry +120+1347  -composite \
        "$tmp/mark-1.png" -geometry +1098+1347 -composite \
        "$tmp/mark-2.png" -geometry +2077+1347 -composite \
        -quality 92 "$out"
    echo "wallpaper-z13 -> $(du -h "$out" | cut -f1)"
}

# Xiaomi: 3200x1800 (16:9) centre-cropped to 2880x1800 for its 16:10 panel. No
# hue work — this one is used as drawn.
build_wallpaper_xiaomi() {
    local src="$SRC/wallpaper-xiaomi.jpg" out="$CONF/background-xiaomi.jpg"
    [ -f "$src" ] || { echo "source not found: $src" >&2; return 1; }
    magick "$src" -gravity center -crop 2880x1800+0+0 +repage -quality 90 "$out"
    echo "wallpaper-xiaomi -> $(du -h "$out" | cut -f1)"
}

case "${1:-all}" in
    lock-z13)         build_lock bus-stop-pixel-lock.mp4    lock-z13.gif    15 128 ;;
    lock-xiaomi)      build_lock train-bridge-pixel-lock.mp4 lock-xiaomi.gif 15 128 ;;
    wallpaper-z13)    build_wallpaper_z13 ;;
    wallpaper-xiaomi) build_wallpaper_xiaomi ;;
    all)
        build_lock bus-stop-pixel-lock.mp4     lock-z13.gif    15 128 || true
        build_lock train-bridge-pixel-lock.mp4 lock-xiaomi.gif 15 128 || true
        build_wallpaper_z13    || true
        build_wallpaper_xiaomi || true
        ;;
    *) echo "usage: $0 {lock-z13|lock-xiaomi|wallpaper-z13|wallpaper-xiaomi|all}" >&2; exit 1 ;;
esac
