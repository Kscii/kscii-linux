#!/usr/bin/env bash
# Robust Wayland session lock entrypoint.

set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/swaylock/config"
THEME_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kscii-lock/config"
READY_TIMEOUT_SECONDS=8
LOCK_THEME="${LOCK_THEME:-minimal}"
LOCK_TEXT="${LOCK_TEXT:-kscii-linux locked}"
LOCK_COLOR="${LOCK_COLOR:-#E2000F}"
LOCK_BODY_COLOR="${LOCK_BODY_COLOR:-#e0e0e0}"
LOCK_FONT_QUERY="${LOCK_FONT_QUERY:-IBM Plex Mono}"
LOCK_FONT_SIZE="${LOCK_FONT_SIZE:-34}"
LOCK_BODY_FONT_SIZE="${LOCK_BODY_FONT_SIZE:-26}"
LOCK_MARGIN_X="${LOCK_MARGIN_X:-40}"
LOCK_MARGIN_Y="${LOCK_MARGIN_Y:-38}"
LOCK_BODY_OFFSET_Y="${LOCK_BODY_OFFSET_Y:-58}"
FASTFETCH_MODE="${FASTFETCH_MODE:-runtime}"
FASTFETCH_TIMEOUT="${FASTFETCH_TIMEOUT:-2}"
FASTFETCH_INCLUDE_LOGO="${FASTFETCH_INCLUDE_LOGO:-1}"
FASTFETCH_LOGO_SOURCE="${FASTFETCH_LOGO_SOURCE:-${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/logos/trackpoint_rounder.txt}"
FASTFETCH_CACHE_DIR="${FASTFETCH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/kscii-lock}"
FASTFETCH_CACHE="${FASTFETCH_CACHE:-${FASTFETCH_CACHE_DIR}/fastfetch.txt}"
FASTFETCH_LOGO_CACHE="${FASTFETCH_LOGO_CACHE:-${FASTFETCH_CACHE_DIR}/fastfetch-logo.txt}"
FASTFETCH_INFO_CACHE="${FASTFETCH_INFO_CACHE:-${FASTFETCH_CACHE_DIR}/fastfetch-info.txt}"
LOCK_INFO_OFFSET_X="${LOCK_INFO_OFFSET_X:-620}"

if [[ -r "$THEME_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$THEME_CONFIG"
fi

if pgrep -xu "$USER" swaylock >/dev/null 2>&1; then
    exit 0
fi

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'lock-session: WAYLAND_DISPLAY is not set; refusing to start swaylock outside a Wayland session.\n' >&2
    exit 1
fi

if [[ ! -r "$CONFIG" ]]; then
    printf 'lock-session: missing swaylock config: %s\n' "$CONFIG" >&2
    exit 1
fi

tmpdir="$(mktemp -d)"
fifo="$tmpdir/swaylock-ready"
mkfifo "$fifo"
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

lock_args=(--config "$CONFIG" --daemonize --ready-fd 3 --scaling stretch)

font_file() {
    local font=""

    if command -v fc-match >/dev/null 2>&1; then
        font="$(fc-match -f '%{file}\n' "$LOCK_FONT_QUERY" 2>/dev/null | head -n 1)"
    fi

    [[ -n "$font" && -r "$font" ]] || font="/usr/share/fonts/TTF/DejaVuSansMono.ttf"
    printf '%s\n' "$font"
}

strip_terminal_control() {
    perl -CS -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e\][^\a]*(\a|\e\\)//g'
}

trim_blank_edges() {
    perl -CS -0pe 's/\A(?:[ \t]*\n)+//; s/(?:\n[ \t]*)+\z/\n/'
}

refresh_fastfetch_cache() {
    command -v fastfetch >/dev/null 2>&1 || return 1
    command -v perl >/dev/null 2>&1 || return 1

    mkdir -p "$FASTFETCH_CACHE_DIR"

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
}

fastfetch_text_files() {
    local logo="$tmpdir/fastfetch-logo.txt"
    local info="$tmpdir/fastfetch-info.txt"

    : > "$logo"
    : > "$info"

    if [[ "$LOCK_THEME" == "fastfetch" ]]; then
        if [[ "$FASTFETCH_MODE" == "runtime" ]]; then
            refresh_fastfetch_cache || true
        fi

        if [[ -s "$FASTFETCH_LOGO_CACHE" ]]; then
            cp "$FASTFETCH_LOGO_CACHE" "$logo"
        fi

        if [[ -s "$FASTFETCH_INFO_CACHE" ]]; then
            cp "$FASTFETCH_INFO_CACHE" "$info"
        elif [[ -s "$FASTFETCH_CACHE" ]]; then
            cp "$FASTFETCH_CACHE" "$info"
        fi
    fi

    printf '%s\t%s\n' "$logo" "$info"
}

render_lock_image() {
    local width="$1"
    local height="$2"
    local output="$3"
    local image="$4"
    local logo="$5"
    local info="$6"
    local font
    local body_y
    local info_x
    local magick_args

    font="$(font_file)"
    info_x=$((LOCK_MARGIN_X + LOCK_INFO_OFFSET_X))
    if [[ "$LOCK_THEME" == "fastfetch" ]]; then
        body_y="$LOCK_MARGIN_Y"
        magick_args=()
    else
        body_y=$((LOCK_MARGIN_Y + LOCK_BODY_OFFSET_Y))
        magick_args=(
            -fill "$LOCK_COLOR"
            -pointsize "$LOCK_FONT_SIZE"
            -annotate "+${LOCK_MARGIN_X}+${LOCK_MARGIN_Y}" "$LOCK_TEXT"
        )
    fi

    magick -size "${width}x${height}" "xc:#000000" \
        -font "$font" \
        -gravity northwest \
        "${magick_args[@]}" \
        -fill "$LOCK_COLOR" \
        -pointsize "$LOCK_BODY_FONT_SIZE" \
        -annotate "+${LOCK_MARGIN_X}+${body_y}" "@$logo" \
        -fill "$LOCK_BODY_COLOR" \
        -pointsize "$LOCK_BODY_FONT_SIZE" \
        -annotate "+${info_x}+${body_y}" "@$info" \
        "$image"

    if [[ -n "$output" ]]; then
        lock_args+=(--image "${output}:$image")
    else
        lock_args+=(--image "$image")
    fi
}

add_lock_images() {
    local outputs_json
    local rendered=0
    local logo
    local info

    command -v magick >/dev/null 2>&1 || return 0
    IFS=$'\t' read -r logo info < <(fastfetch_text_files)

    if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        outputs_json="$(niri msg -j outputs 2>/dev/null || true)"
        if [[ -n "$outputs_json" ]]; then
            while IFS=$'\t' read -r output width height; do
                [[ -n "$output" && "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] || continue
                render_lock_image "$width" "$height" "$output" "$tmpdir/lock-${output//[^A-Za-z0-9_.-]/_}.png" "$logo" "$info"
                rendered=1
            done < <(
                jq -r '
                    to_entries[]
                    | .key as $name
                    | .value as $out
                    | ($out.current_mode // 0) as $mode
                    | ($out.modes[$mode].width // $out.logical.width // 1920) as $width
                    | ($out.modes[$mode].height // $out.logical.height // 1080) as $height
                    | [$name, $width, $height]
                    | @tsv
                ' <<<"$outputs_json"
            )
        fi
    fi

    if [[ "$rendered" -eq 0 ]]; then
        render_lock_image 1920 1080 "" "$tmpdir/lock.png" "$logo" "$info"
    fi
}

add_lock_images

swaylock "${lock_args[@]}" 3>"$fifo" &
lock_launcher_pid=$!

if ! timeout "${READY_TIMEOUT_SECONDS}s" bash -c 'IFS= read -r _ < "$1"' bash "$fifo"; then
    printf 'lock-session: timed out waiting for swaylock readiness.\n' >&2
    kill "$lock_launcher_pid" >/dev/null 2>&1 || true
    exit 1
fi

wait "$lock_launcher_pid" >/dev/null 2>&1 || true
