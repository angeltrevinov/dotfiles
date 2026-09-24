#!/usr/bin/env bash
# Keep Hyprland's laptop panel in sync with the authoritative logind lid state.
# The ASUS lid switch reports opposite on/off labels on some systems, so the
# Hyprland switch event is used only as a trigger; logind decides what to do.

set -u

readonly LAPTOP_OUTPUT="eDP-1"
readonly LOGIND_BUS="org.freedesktop.login1"
readonly LOGIND_PATH="/org/freedesktop/login1"
readonly LOGIND_INTERFACE="org.freedesktop.login1.Manager"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly STATE_LOG="$STATE_DIR/hypr-clamshell.log"

log() {
    local timestamp
    local message="hypr-clamshell: $*"

    timestamp="$(date --iso-8601=seconds)"
    printf '%s\n' "$message"
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s %s\n' "$timestamp" "$message" >>"$STATE_LOG" 2>/dev/null || true
}

log_workspace_state() {
    local timestamp
    timestamp="$(date --iso-8601=seconds)"

    hyprctl workspaces -j 2>/dev/null |
        jq -r '.[] | "workspace \(.id) on \(.monitor)"' 2>/dev/null |
        while IFS= read -r workspace; do
            printf '%s hypr-clamshell: %s\n' "$timestamp" "$workspace" >>"$STATE_LOG" 2>/dev/null || true
        done
}

set_laptop_panel_enabled() {
    local enabled="$1"
    local disabled="true"

    if [[ "$enabled" == "true" ]]; then
        disabled="false"
    fi

    if hyprctl eval "hl.monitor({ output = '${LAPTOP_OUTPUT}', mode = '1920x1080@144', position = '0x0', scale = '1.2', disabled = ${disabled} })" >/dev/null 2>&1; then
        if [[ "$enabled" == "true" ]]; then
            # Also clear DPMS in case the panel was blanked separately.
            hyprctl dispatch "hl.dsp.dpms({ monitor = '${LAPTOP_OUTPUT}', action = 'enable' })" >/dev/null 2>&1 || true
        fi
        return 0
    fi

    return 1
}

laptop_panel_exists() {
    hyprctl monitors -j 2>/dev/null |
        jq -e --arg laptop "$LAPTOP_OUTPUT" 'any(.[]; .name == $laptop)' >/dev/null 2>&1
}

# Let logind finish processing the ACPI event before querying its property.
if [[ "${1:-}" != "--sync" ]]; then
    sleep 0.3
fi

lid_closed="$(busctl --system get-property "$LOGIND_BUS" "$LOGIND_PATH" "$LOGIND_INTERFACE" LidClosed 2>/dev/null | awk '{print $2}')"

case "$lid_closed" in
    true)
        external_count="$(
            hyprctl monitors -j 2>/dev/null |
                jq --arg laptop "$LAPTOP_OUTPUT" '[.[] | select(.name != $laptop)] | length' 2>/dev/null
        )"

        # If Hyprland is unavailable or its state cannot be read, do not risk
        # disabling the only known output.
        if [[ "$external_count" =~ ^[0-9]+$ ]] && (( external_count > 0 )); then
            if ! laptop_panel_exists; then
                log 'lid already closed; workspaces remain on the external display'
            elif set_laptop_panel_enabled false; then
                log 'lid closed; migrated workspaces to the external display'
                log_workspace_state
            else
                log 'lid closed, but Hyprland could not disable the laptop panel'
            fi
        else
            log 'lid closed without a readable external display; leaving the laptop panel unchanged'
        fi
        ;;
    false)
        if laptop_panel_exists; then
            log 'lid already open; laptop display remains active'
            log_workspace_state
        elif set_laptop_panel_enabled true; then
            log 'lid open; restored the laptop display'
            log_workspace_state
        else
            log 'lid open, but Hyprland could not restore the laptop display'
        fi
        ;;
    *)
        # Unknown state must fail open, not risk a black laptop screen.
        if laptop_panel_exists; then
            log 'unknown lid state; laptop display remains active as a safety measure'
        elif set_laptop_panel_enabled true; then
            log 'unknown lid state; restored the laptop display as a safety measure'
        else
            log "unknown lid state (${lid_closed:-unreadable}); could not restore the laptop display"
        fi
        ;;
esac
