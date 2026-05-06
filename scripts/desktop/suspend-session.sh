#!/usr/bin/env bash
# Lock first, then suspend. Optionally suspend only when running on battery.

set -euo pipefail

MODE="${1:-always}"

has_battery() {
    find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' 2>/dev/null | grep -q .
}

on_ac_power() {
    local supply type online found=0

    for supply in /sys/class/power_supply/*; do
        [[ -r "$supply/type" ]] || continue
        type="$(<"$supply/type")"
        [[ "$type" == "Mains" ]] || continue
        found=1
        online="$(<"$supply/online" 2>/dev/null || printf 0)"
        [[ "$online" == "1" ]] && return 0
    done

    # Desktops or systems without a battery are treated as AC-powered.
    [[ "$found" -eq 0 ]] && ! has_battery && return 0
    return 1
}

case "$MODE" in
    --if-battery|if-battery)
        if on_ac_power; then
            exit 0
        fi
        ;;
    always|"")
        ;;
    *)
        printf 'Usage: suspend-session.sh [always|--if-battery]\n' >&2
        exit 2
        ;;
esac

"${XDG_BIN_HOME:-$HOME/.local/bin}/lock-session"

systemctl suspend

