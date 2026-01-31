# Arch Linux Dotfiles

Personal dotfiles for my Arch Linux rice setup, featuring both X11 (i3) and Wayland (Hyprland) configurations.

## Screenshots

<!-- Add your screenshots here -->

## Features

### Window Managers
- **i3** - Tiling window manager for X11
- **Hyprland** - Dynamic tiling Wayland compositor

### Status Bars
- **Polybar** - Status bar for i3/X11
- **Waybar** - Status bar for Hyprland/Wayland with custom modules:
  - CPU usage with per-core breakdown and temperature
  - GPU/VRAM usage and temperature (NVIDIA/AMD)
  - Network info with public IP
  - Spotify integration

### Terminals
- **Alacritty** - GPU-accelerated terminal
- **URxvt** - Lightweight terminal

### Applications
- **Rofi** - Application launcher with custom themes
- **Ranger** - Terminal file manager
- **Neofetch** - System info display
- **Neovim** - Text editor with Lua config
- **Tmux** - Terminal multiplexer

### Eye Candy
- **Picom** - Compositor for X11 (transparency, shadows, blur)
- **Dunst** - Notification daemon
- **Cava** - Audio visualizer
- **GLava** - OpenGL audio visualizer

### Media
- **spotify-tui** - Spotify TUI client
- **Playerctl** - Media player controls

## Installation

### Quick Install

```bash
git clone git@gitlab.com:raducu_garjoaba/arch_rice.git ~/.config
cd ~/.config
./install.sh
```

### Manual Installation

1. Install dependencies:
```bash
sudo pacman -S --needed i3-wm polybar picom rofi alacritty rxvt-unicode \
    ranger neofetch neovim tmux dunst cava playerctl pulseaudio pavucontrol \
    feh nitrogen xorg-xrandr xorg-xinit ttf-terminus-nerd nerd-fonts \
    hyprland waybar
```

2. Install AUR packages (using yay):
```bash
yay -S --needed spotify-tui glava siji-git
```

3. Symlink or copy configs to `~/.config/`

## Fonts Required

- Terminus (bitmap font)
- Nerd Fonts (for icons)
- Siji (icon font for polybar)
- Font Awesome

## Color Scheme

Based on Tomorrow Night theme:
- Background: `#1d1f21`
- Foreground: `#c5c8c6`
- Accent: `#81a2be` (blue)
- Alert: `#bd2c40` (red)

## Keybindings

### i3

| Key | Action |
|-----|--------|
| `$mod+Return` | Open terminal |
| `$mod+d` | Rofi launcher |
| `$mod+Shift+q` | Kill window |
| `$mod+h/j/k/l` | Focus left/down/up/right |
| `$mod+1-9` | Switch workspace |

### Hyprland

See `hypr/hyprland.conf` for full keybindings.

## File Structure

```
~/.config/
├── alacritty/      # Alacritty terminal config
├── cava/           # Audio visualizer config
├── dunst/          # Notification daemon config
├── glava/          # GLava visualizer config
├── hypr/           # Hyprland config
├── i3/             # i3 window manager config
├── neofetch/       # Neofetch config + logo
├── nvim/           # Neovim config (Lua)
├── picom/          # Compositor config
├── polybar/        # Polybar config + scripts
├── ranger/         # File manager config
├── rofi/           # App launcher config + themes
├── spotify-tui/    # Spotify TUI config
├── tmux/           # Tmux config
├── urxvt/          # URxvt/.Xresources
├── waybar/         # Waybar config + scripts
├── .bashrc         # Bash config
└── .xinitrc        # X11 startup
```

## Credits

- [Tomorrow Night](https://github.com/chriskempson/tomorrow-theme) color scheme
- Various r/unixporn inspirations
