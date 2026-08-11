#!/bin/bash

# Arch Linux Dotfiles Installation Script
# This script installs all dependencies for the rice setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch Linux (pacman not found)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- host profile -----------------------------------------------------------
# One repo, several machines. The profile decides which packages, scripts and
# config fragments apply here. See lib/profile.sh for the resolution order.
usage() {
    cat <<EOF
Usage: $(basename "$0") [--profile=<name>] [--list-profiles]

  --profile=<name>   force a host profile instead of autodetecting
  --list-profiles    show available profiles and exit

Profiles are autodetected from DMI, or pinned by writing the name into
~/.config/rice-profile. Available: $(cd "$SCRIPT_DIR/profiles" && ls *.sh 2>/dev/null | sed 's/\.sh$//' | tr '\n' ' ')
EOF
}

for arg in "$@"; do
    case "$arg" in
        --profile=*)   RICE_PROFILE="${arg#*=}"; export RICE_PROFILE ;;
        --list-profiles)
            (cd "$SCRIPT_DIR/profiles" && ls *.sh | sed 's/\.sh$//')
            exit 0 ;;
        -h|--help)     usage; exit 0 ;;
        *)             print_error "unknown option: $arg"; usage; exit 1 ;;
    esac
done

# shellcheck source=lib/profile.sh
source "$SCRIPT_DIR/lib/profile.sh"
# shellcheck source=lib/theme.sh
source "$SCRIPT_DIR/lib/theme.sh"
rice_load_profile

# Deploy the lock screen's PAM stack. Must live in /etc/pam.d: PAM resolves
# `include` against the config directory it was started with, so a repo-local
# stack using "include login" fails with PAM_SYSTEM_ERR. Same approach hyprlock
# and swaylock take. Without this the lock cannot authenticate at all.
rice_install_pam_lock() {
    if [[ -f "$SCRIPT_DIR/system/pam-quickshell-lock" ]]; then
        sudo install -Dm644 "$SCRIPT_DIR/system/pam-quickshell-lock" /etc/pam.d/quickshell-lock \
            && print_success "PAM stack installed (/etc/pam.d/quickshell-lock)"
    fi
}

# Deploy system/nvidia-pm.conf — called from profiles with the nvidia_prime feature.
rice_install_nvidia_pm() {
    if [[ -f "$SCRIPT_DIR/system/nvidia-pm.conf" ]]; then
        sudo install -Dm644 "$SCRIPT_DIR/system/nvidia-pm.conf" /etc/modprobe.d/nvidia-pm.conf \
            && print_success "NVIDIA runtime power management configured (rebuild initramfs to apply)"
    fi
}

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Arch Linux Dotfiles Installer                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
print_status "Host profile: ${PROFILE_NAME} [${RICE_PROFILE}]"
print_status "Features: ${PROFILE_FEATURES[*]:-none}"
echo ""

# Core packages from official repos
PACMAN_PACKAGES=(
    # Window Managers
    "i3-wm"
    "i3lock"
    "i3status"
    "hyprland"
    
    # Status Bars
    "polybar"
    "waybar"
    
    # Terminals
    # NOTE: alacritty itself is NOT installed from the repos — the AUR list below
    # pulls alacritty-smooth-cursor-git, which provides/conflicts with it.
    "rxvt-unicode"
    
    # Compositor & Display
    "picom"
    "xorg-server"
    "xorg-xinit"
    "xorg-xrandr"
    "xorg-xsetroot"
    
    # Launchers & Menus
    "rofi"
    "dmenu"
    
    # File Manager
    "ranger"
    
    # Notifications
    "dunst"
    "libnotify"
    
    # Audio (pipewire assumed already installed)
    "pavucontrol"
    "playerctl"
    "cava"
    
    # Utilities
    "fastfetch"
    "neovim"
    "tmux"
    "feh"
    "curl"
    "wget"
    "git"
    "htop"
    "unzip"

    # Wayland session bits (referenced by hyprland.conf exec-once)
    "swaybg"
    "swaylock"
    "hyprpaper"
    "network-manager-applet"
    "unclutter"

    # Fonts
    "ttf-terminus-nerd"
    "otf-font-awesome"
    "noto-fonts"
    "noto-fonts-emoji"
    
    # Screenshots
    "scrot"
    "maim"
    
    # Misc
    "xclip"
    "xdotool"
    "jq"
    "bc"
    "lm_sensors"
    "wireless_tools"

    # --- Hyprland/Wayland session ---
    "wofi"                        # app launcher ($menu in hyprland.conf)
    "hyprlock"                    # fallback lock screen (kept: the quickshell lock is newer)
    "hypridle"                    # idle daemon: locks before sleep (password on wake) + dpms
    # Quickshell lock screen — hyprlock can't play video, so the lock surface is
    # our own QML (.config/quickshell/lock). ffmpeg backend decodes the clip.
    "quickshell"
    "qt6-multimedia"
    "gst-plugins-good"
    "gst-libav"
    "grim"                        # screenshots (pen-screenshotd, camera widgets)
    "slurp"                       # region select
    "wl-clipboard"                # wl-copy (cam-clip)
    "mpv"                         # camera peek widgets
    "chafa"                       # inline terminal image viewer (img() in .bashrc)
    "brightnessctl"               # backlight control
    "rofimoji"                    # emoji / symbol picker (Super+. , wofi selector)
    "wtype"                       # types the picked emoji into the focused window
    "noto-fonts-emoji"            # color emoji rendering
    # bluetooth earbuds + AVRCP<->MPRIS bridge
    "bluez"
    "bluez-utils"                 # bluetoothctl + mpris-proxy (buds single-tap fix)
    # GTK layer-shell python stack (buds popups, ANC OSD)
    "gtk-layer-shell"
    "python-gobject"
    "python-cairo"
    # fonts
    "ttf-nerd-fonts-symbols-mono" # nf-md glyphs used across waybar / OSDs
)

# AUR packages
AUR_PACKAGES=(
    "glava"
    "siji-git"
    "ttf-unifont"
    "bibata-cursor-theme"          # base for the recolored green cursor (generated below)
    "alacritty-smooth-cursor-git"  # alacritty + smooth cursor motion patch; provides/conflicts 'alacritty'
)

# Hardware-specific packages come from the host profile (profiles/<name>.sh).
PACMAN_PACKAGES+=("${PROFILE_PACMAN[@]}")
AUR_PACKAGES+=("${PROFILE_AUR[@]}")

# Install pacman packages
print_status "Installing packages from official repositories..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" || {
    print_warning "Some packages may have failed, continuing..."
}
print_success "Official packages installed"

# Check for AUR helper
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    print_warning "No AUR helper found (paru/yay)"
    read -p "Install paru? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_status "Installing paru..."
        sudo pacman -S --needed --noconfirm base-devel
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/paru
        AUR_HELPER="paru"
        print_success "paru installed"
    fi
fi

# Install AUR packages
if [[ -n "$AUR_HELPER" ]]; then
    print_status "Installing AUR packages with $AUR_HELPER..."
    $AUR_HELPER -S --needed --noconfirm "${AUR_PACKAGES[@]}" || {
        print_warning "Some AUR packages may have failed, continuing..."
    }
    print_success "AUR packages installed"
else
    print_warning "Skipping AUR packages (no AUR helper)"
    print_warning "Install manually: ${AUR_PACKAGES[*]}"
fi

# --- accent theming --------------------------------------------------------
# A profile with non-canonical accents gets a recoloured mirror of .config/ and
# .local/, and everything below deploys from there instead of straight out of
# the repo. Canonical profiles skip this entirely.
if rice_theme_is_canonical; then
    DEPLOY_ROOT="$SCRIPT_DIR"
    print_status "Accent: canonical (#${PROFILE_ACCENT}) — deploying repo directly"
else
    print_status "Accent: #${PROFILE_ACCENT} / #${PROFILE_ACCENT2} — building recoloured mirror"
    stats="$(rice_theme_build "$RICE_THEME_ROOT")"
    DEPLOY_ROOT="$RICE_THEME_ROOT"
    print_success "Theme mirror at $RICE_THEME_ROOT ($stats)"
fi

# Deploy config files
print_status "Deploying configuration files..."

# Config directories to deploy to ~/.config/
CONFIG_DIRS=(
    "alacritty"
    "cava"
    "dunst"
    "glava"
    "hypr"
    "i3"
    "neofetch"
    "nvim"
    "picom"
    "polybar"
    "quickshell"
    "ranger"
    "rofi"
    "tmux"
    "urxvt"
    "waybar"
    "wofi"
)

# Create backup directory
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# Deploy .config directories
for dir in "${CONFIG_DIRS[@]}"; do
    src=""
    # Check if config exists in .config/ subdirectory first
    if [ -d "$DEPLOY_ROOT/.config/$dir" ]; then
        src="$DEPLOY_ROOT/.config/$dir"
    elif [ -d "$DEPLOY_ROOT/$dir" ]; then
        src="$DEPLOY_ROOT/$dir"
    fi
    
    if [ -n "$src" ]; then
        dest="$HOME/.config/$dir"
        
        # Backup existing config if it exists and is not a symlink
        if [ -d "$dest" ] && [ ! -L "$dest" ]; then
            mkdir -p "$BACKUP_DIR"
            print_warning "Backing up existing $dir to $BACKUP_DIR/"
            mv "$dest" "$BACKUP_DIR/"
        elif [ -L "$dest" ]; then
            rm "$dest"
        fi
        
        # Create symlink
        mkdir -p "$HOME/.config"
        ln -sf "$src" "$dest"
        print_success "Linked $dir -> $dest"
    fi
done

# Deploy home directory files (.bashrc, .xinitrc)
HOME_FILES=(
    ".bashrc"
    ".bash_profile"   # resolves AQ_DRM_DEVICES (pins the compositor to the iGPU)
    ".xinitrc"
)

for file in "${HOME_FILES[@]}"; do
    src=""
    if [ -f "$SCRIPT_DIR/$file" ]; then
        src="$SCRIPT_DIR/$file"
    elif [ -f "$DEPLOY_ROOT/.config/$file" ]; then
        src="$DEPLOY_ROOT/.config/$file"
    fi
    
    if [ -n "$src" ]; then
        dest="$HOME/$file"
        
        # Backup existing file
        if [ -f "$dest" ] && [ ! -L "$dest" ]; then
            mkdir -p "$BACKUP_DIR"
            print_warning "Backing up existing $file to $BACKUP_DIR/"
            cp "$dest" "$BACKUP_DIR/"
        fi
        
        # Create symlink
        ln -sf "$src" "$dest"
        print_success "Linked $file -> $dest"
    fi
done

# Deploy ~/.local/bin scripts (symlinked; PATH picks them up via .bashrc)
if [ -d "$DEPLOY_ROOT/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
    for f in "$DEPLOY_ROOT/.local/bin/"*; do
        [ -e "$f" ] || continue
        name="$(basename "$f")"

        # Skip scripts this machine has no hardware for (see PROFILE_BIN_EXCLUDE).
        if rice_bin_excluded "$name"; then
            # Remove a stale link from a previous profile so nothing dangles.
            [ -L "$HOME/.local/bin/$name" ] && rm -f "$HOME/.local/bin/$name"
            continue
        fi

        dest="$HOME/.local/bin/$name"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            mkdir -p "$BACKUP_DIR"
            print_warning "Backing up existing $name to $BACKUP_DIR/"
            mv "$dest" "$BACKUP_DIR/"
        elif [ -L "$dest" ]; then
            rm "$dest"
        fi
        ln -sf "$f" "$dest"
        print_success "Linked bin/$name -> $dest"
    done
    print_success "Local bin scripts deployed"
fi

# Deploy ~/.local/share/applications overrides (e.g. steam.desktop: UI on iGPU + 1.25 scaling)
if [ -d "$DEPLOY_ROOT/.local/share/applications" ]; then
    mkdir -p "$HOME/.local/share/applications"
    for f in "$DEPLOY_ROOT/.local/share/applications/"*; do
        [ -e "$f" ] || continue
        ln -sf "$f" "$HOME/.local/share/applications/$(basename "$f")"
        print_success "Linked applications/$(basename "$f")"
    done
fi

# Deploy custom fonts (e.g. BudsExtra.ttf — the waybar earbuds egg glyph) + refresh cache
if [ -d "$DEPLOY_ROOT/.local/share/fonts" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    for f in "$DEPLOY_ROOT/.local/share/fonts/"*; do
        [ -e "$f" ] || continue
        ln -sf "$f" "$HOME/.local/share/fonts/$(basename "$f")"
    done
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    print_success "Custom fonts linked + font cache refreshed"
fi

# Generate the accent-coloured cursor from the installed Bibata (recolor-cursor is
# pure-stdlib python). The ~40MB recolored theme is kept OUT of git and regenerated
# here instead. Colour and theme name both come from the host profile, so the Z13
# gets Bibata-Modern-Green and the Xiaomi gets Bibata-Modern-Pink.
if [ -x "$HOME/.local/bin/recolor-cursor" ]; then
    if [ -d /usr/share/icons/Bibata-Modern-Ice ] || [ -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
        "$HOME/.local/bin/recolor-cursor" Bibata-Modern-Ice "$PROFILE_ACCENT" "$PROFILE_CURSOR_THEME" \
            && print_success "Generated $PROFILE_CURSOR_THEME cursor (#$PROFILE_ACCENT)" \
            || print_warning "Cursor recolor failed"
    else
        print_warning "Bibata-Modern-Ice not installed; skipping cursor generation"
    fi
fi

# Deploy background images
if [ -d "$DEPLOY_ROOT/.config" ]; then
    for bg in "$DEPLOY_ROOT/.config"/background.*; do
        if [ -f "$bg" ]; then
            filename=$(basename "$bg")
            ln -sf "$bg" "$HOME/.config/$filename"
            print_success "Linked $filename"
        fi
    done
fi

print_success "Config files deployed"

# --- host profile fragments -------------------------------------------------
# Hyprland and waybar both pull in one machine-specific file. These live OUTSIDE
# the symlinked config directories on purpose: ~/.config/hypr and ~/.config/waybar
# point straight into this repo, so writing generated state there would show up as
# repo dirt on every machine.
print_status "Linking host profile fragments..."

hypr_profile="$DEPLOY_ROOT/.config/hypr/profile.d/$RICE_PROFILE.conf"
if [ -f "$hypr_profile" ]; then
    ln -sfn "$hypr_profile" "$HOME/.config/hypr-profile.conf"
    print_success "hyprland profile -> $RICE_PROFILE.conf"
else
    print_warning "no hyprland fragment for profile '$RICE_PROFILE'"
fi

waybar_profile="$DEPLOY_ROOT/.config/waybar/profile.d/$RICE_PROFILE.jsonc"
if [ -f "$waybar_profile" ]; then
    ln -sfn "$waybar_profile" "$HOME/.config/waybar-profile.jsonc"
    print_success "waybar profile -> $RICE_PROFILE.jsonc"
else
    print_warning "no waybar fragment for profile '$RICE_PROFILE'"
fi

# --- system services + tweaks -----------------------------------------------
print_status "Configuring system services..."

# bluetooth (earbuds) + AVRCP<->MPRIS bridge (single-tap play/pause on the buds)
sudo systemctl enable --now bluetooth.service 2>/dev/null && print_success "bluetooth enabled"
systemctl --user enable --now mpris-proxy.service 2>/dev/null && print_success "mpris-proxy (user) enabled"

# Lock screen PAM stack — needed on every host, not profile-specific.
rice_install_pam_lock

# Everything hardware-specific (keyd, NVIDIA power management, power daemons)
# is done by the profile's own hook.
if declare -F profile_system_setup >/dev/null; then
    profile_system_setup
fi

print_success "System services configured"

echo ""
print_success "Installation complete!"
echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo "Your old configs were backed up to: $BACKUP_DIR"
    echo ""
fi
echo "Next steps:"
echo "  1. Log out and select i3 or Hyprland from your display manager"
echo "  2. Or start X11 with: startx"
echo "  3. Or start Hyprland with: Hyprland"
echo ""
echo ""
