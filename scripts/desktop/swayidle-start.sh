#!/usr/bin/env bash
# ThinkPad Engineering Edition — 空闲管理守护进程
# 由 niri 在启动时通过 spawn-sh-at-startup 拉起
#
# 时间线：
#   600 秒 （10 分钟） → 锁屏（swaylock）
#   2400 秒（40 分钟） → 关闭显示器（OLED 休眠）
#   before-sleep      → 合盖或挂起前锁屏

exec swayidle -w \
    timeout 600  "sh -c 'pgrep -x swaylock || swaylock'" \
    timeout 2400 "niri msg action power-off-monitors" \
    before-sleep "sh -c 'pgrep -x swaylock || swaylock'"
