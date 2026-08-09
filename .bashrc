#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='┏ [\e[1;34m\u\e[0m@\e[1;32m\h\e[0m]-[\e[1;36m$(date +%H:%M:%S)\e[0m]-[\e[33;1m\w\e[0m]\n┗ $'
source /usr/share/nvm/init-nvm.sh

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# rootless podman docker socket (for Encore and other docker-aware tools)
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"

# view images inline as colored block/symbol art (works in any terminal, incl. alacritty)
# usage: img photo.png   |   img *.jpg   |   curl -s URL | img -
img() { chafa "$@"; }

# personal scripts (~/.local/bin: buds-anc, buds-daemon-toggle, earbuds-status, ...)
# guarded so re-sourcing can't duplicate the entry
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
