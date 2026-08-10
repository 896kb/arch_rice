# arch_rice — ROG Flow Z13 dotfiles

Personal Arch Linux rice for an **ASUS ROG Flow Z13 (ACRNM RMT-02 / GZ301VIC**, Intel iGPU + NVIDIA RTX 4070). Primary session is **Hyprland (Wayland)**; a legacy **i3 (X11)** config is kept too.

The repo **mirrors `$HOME`** — `install.sh` deploys by symlinking each tracked path back into place, so editing a file here *is* editing the live config. (Editing must target the real path under `~/arch_rice/…`; the symlinks point here.)

---

## Highlights

- **Xiaomi Buds 6 on Linux** — reverse-engineered stack (nothing else supports these): per-bud + case battery, in-ear position, **ANC control**, **in-ear auto-pause**, single-tap play/pause fix, waybar widget with a custom glyph.
- **Hybrid GPU** — compositor pinned to the **Intel iGPU** so the RTX 4070 sleeps; games opt in with `prime-run`; the Steam UI is forced onto the iGPU.
- **Tablet-first** — accelerometer auto-rotate, touchscreen gestures, on-screen keyboard, pen actions, detachable-keyboard touchpad toggle.
- **Green-recolored Bibata cursor**, styled **hyprlock** (locks before sleep), **rofimoji** emoji grid, camera peek widgets, volume-rocker modes.

---

## Theming

**Base:** [Tomorrow Night](https://github.com/chriskempson/tomorrow-theme). **UI font:** `Departure Mono` everywhere, with `Symbols Nerd Font Mono` for icon glyphs and the bundled `BudsExtra` for the earbuds glyph.

**Palette / accents** (two accents coexist by design):

| role | hex | used by |
|------|-----|---------|
| background | `#1d1f21` | everything |
| foreground | `#c5c8c6` | everything |
| **ACRNM accent** (chartreuse) | `#ffff78` | Hyprland active border, waybar, wofi launcher, rofi, dunst frame/highlight |
| **green accent** | `#b5bd68` | cursor, hyprlock, waybar earbuds "connected", riptide, ANC OSD |
| warn (amber) | `#f0c674` | low battery |
| alert (red) | `#bd2c40` / `#cc6666` | dunst urgent, lock fail |
| dim / off | `#555555` | disabled indicators |

**Per-package theming:**

| package | font | accent | notes |
|---------|------|--------|-------|
| **Hyprland** | — | `#ffff78` border | `gaps_in 8`, `gaps_out 20`, `border_size 1`, `rounding 0`, blur on; inactive border transparent |
| **Waybar** | Departure Mono 11 | `#ffff78` (+green earbuds, amber low-batt) | custom modules (see below) |
| **wofi** (launcher) | Departure Mono | `#ffff78` ACRNM | `config` + `style.css` |
| **wofi** (emoji) | Noto Color Emoji | `#b5bd68` green, **4-column grid** | separate `emoji.conf` / `emoji.css` |
| **rofi** | — | ACRNM theme | `@theme themes/acrnm.rasi` |
| **dunst** | Departure Mono 10 | `#ffff78` frame + `highlight` | `highlight` = the ANC-OSD progress-bar fill |
| **alacritty** | Departure Mono 10 | Tomorrow palette | |
| **hyprlock** | Departure Mono | `#b5bd68` green | blurred wallpaper + big clock/date |
| **cursor** | — | `Bibata-Modern-Green` (`#b5bd68`) | recolored from Bibata-Modern-Ice by `recolor-cursor`; xcursor size 24 |

---

## Gestures

**Touchscreen** (lisgd via `touch-gestures`; ELAN9008 panel — works with the keyboard detached):

| gesture | action |
|---------|--------|
| **3-finger swipe up** | toggle the on-screen keyboard (`wvkbd`) |
| **swipe down from the top-right corner** | rear-camera peek toggle |
| **swipe down from the top-left corner** | front-camera peek toggle |

**Trackpad:** natural scroll; per-device `altwin:swap_lalt_lwin` + tuned sensitivity for the detachable keyboard.

---

## Keybindings

Window-management binds (focus / move / resize / workspaces / `Super+R` resize submap) are in `.config/hypr/hyprland.conf`. Hardware / function-row / pen / app bindings:

**Function row & media keys**
| key | action |
|-----|--------|
| mute / mic-mute *(F-row)* | `audio-mute sink` / `audio-mute source` |
| volume down / up *(F-row)* | `rocker down` / `rocker up` |
| play-pause / prev / next | `playerctl` |
| `Fn+F5` | fan / performance profile (asusd) + OSD |
| `Fn+F7` / `Fn+F8` | keyboard backlight down / up |
| touchpad key *(Fn+F6)* | toggle the detachable-keyboard touchpad |
| `Fn+F11` | sleep (logind) |
| `Fn+F12` | toggle **suspend on lid close** (+ OSD, persistent) |

**Volume rocker (side buttons — keyd)**
| input | action |
|-------|--------|
| rocker up / down | volume **or** screen brightness (mode-dependent) — `rocker` |
| rocker both-press *(→ F24)* | switch rocker mode |

**Pen / launchers / misc**
| key | action |
|-----|--------|
| pen top-button **double-click** | summon / dismiss **Krita** on its scratchpad workspace (`penbtn`) |
| pen eraser-region press | region screenshot (`pen-screenshotd`) |
| `Super+C` | **lock** (hyprlock via `loginctl lock-session`) |
| `Super+D` | app launcher (wofi) |
| `Super+.` | **emoji picker** (rofimoji grid) |
| `Super+Shift+O` | OCR (OCR4Linux) |
| `Alt+Space` | Claude Desktop |

---

## Custom behaviors & scripts (`~/.local/bin`)

**Earbuds (Xiaomi Buds 6)** — `buds-daemon` holds the control channel and writes `~/.cache/buds-battery.json`; `earbuds-status` is the waybar widget (**click** = connect/disconnect, **right-click** = daemon toggle). `buds-anc off|anc|transparency|cycle` switches noise cancelling (dunst OSD shows the mode). Removing a bud **auto-pauses** media; reinserting resumes. Opening the case shows an image overlay that morphs to which bud is docked. Single-tap play/pause works via `mpris-proxy`.

**Cameras** — `rearcam-bridge` exposes the IPU6 rear camera to browsers via a V4L2 loopback. `rearcam-widget` / `frontcam-widget` are pinned mpv peek panels (corner-swipe gestures above, or waybar `rearcam-status`), auto-oriented for the current rotation.

**Tablet / input** — `auto-rotate` (accelerometer; landscape-locked while the keyboard is attached), `touch-gestures` (lisgd), `wvkbd-toggle` (on-screen keyboard), `touchpad-toggle`, `penbtn`, `pen-screenshotd`.

**Hardware / OSD** — `osd` (generic dunst OSD wrapper), `rocker` (volume/brightness rocker modes), `audio-mute`, `kbd-backlight`, `fan-profile-osd` (Fn+F5), `lid-sleep-toggle` (Fn+F12).

**GPU / cursor / lock** — `prime-run` (NVIDIA offload), `recolor-cursor` (recolor a grayscale xcursor theme). Lock = `hyprlock` + `hypridle` (locks *before* sleep → password on wake; idle-lock at 5 min, screen off at 6 min).

---

## Structure

```
~/arch_rice/
├── .config/          # whole-dir symlinks: hypr waybar wofi alacritty dunst rofi ranger
│                     #   cava glava picom polybar i3 nvim tmux neofetch urxvt
├── .local/
│   ├── bin/          # all custom scripts (symlinked individually; on PATH via .bashrc)
│   └── share/
│       ├── applications/steam.desktop   # Steam UI → iGPU + 1.25 scaling
│       └── fonts/BudsExtra.ttf          # waybar earbuds glyph (U+F3FF)
├── system/           # reference /etc tweaks: keyd-default.conf (rocker), cpu-tune
├── .bashrc   .xinitrc   install.sh
```

---

## Install

```bash
git clone git@gitlab.com:896kb/arch_rice.git ~/arch_rice
cd ~/arch_rice
./install.sh
```

`install.sh`:

- **Packages** — Hyprland/Wayland tooling (`wofi`, `hyprlock`, `hypridle`, `grim`/`slurp`/`wl-clipboard`, `mpv`, `rofimoji`+`wtype`, nerd-font symbols, `noto-fonts-emoji`) and Flow Z13 hardware deps (`iio-sensor-proxy`, `keyd`, `v4l2loopback-dkms`, `bluez`/`bluez-utils`, GTK layer-shell python stack); AUR: `wvkbd`, `lisgd`, `light`, `asusctl` (also in the *g14* repo), `bibata-cursor-theme`.
- **Deploy** — backs up existing configs to `~/.config-backup-*`, then symlinks the `.config/` dirs, home files, every `.local/bin/` script, `.local/share/applications` + `.local/share/fonts` (+ `fc-cache`).
- **Generate / enable** — regenerates the green cursor (`Bibata-Modern-Green`) from Bibata; deploys `system/keyd-default.conf` → `/etc/keyd/`; enables `keyd`, `bluetooth`, and the `mpris-proxy` user service.

> Verified: the deploy logic runs clean in an isolated `$HOME` (all symlinks resolve, backups made, cursor generated). `system/cpu-tune` and the iio-sensor-proxy suspend hook are applied by hand.

---

## Fonts

`Departure Mono` (UI), a Nerd Font + `ttf-nerd-fonts-symbols-mono` (glyphs), `noto-fonts-emoji` (emoji), the bundled `BudsExtra.ttf` (earbuds glyph); Terminus + Siji for the legacy polybar. `bibata-cursor-theme` is the base for the green cursor.

## Credits

- [Tomorrow Night](https://github.com/chriskempson/tomorrow-theme) palette · [Bibata](https://github.com/ful1e5/Bibata_Cursor) cursor base
- Xiaomi Buds 6 protocol ported from [Gadgetbridge](https://codeberg.org/Freeyourgadget/Gadgetbridge)'s RedmiBuds work
- r/unixporn inspirations
