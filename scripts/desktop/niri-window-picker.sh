#!/usr/bin/env bash
# niri 窗口选择器 — 由 Alt+Shift+Tab 或 Alt+Tab 双击触发
# 通过 fuzzel（dmenu 模式）列出所有打开的窗口，选中后聚焦。
# 格式："ID\t[app_id]  窗口标题"

CURRENT=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')

selected=$(niri msg -j windows 2>/dev/null \
    | jq -r --arg cur "$CURRENT" '
        .[] | select(.id != ($cur | tonumber)) |
        "\(.id)\t[\(.app_id // "?")]  \(.title // "(无标题)")"
    ' \
    | fuzzel \
        --dmenu \
        --prompt="⊞  " \
        --width=60 \
        --lines=12 \
        --font="IBM Plex Mono:size=13")

[[ -z "$selected" ]] && exit 0

window_id=$(printf '%s' "$selected" | cut -f1)
niri msg action focus-window --id "$window_id"
