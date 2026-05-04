#!/usr/bin/env bash
# waybar 自定义模块：当前输入法状态
# 输出 JSON，包含显示文本（中/英）、CSS 类名（zh/en）和悬停提示
# 轮询间隔：1 秒（在 waybar config.jsonc 中设置）

im=$(fcitx5-remote -n 2>/dev/null)

case "$im" in
    rime)
        printf '{"text":"中","class":"zh","tooltip":"中文拼音 (Rime)"}\n'
        ;;
    *)
        printf '{"text":"英","class":"en","tooltip":"English (US)"}\n'
        ;;
esac
