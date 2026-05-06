#!/usr/bin/env bash
# Refresh cached fastfetch text for the lock screen.

set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kscii-lock/config"

LOCK_THEME=fastfetch
FASTFETCH_MODE=runtime
FASTFETCH_TIMEOUT=2
FASTFETCH_INCLUDE_LOGO=1
FASTFETCH_LOGO_SOURCE="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/logos/trackpoint_rounder.txt"
FASTFETCH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/kscii-lock"
FASTFETCH_CACHE="${FASTFETCH_CACHE_DIR}/fastfetch.txt"
FASTFETCH_LOGO_CACHE="${FASTFETCH_CACHE_DIR}/fastfetch-logo.txt"
FASTFETCH_INFO_CACHE="${FASTFETCH_CACHE_DIR}/fastfetch-info.txt"

if [[ -r "$CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG"
fi

strip_terminal_control() {
    perl -CS -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e\][^\a]*(\a|\e\\)//g'
}

trim_blank_edges() {
    perl -CS -0pe 's/\A(?:[ \t]*\n)+//; s/(?:\n[ \t]*)+\z/\n/'
}

mkdir -p "$FASTFETCH_CACHE_DIR"

if ! command -v fastfetch >/dev/null 2>&1; then
    printf 'update-lock-fastfetch: fastfetch is not installed.\n' >&2
    exit 1
fi

if ! command -v perl >/dev/null 2>&1; then
    printf 'update-lock-fastfetch: perl is required to sanitize fastfetch output.\n' >&2
    exit 1
fi

timeout "${FASTFETCH_TIMEOUT}s" fastfetch --logo none --pipe \
    | strip_terminal_control \
    | trim_blank_edges \
    > "$FASTFETCH_INFO_CACHE"

if [[ "${FASTFETCH_INCLUDE_LOGO}" == "1" && -r "$FASTFETCH_LOGO_SOURCE" ]]; then
    strip_terminal_control < "$FASTFETCH_LOGO_SOURCE" \
        | trim_blank_edges \
        > "$FASTFETCH_LOGO_CACHE"
else
    : > "$FASTFETCH_LOGO_CACHE"
fi

{
    if [[ -s "$FASTFETCH_LOGO_CACHE" ]]; then
        sed -n '1,120p' "$FASTFETCH_LOGO_CACHE"
        printf '\n'
    fi
    sed -n '1,160p' "$FASTFETCH_INFO_CACHE"
} > "$FASTFETCH_CACHE"

printf 'Updated %s and %s\n' "$FASTFETCH_LOGO_CACHE" "$FASTFETCH_INFO_CACHE"
