#!/usr/bin/env bash
# ThinkPad Engineering Edition — 锁屏脚本
#
# 用法:
#   niri-lock.sh                     → 锁屏（若存在壁纸则自动使用）
#   niri-lock.sh --art               → 使用已保存的锁屏壁纸
#   niri-lock.sh --plain             → 纯黑锁屏（OLED 省电）
#   niri-lock.sh --generate [风格]
#       将锁屏图片渲染到 ~/.config/swaylock/lockscreen.png
#       可用风格（默认: sphere）:
#         sphere      — TrackPoint 球形 ASCII 艺术（统一发行版 Logo）
#         thinkpad    — THINKPAD 像素字体文字
#         kscii-upper — 大写 "KSCII LINUX"（figlet）
#         kscii-lower — 小写 "kscii linux"（figlet）
#         kscii-nospace — 无空格 "KSCIILINUX"（figlet）
#         kscii-only  — 仅 "KSCII"（figlet）

ART_IMAGE="$HOME/.config/swaylock/lockscreen.png"
DISPLAY_SIZE="2880x1800"   # 根据实机调整（运行 niri msg outputs 查询）
FONT="IBM Plex Mono"

_require_imagemagick() {
    command -v convert &>/dev/null || { echo "需要 imagemagick（convert 命令）"; exit 1; }
    mkdir -p "$(dirname "$ART_IMAGE")"
}

# ── 风格：TrackPoint 球形（统一发行版 Logo）──────────────────────────────
_gen_sphere() {
    local gen_logo="$HOME/.local/bin/gen-logo"
    command -v python3 &>/dev/null || { echo "需要 python3"; exit 1; }
    if [[ ! -x "$gen_logo" ]]; then
        echo "找不到 gen-logo，请先运行 scripts/gui/post-niri.sh"
        exit 1
    fi

    local plain_art
    plain_art=$("$gen_logo" --plain)

    convert \
        -size "${DISPLAY_SIZE}" xc:#000000 \
        -font "$FONT" \
        -pointsize 50 \
        -fill '#E2000F' \
        -gravity Center \
        -annotate 0 "$plain_art" \
        "$ART_IMAGE"
}

# ── 风格：THINKPAD 像素字体 ────────────────────────────────────────────────
_gen_thinkpad() {
    convert \
        -size "${DISPLAY_SIZE}" xc:#000000 \
        -font "$FONT" \
        -pointsize 18 \
        -fill '#E2000F' \
        -gravity Center \
        -annotate 0 \
'  ████████╗██╗  ██╗██╗███╗   ██╗██╗  ██╗██████╗  █████╗ ██████╗
  ╚══██╔══╝██║  ██║██║████╗  ██║██║ ██╔╝██╔══██╗██╔══██╗██╔══██╗
     ██║   ███████║██║██╔██╗ ██║█████╔╝ ██████╔╝███████║██║  ██║
     ██║   ██╔══██║██║██║╚██╗██║██╔═██╗ ██╔═══╝ ██╔══██║██║  ██║
     ██║   ██║  ██║██║██║ ╚████║██║  ██╗██║     ██║  ██║██████╔╝
     ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═════╝' \
        "$ART_IMAGE"
}

# ── 风格：figlet 文字艺术 ──────────────────────────────────────────────────
_gen_figlet() {
    local text="$1"
    command -v figlet &>/dev/null || { echo "需要 figlet"; exit 1; }
    local art
    art="$(figlet -f slant "$text")"

    convert \
        -size "${DISPLAY_SIZE}" xc:#000000 \
        -font "$FONT" \
        -pointsize 28 \
        -fill '#E2000F' \
        -gravity Center \
        -annotate 0 "$art" \
        "$ART_IMAGE"
}

# ── 主函数：生成锁屏图片 ───────────────────────────────────────────────────
generate() {
    local variant="${1:-sphere}"
    _require_imagemagick

    case "$variant" in
        sphere)       _gen_sphere ;;
        thinkpad)     _gen_thinkpad ;;
        kscii-upper)  _gen_figlet "KSCII LINUX" ;;
        kscii-lower)  _gen_figlet "kscii linux" ;;
        kscii-nospace) _gen_figlet "KSCIILINUX" ;;
        kscii-only)   _gen_figlet "KSCII" ;;
        *)
            echo "未知风格：${variant}"
            echo "可用风格：sphere, thinkpad, kscii-upper, kscii-lower, kscii-nospace, kscii-only"
            exit 1
            ;;
    esac
    echo "锁屏图片已生成：${ART_IMAGE}（风格：${variant}）"
}

# ── 主函数：启动 swaylock ──────────────────────────────────────────────────
do_lock() {
    local mode="${1:-auto}"
    local image_arg=()

    if [[ "$mode" == "--art" || "$mode" == "auto" ]] && [[ -f "$ART_IMAGE" ]]; then
        image_arg=("--image=${ART_IMAGE}")
    fi

    swaylock \
        --config "$HOME/.config/swaylock/config" \
        "${image_arg[@]}"
}

# ── 命令分发 ───────────────────────────────────────────────────────────────
case "${1:-}" in
    --generate)     generate "${2:-sphere}" ;;
    --generate-art) generate "${2:-sphere}" ;;   # 向后兼容旧命令
    --plain)        do_lock "--plain" ;;
    --art)          do_lock "--art" ;;
    *)              do_lock "auto" ;;
esac
