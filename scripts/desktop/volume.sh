#!/usr/bin/env bash
# Change PipeWire volume and show a compact notification.

set -euo pipefail

usage() {
    printf 'Usage: volume.sh up|down|mute|mic-mute\n' >&2
}

sink='@DEFAULT_AUDIO_SINK@'
source='@DEFAULT_AUDIO_SOURCE@'

volume_percent() {
    wpctl get-volume "$sink" | awk '{
        muted = ($0 ~ /\[MUTED\]/)
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9.]+$/) {
                printf "%d %s\n", int(($i * 100) + 0.5), muted ? "muted" : "unmuted"
                exit
            }
        }
    }'
}

notify_volume() {
    local state volume label urgency
    read -r volume state < <(volume_percent)

    if [[ "$state" == "muted" ]]; then
        label="Muted"
        urgency="low"
    else
        label="${volume}%"
        urgency="low"
    fi

    notify-send \
        -a "Volume" \
        -u "$urgency" \
        -h "string:x-canonical-private-synchronous:volume" \
        -h "int:value:${volume}" \
        "Volume" "$label" 2>/dev/null || true
}

notify_mic() {
    local text
    if wpctl get-volume "$source" | grep -q '\[MUTED\]'; then
        text="Muted"
    else
        text="On"
    fi

    notify-send \
        -a "Volume" \
        -u low \
        -h "string:x-canonical-private-synchronous:microphone" \
        "Microphone" "$text" 2>/dev/null || true
}

case "${1:-}" in
    up)
        wpctl set-mute "$sink" 0
        wpctl set-volume "$sink" 0.05+ -l 1.0
        notify_volume
        ;;
    down)
        wpctl set-mute "$sink" 0
        wpctl set-volume "$sink" 0.05-
        notify_volume
        ;;
    mute)
        wpctl set-mute "$sink" toggle
        notify_volume
        ;;
    mic-mute)
        wpctl set-mute "$source" toggle
        notify_mic
        ;;
    *)
        usage
        exit 2
        ;;
esac
