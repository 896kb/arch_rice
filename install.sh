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

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Arch Linux Dotfiles Installer                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
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
    "alacritty"
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
    
    # Audio
    "pulseaudio"
    "pavucontrol"
    "playerctl"
    "cava"
    
    # Utilities
    "neofetch"
    "neovim"
    "tmux"
    "feh"
    "nitrogen"
    "curl"
    "wget"
    "git"
    "htop"
    "unzip"
    
    # Fonts
    "ttf-terminus-nerd"
    "ttf-font-awesome"
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
)

# AUR packages
AUR_PACKAGES=(
    "spotify-tui"
    "glava"
    "siji-git"
    "ttf-unifont"
    "nerd-fonts-complete"
)

# Install pacman packages
print_status "Installing packages from official repositories..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" || {
    print_warning "Some packages may have failed, continuing..."
}
print_success "Official packages installed"

# Check for AUR helper
AUR_HELPER=""
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    print_warning "No AUR helper found (yay/paru)"
    read -p "Install yay? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_status "Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
        AUR_HELPER="yay"
        print_success "yay installed"
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

# Enable services
print_status "Enabling services..."
systemctl --user enable --now pulseaudio.service 2>/dev/null || true
print_success "Services configured"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    "ranger"
    "rofi"
    "spotify-tui"
    "tmux"
    "urxvt"
    "waybar"
)

# Create backup directory
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# Deploy .config directories
for dir in "${CONFIG_DIRS[@]}"; do
    src=""
    # Check if config exists in .config/ subdirectory first
    if [ -d "$SCRIPT_DIR/.config/$dir" ]; then
        src="$SCRIPT_DIR/.config/$dir"
    elif [ -d "$SCRIPT_DIR/$dir" ]; then
        src="$SCRIPT_DIR/$dir"
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
    ".xinitrc"
)

for file in "${HOME_FILES[@]}"; do
    src=""
    if [ -f "$SCRIPT_DIR/$file" ]; then
        src="$SCRIPT_DIR/$file"
    elif [ -f "$SCRIPT_DIR/.config/$file" ]; then
        src="$SCRIPT_DIR/.config/$file"
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

# Deploy background images
if [ -d "$SCRIPT_DIR/.config" ]; then
    for bg in "$SCRIPT_DIR/.config"/background.*; do
        if [ -f "$bg" ]; then
            filename=$(basename "$bg")
            ln -sf "$bg" "$HOME/.config/$filename"
            print_success "Linked $filename"
        fi
    done
fi

print_success "Config files deployed"

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
echo "Optional: Set up spotify-tui with: spt"
echo ""
