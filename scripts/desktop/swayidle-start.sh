#!/usr/bin/env bash
# ThinkPad Engineering Edition — idle policy daemon
# Reads ~/.config/kscii-power/policy.conf at startup.

set -euo pipefail

POLICY="${XDG_CONFIG_HOME:-$HOME/.config}/kscii-power/policy.conf"
LOCK_AFTER_SECONDS=600
BATTERY_SUSPEND_AFTER_SECONDS=1200
AC_SUSPEND_AFTER_SECONDS=0

if [[ -r "$POLICY" ]]; then
    # shellcheck source=/dev/null
    source "$POLICY"
fi

bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
args=(
    -w
    timeout "$LOCK_AFTER_SECONDS" "$bin_dir/lock-session"
    before-sleep "$bin_dir/lock-session"
)

if [[ "${BATTERY_SUSPEND_AFTER_SECONDS:-0}" -gt 0 ]]; then
    args+=(timeout "$BATTERY_SUSPEND_AFTER_SECONDS" "$bin_dir/suspend-session --if-battery")
fi

if [[ "${AC_SUSPEND_AFTER_SECONDS:-0}" -gt 0 ]]; then
    args+=(timeout "$AC_SUSPEND_AFTER_SECONDS" "$bin_dir/suspend-session")
fi

exec swayidle "${args[@]}"
