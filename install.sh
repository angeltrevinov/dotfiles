#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { printf "\033[0;34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[0;32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[0;33m[WARN]\033[0m  %s\n" "$1"; }
err()   { printf "\033[0;31m[ERR]\033[0m   %s\n" "$1"; }

# ─── Package Installation ────────────────────────────────────────────

install_pacman_packages() {
    info "Installing pacman packages..."
    if [[ ! -f "$DOTFILES_DIR/pacman-packages.txt" ]]; then
        warn "pacman-packages.txt not found, skipping"
        return
    fi
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pacman-packages.txt"
    ok "Pacman packages installed"
}

install_aur_packages() {
    local aur_helper=""
    if command -v yay &>/dev/null; then
        aur_helper="yay"
    elif command -v paru &>/dev/null; then
        aur_helper="paru"
    fi

    if [[ -z "$aur_helper" ]]; then
        warn "No AUR helper found (yay/paru), skipping AUR packages"
        warn "Install yay first: sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si"
        return
    fi

    if [[ ! -f "$DOTFILES_DIR/yay-packages.txt" ]]; then
        warn "yay-packages.txt not found, skipping"
        return
    fi

    local count
    count=$(wc -l < "$DOTFILES_DIR/yay-packages.txt")
    if [[ "$count" -eq 0 ]]; then
        warn "yay-packages.txt is empty, skipping"
        return
    fi

    info "Installing AUR packages with $aur_helper..."
    "$aur_helper" -S --needed --noconfirm - < "$DOTFILES_DIR/yay-packages.txt"
    ok "AUR packages installed"
}

# ─── Config Symlinks ─────────────────────────────────────────────────

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
        warn "Backing up existing $target -> $backup"
        mv "$target" "$backup"
    fi
}

link_config() {
    local src="$1"
    local dest="$2"

    backup_if_exists "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    ok "Linked $dest -> $src"
}

install_configs() {
    info "Installing config files..."

    # Hyprland
    link_config "$DOTFILES_DIR/hypr/.config/hypr/hyprland.lua"  "$HOME/.config/hypr/hyprland.lua"
    link_config "$DOTFILES_DIR/hypr/.config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
    link_config "$DOTFILES_DIR/hypr/.config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"

    # Waybar
    link_config "$DOTFILES_DIR/waybar/.config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    link_config "$DOTFILES_DIR/waybar/.config/waybar/style.css"    "$HOME/.config/waybar/style.css"

    # Rofi
    link_config "$DOTFILES_DIR/rofi/.config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"

    # Fish
    link_config "$DOTFILES_DIR/fish/.config/fish/config.fish" "$HOME/.config/fish/config.fish"

    # Neovim (entire directory via symlink)
    link_config "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"

    # Obsidian (app config + vault settings)
    link_config "$DOTFILES_DIR/obsidian/.config/obsidian/obsidian.json" "$HOME/.config/obsidian/obsidian.json"
    link_config "$DOTFILES_DIR/obsidian/.config/obsidian/Preferences"   "$HOME/.config/obsidian/Preferences"

    # Vault settings (live vault is at ~/My Notes)
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/appearance.json"        "$HOME/My Notes/.obsidian/appearance.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/app.json"               "$HOME/My Notes/.obsidian/app.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/bookmarks.json"         "$HOME/My Notes/.obsidian/bookmarks.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/community-plugins.json" "$HOME/My Notes/.obsidian/community-plugins.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/core-plugins.json"      "$HOME/My Notes/.obsidian/core-plugins.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/graph.json"             "$HOME/My Notes/.obsidian/graph.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/templates.json"         "$HOME/My Notes/.obsidian/templates.json"
    link_config "$DOTFILES_DIR/obsidian/vault/.obsidian/types.json"             "$HOME/My Notes/.obsidian/types.json"

    ok "All configs linked"
}

# ─── Main ─────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --packages-only    Install packages only, skip configs
  --configs-only     Install configs only, skip packages
  --aur-only         Install AUR packages only
  --list-packages    Print package lists without installing
  -y, --yes          Skip confirmation prompt
  -h, --help         Show this help

Examples:
  $0                  # Install everything (packages + configs)
  $0 --configs-only   # Only link config files
  $0 --packages-only  # Only install packages
  $0 --list-packages  # Show what would be installed
EOF
}

main() {
    local packages=true configs=true yes=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --packages-only) configs=false ;;
            --configs-only)  packages=false ;;
            --aur-only)      packages=false; configs=false; install_aur_packages; exit 0 ;;
            --list-packages) echo "=== Pacman packages ==="; cat "$DOTFILES_DIR/pacman-packages.txt"; echo; echo "=== AUR packages ==="; cat "$DOTFILES_DIR/yay-packages.txt"; exit 0 ;;
            -y|--yes)        yes=true ;;
            -h|--help)       usage; exit 0 ;;
            *)               err "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done

    echo
    info "Dotfiles installer"
    info "Source: $DOTFILES_DIR"
    echo

    if [[ "$yes" == false ]]; then
        read -rp "Proceed with installation? [y/N] " confirm
        if [[ "$confirm" != [yY] ]]; then
            info "Aborted"
            exit 0
        fi
    fi

    if [[ "$packages" == true ]]; then
        install_pacman_packages
        install_aur_packages
    fi

    if [[ "$configs" == true ]]; then
        install_configs
    fi

    echo
    ok "Done! Restart your session or run:"
    echo "  hyprctl reload"
}

main "$@"
