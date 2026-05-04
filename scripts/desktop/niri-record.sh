#!/usr/bin/env bash
# niri 屏幕录制切换脚本
# 使用 wl-screenrec（硬件加速），降级回退到 wf-recorder
#
# 用法:
#   niri-record.sh region   → 切换区域录制（Mod+Print）
#   niri-record.sh screen   → 切换全屏录制（Mod+Shift+Print）

PID_FILE="/tmp/niri-record.pid"
OUTPUT_DIR="$HOME/Videos/Recordings"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_FILE="$OUTPUT_DIR/Recording_${TIMESTAMP}.mp4"

mkdir -p "$OUTPUT_DIR"

stop_recording() {
    if [[ -f "$PID_FILE" ]]; then
        kill -SIGINT "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
        notify-send -u normal "录制已保存" "$OUTPUT_DIR" --icon=video-x-generic
    fi
}

start_region() {
    local region
    region=$(slurp 2>/dev/null) || exit 0  # 用户取消选择

    if command -v wl-screenrec &>/dev/null; then
        wl-screenrec --geometry "$region" -f "$OUTPUT_FILE" &
    else
        wf-recorder --geometry "$region" -f "$OUTPUT_FILE" &
    fi
    echo $! > "$PID_FILE"
    notify-send -u low "录制已开始" "区域录制 — 再按 Mod+Print 停止" --icon=media-record
}

start_screen() {
    if command -v wl-screenrec &>/dev/null; then
        wl-screenrec -f "$OUTPUT_FILE" &
    else
        wf-recorder -f "$OUTPUT_FILE" &
    fi
    echo $! > "$PID_FILE"
    notify-send -u low "录制已开始" "全屏录制 — 再按 Mod+Shift+Print 停止" --icon=media-record
}

# ── 切换逻辑 ──────────────────────────────────────────────────────────────
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    stop_recording
else
    case "${1:-screen}" in
        region) start_region ;;
        screen) start_screen ;;
    esac
fi
