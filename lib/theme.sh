#!/bin/bash
# Per-host accent theming for arch_rice.
#
# The repo is the single source of truth and is stored in the CANONICAL colours
# (the green rice). A profile that wants different accents declares them, and
# install.sh generates a recoloured *mirror* of .config/ and .local/ which it
# then deploys instead of the repo itself.
#
# In the mirror, a file that carries an accent colour is a real recoloured copy;
# every other file is a symlink straight back into the repo, so editing configs
# on a themed machine still edits the repo for anything colour-free. After
# changing a colour-bearing file, re-run install.sh to regenerate the mirror.
#
# Profiles declare:
#   PROFILE_ACCENT        primary accent, replaces the canonical green
#   PROFILE_ACCENT2       secondary accent, replaces the canonical yellow
#   PROFILE_CURSOR_THEME  generated Bibata theme name (built from PROFILE_ACCENT)

# Canonical colours as committed. Hex WITHOUT the leading '#' so the same value
# matches "#b5bd68" (CSS), "rgb(b5bd68)" (hyprland) and bare hex (lua/scripts).
RICE_CANON_ACCENT="b5bd68"
RICE_CANON_ACCENT2="ffff78"

# Not every config spells colours in hex. hyprlock.conf uses decimal tuples —
# rgba(181, 189, 104, 1.0) — and matching only the hex form recoloured its
# COMMENTS while leaving the actual colours green (caught 2026-08-10). Both
# notations are derived from the same hex so they can never drift apart.

# hex6 -> "R, G, B"
_rice_dec() { printf '%d, %d, %d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

# hex6 -> regex matching "R, G, B" with any spacing
_rice_dec_re() { printf '%d,[[:space:]]*%d,[[:space:]]*%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

# Where the recoloured mirror is built. Deliberately outside the repo.
RICE_THEME_ROOT="${RICE_THEME_ROOT:-$HOME/.local/share/arch_rice-theme}"

# True when this profile uses the committed colours, i.e. no mirror is needed
# and the repo can be deployed directly (the Z13 path — zero behaviour change).
rice_theme_is_canonical() {
    [[ "${PROFILE_ACCENT:-$RICE_CANON_ACCENT}"   == "$RICE_CANON_ACCENT" ]] &&
    [[ "${PROFILE_ACCENT2:-$RICE_CANON_ACCENT2}" == "$RICE_CANON_ACCENT2" ]]
}

# rice_theme_build <out_root>
# Rebuild the mirror from scratch. Only tracked files are considered, so stray
# files in the working tree never leak into a deployment.
rice_theme_build() {
    local out="$1"
    local accent="${PROFILE_ACCENT:-$RICE_CANON_ACCENT}"
    local accent2="${PROFILE_ACCENT2:-$RICE_CANON_ACCENT2}"
    local rel dest recoloured=0 linked=0

    # Match hex AND decimal spellings of both canonical accents.
    local dec1_re dec2_re detect
    dec1_re="$(_rice_dec_re "$RICE_CANON_ACCENT")"
    dec2_re="$(_rice_dec_re "$RICE_CANON_ACCENT2")"
    detect="$RICE_CANON_ACCENT|$RICE_CANON_ACCENT2|$dec1_re|$dec2_re"

    rm -rf "$out"
    mkdir -p "$out"

    while IFS= read -r rel; do
        dest="$out/$rel"
        mkdir -p "$(dirname "$dest")"

        # -I makes grep treat binaries as non-matching, so PNGs/TTFs/SVGs fall
        # through to the symlink branch untouched.
        if grep -qIiE "$detect" "$RICE_ROOT/$rel" 2>/dev/null; then
            sed -E "s/$RICE_CANON_ACCENT/$accent/Ig
                    s/$RICE_CANON_ACCENT2/$accent2/Ig
                    s/$dec1_re/$(_rice_dec "$accent")/g
                    s/$dec2_re/$(_rice_dec "$accent2")/g" \
                "$RICE_ROOT/$rel" > "$dest"
            [[ -x "$RICE_ROOT/$rel" ]] && chmod +x "$dest"
            recoloured=$((recoloured + 1))
        else
            ln -sfn "$RICE_ROOT/$rel" "$dest"
            linked=$((linked + 1))
        fi
    done < <(cd "$RICE_ROOT" && git ls-files -- .config .local)

    echo "$recoloured recoloured, $linked linked"
}
