#!/usr/bin/env bash
# niri 窗口焦点历史守护进程（供 niri-alt-tab.sh 使用）
# 由 niri 在启动时自动拉起（niri/config.kdl 中的 spawn-at-startup）。
# 历史文件：~/.cache/niri-focus-history（每行一个窗口 ID，最新的在最前）

HISTORY="$HOME/.cache/niri-focus-history"
mkdir -p "$(dirname "$HISTORY")"
touch "$HISTORY"

# 等待 niri IPC 就绪
until niri msg version &>/dev/null; do sleep 0.5; done

niri msg event-stream 2>/dev/null | while IFS= read -r line; do
    # 从 WindowFocused 事件中提取窗口 ID
    id=$(printf '%s' "$line" \
        | jq -r 'if .WindowFocused then .WindowFocused.id
                 elif .window_focused then .window_focused.id
                 else empty end' 2>/dev/null)
    [[ -z "$id" ]] && continue

    # 将新 ID 插到最前，去重，保留最近 20 条记录
    (echo "$id"
     grep -v "^${id}$" "$HISTORY" 2>/dev/null | head -19) > "${HISTORY}.tmp"
    mv "${HISTORY}.tmp" "$HISTORY"
done
