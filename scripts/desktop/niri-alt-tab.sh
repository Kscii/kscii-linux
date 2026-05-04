#!/usr/bin/env bash
# niri 窗口切换器（Alt+Tab）
#
# 行为（近似 GNOME Alt+Tab）：
#   单次按下  → 立即切换到上一个聚焦的窗口
#   0.75 秒内连按两次 → 打开窗口选择器（fuzzel 列表）
#
# 依赖：niri-focus-daemon.sh 需在后台运行（负责记录焦点历史）

HISTORY="$HOME/.cache/niri-focus-history"
FLAG="/tmp/niri-alt-tab-flag"
TIMER_PID="/tmp/niri-alt-tab-timer.pid"
DELAY=0.75

# ── 双击检测 ──────────────────────────────────────────────────────────────
if [[ -f "$FLAG" ]]; then
    # 在延迟窗口内检测到第二次按下 → 显示窗口选择器
    rm -f "$FLAG"
    kill "$(cat "$TIMER_PID" 2>/dev/null)" 2>/dev/null
    rm -f "$TIMER_PID"
    exec "$(dirname "$0")/niri-window-picker.sh"
fi

# ── 第一次按下：切换到上一个窗口 ─────────────────────────────────────────
touch "$FLAG"

CURRENT=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')

if [[ -f "$HISTORY" ]]; then
    while IFS= read -r id; do
        # 跳过当前聚焦的窗口
        [[ "$id" == "$CURRENT" ]] && continue
        # 尝试聚焦 —— 若窗口仍存在则成功
        if niri msg action focus-window --id "$id" 2>/dev/null; then
            break
        fi
    done < "$HISTORY"
fi

# 延迟窗口结束后清除标志文件
(sleep "$DELAY" && rm -f "$FLAG" "$TIMER_PID") &
echo $! > "$TIMER_PID"
