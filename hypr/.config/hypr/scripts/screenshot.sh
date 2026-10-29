#!/usr/bin/env bash
# Screenshot helper for Hyprland (Wayland): grim + slurp + satty.
#
# Usage: screenshot.sh [region|full|active]
#   region (default) - drag a region, then annotate in satty
#   full             - whole screen
#   active           - focused window
#
# In satty: Enter copies to the clipboard and saves to ~/Pictures/Screenshots,
#           Esc cancels without saving.

set -euo pipefail

mode="${1:-region}"

shot_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$shot_dir"
out="$shot_dir/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"

geom=""
case "$mode" in
    region)
        # Exit quietly when the region selection is cancelled (Esc).
        geom="$(slurp -b '#33ccffee' -w 2)" || exit 0
        ;;
    active)
        geom="$(hyprctl activewindow -j | jq -r '
            if (.address // "") == "" then empty
            else "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"
            end')"
        [ -n "$geom" ] || exit 0
        ;;
    full) ;;
    *)
        echo "usage: $0 [region|full|active]" >&2
        exit 2
        ;;
esac

if [ -n "$geom" ]; then
    grim -g "$geom" -t ppm -
else
    grim -t ppm -
fi | satty \
    --filename - \
    --fullscreen \
    --output-filename "$out" \
    --copy-command 'wl-copy' \
    --actions-on-enter 'save-to-clipboard,save-to-file,exit' \
    --actions-on-escape 'exit'
