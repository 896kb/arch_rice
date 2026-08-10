# arch_rice — ROG Flow Z13 dotfiles

Personal Arch Linux rice for an **ASUS ROG Flow Z13 (ACRNM RMT-02 / GZ301VIC**, Intel iGPU + NVIDIA RTX 4070). Primary session is **Hyprland (Wayland)**; legacy **i3 (X11)** config is kept too.

The repo **mirrors `$HOME`** and is deployed by symlinking each tracked file back into place (see [Install](#install)) — so editing a config here *is* editing the live config.

## Highlights

- **Xiaomi Buds 6 on Linux** — reverse-engineered stack (no existing tool supports these): per-bud + case battery, in-ear position, **ANC control**, **in-ear auto-pause**, and a waybar widget with a custom battery-case glyph.
- **Hybrid GPU done right** — the compositor is pinned to the **Intel iGPU** so the RTX 4070 can sleep; games opt in with `prime-run`, and the Steam client UI is forced onto the iGPU (no more cross-GPU-copy lag / dGPU stuck awake).
- **Green Bibata cursor** — `recolor-cursor` regenerates a `#b5bd68` variant of Bibata from source at install time (no binaries in git).
- **Tablet / detachable-keyboard niceties** — accelerometer auto-rotate, touchscreen gestures (lisgd), on-screen keyboard, touchpad toggle, ASUS pen button actions.
- **Camera stack** — IPU6 rear camera exposed to browsers via a V4L2 loopback bridge, plus slide-in front/rear camera peek widgets.
- **Hardware keys** — volume-rocker remap (keyd), fan-profile OSD (Fn+F5), and an **Fn+F12 "suspend on lid close" toggle**.

## Structure

```
~/arch_rice/
├── .config/                         # whole-dir symlinks into ~/.config
│   ├── hypr/  waybar/  alacritty/  dunst/  rofi/  ranger/  cava/  glava/
│   ├── picom/  polybar/  i3/  nvim/  tmux/  neofetch/  urxvt/  spotify-tui/
├── .local/
│   ├── bin/                         # all custom scripts (symlinked individually; on PATH via .bashrc)
│   └── share/
│       ├── applications/steam.desktop   # Steam UI → Intel iGPU + 1.25 scaling override
│       └── fonts/BudsExtra.ttf          # waybar earbuds "egg" glyph (U+F3FF)
├── system/                          # reference copies of /etc tweaks (applied manually)
│   └── keyd-default.conf            # volume-rocker chord → F24
├── .bashrc   .xinitrc   install.sh
```

## Scripts (`~/.local/bin`)

**Earbuds (Xiaomi Buds 6)**
| script | purpose |
|--------|---------|
| `buds-daemon` | holds the RFCOMM control channel; writes battery/position/ANC to `~/.cache/buds-battery.json`; drives in-ear auto-pause + the ANC OSD |
| `buds-battery` | one-shot per-component battery (L / R / Case) reader (SAFER+ auth, FE-DC-BA framing) |
| `buds-anc` | control noise cancelling — `off` / `anc` / `transparency` / `cycle` / `status` |
| `buds-popup` / `buds-case-watcher` | case-open image overlay that morphs by which bud is docked |
| `earbuds-status` / `earbuds-toggle` / `buds-daemon-toggle` | waybar module + connect / daemon toggles |

**Cameras** — `rearcam-bridge` (IPU6 → V4L2 loopback for browsers), `rearcam-status`, `rearcam-widget`, `frontcam-widget`, `cam-fullscreen`, `cam-geometry`, `cam-reorient`, `cam-clip`, `camwidget.lua`

**Tablet / input** — `auto-rotate`, `touch-gestures` (lisgd), `touchpad-toggle`, `wvkbd-toggle`, `penbtn`, `pen-screenshotd`

**Hardware / OSD** — `osd` (generic dunst OSD wrapper), `rocker` (volume-rocker mode switch), `audio-mute`, `kbd-backlight`, `fan-profile-osd`, `lid-sleep-toggle` (Fn+F12)

**GPU / cursor** — `prime-run` (NVIDIA offload), `recolor-cursor` (recolor a grayscale xcursor theme)

## Install

```bash
git clone git@gitlab.com:896kb/arch_rice.git ~/arch_rice
cd ~/arch_rice
./install.sh
```

`install.sh` installs the pacman + AUR packages, backs up any existing configs to `~/.config-backup-*`, then symlinks: the `.config/` dirs, home files (`.bashrc`, `.xinitrc`), **every file in `.local/bin/`**, `.local/share/applications/*` (Steam override) and `.local/share/fonts/*` (+ `fc-cache`), and finally **regenerates the green cursor** (`Bibata-Modern-Green`) from the installed Bibata.

**System tweaks** under `system/` are applied by hand, e.g. the volume-rocker remap:
```bash
sudo cp system/keyd-default.conf /etc/keyd/default.conf && sudo systemctl restart keyd
```

## Fonts

Terminus (bitmap), a Nerd Font (icons), Font Awesome, Siji (polybar), and the bundled **BudsExtra.ttf** (waybar earbuds glyph). `bibata-cursor-theme` (AUR) is the base for the green cursor.

## Color scheme

Tomorrow Night, with **green `#b5bd68`** as the everywhere-accent (waybar, cursor, TUIs):

| role | hex |
|------|-----|
| background | `#1d1f21` |
| foreground | `#c5c8c6` |
| accent (green) | `#b5bd68` |
| warn (amber) | `#f0c674` |
| dim / off | `#555555` |

## Keybindings

Full set in `.config/hypr/hyprland.conf` (83 binds). Notable hardware/custom ones:

| key | action |
|-----|--------|
| `Fn+F5` | fan/performance profile (asusd) + OSD |
| `Fn+F11` | sleep (logind) |
| `Fn+F12` | toggle **suspend on lid close** (+ notification, persistent) |
| volume rocker | volume / brightness (keyd → `rocker`) |
| `Super+D` | rofi/wofi launcher · `Super+P` emoji picker |

## Credits

- [Tomorrow Night](https://github.com/chriskempson/tomorrow-theme) palette · [Bibata](https://github.com/ful1e5/Bibata_Cursor) cursor base
- Xiaomi Buds 6 protocol ported from [Gadgetbridge](https://codeberg.org/Freeyourgadget/Gadgetbridge)'s RedmiBuds work
- r/unixporn inspirations
