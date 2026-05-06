#!/usr/bin/env bash
# ThinkPad Engineering Edition — 桌面配置脚本
# 部署点文件和桌面脚本；不重新安装软件包。
# 请在安装软件包后运行（参见 packages/*.txt）。
#
# 用法：bash scripts/desktop/setup.sh [--dry-run]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
SCRIPTS_DIR="$REPO_DIR/scripts/desktop"
BIN_DIR="$HOME/.local/bin"
DRY_RUN=0

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# ── 颜色输出辅助函数 ──────────────────────────────────────────────────────
RED='\033[1;31m'; GRN='\033[1;32m'; BLU='\033[1;34m'; RST='\033[0m'
info()  { echo -e "${BLU}[*]${RST} $*"; }
ok()    { echo -e "${GRN}[✔]${RST} $*"; }
warn()  { echo -e "${RED}[!]${RST} $*"; }
run()   { if [[ $DRY_RUN -eq 1 ]]; then echo "  (dry) $*"; else "$@"; fi; }

current_login_shell() {
    getent passwd "$USER" | cut -d: -f7
}

update_managed_niri_output_block() {
    local config_path="$1"
    local output_name="$2"
    local output_mode="$3"
    local output_scale="$4"
    local output_transform="$5"
    local tmp

    tmp="$(mktemp)"
    awk -v name="$output_name" -v mode="$output_mode" -v scale="$output_scale" -v transform="$output_transform" '
        BEGIN { in_block = 0 }
        /AUTO-DETECTED OUTPUT START/ {
            print
            print "output \"" name "\" {"
            print "    mode \"" mode "\""
            print "    scale " scale
            print "    transform \"" transform "\""
            print "}"
            in_block = 1
            next
        }
        /AUTO-DETECTED OUTPUT END/ {
            in_block = 0
            print
            next
        }
        !in_block { print }
    ' "$config_path" > "$tmp"

    mv "$tmp" "$config_path"
}

auto_configure_niri_output() {
    local config_path="$HOME/.config/niri/config.kdl"
    local detect_log="$HOME/.config/niri/detected-output.txt"
    local outputs output_name output_mode output_scale output_transform

    [[ $DRY_RUN -eq 1 ]] && return 0

    if [[ -z "${NIRI_SOCKET:-}" ]]; then
        warn "未检测到 NIRI_SOCKET — 跳过自动写入显示输出配置"
        return 0
    fi

    if ! command -v niri &>/dev/null; then
        warn "找不到 niri 命令 — 跳过自动写入显示输出配置"
        return 0
    fi

    outputs="$(niri msg outputs 2>/dev/null || true)"
    if [[ -z "$outputs" ]]; then
        warn "无法读取当前 niri 输出信息 — 跳过自动写入显示输出配置"
        return 0
    fi

    output_name="$(printf '%s\n' "$outputs" | sed -n '1s/.*(\([^)]*\)).*/\1/p')"
    output_mode="$(printf '%s\n' "$outputs" | sed -n 's/^  Current mode: \([^ ]*\) @ \([^ ]*\) Hz.*/\1@\2/p')"
    output_scale="$(printf '%s\n' "$outputs" | sed -n 's/^  Scale: \(.*\)$/\1/p')"
    output_transform="$(printf '%s\n' "$outputs" | sed -n 's/^  Transform: \(.*\)$/\1/p')"

    {
        printf 'NIRI_SOCKET=%s\n' "${NIRI_SOCKET}"
        printf '%s\n' "$outputs"
    } > "$detect_log"

    if [[ -z "$output_name" || -z "$output_mode" || -z "$output_scale" || -z "$output_transform" ]]; then
        warn "输出信息解析不完整，已记录到：$detect_log"
        return 0
    fi

    update_managed_niri_output_block "$config_path" "$output_name" "$output_mode" "$output_scale" "$output_transform"
    ok "已自动写入 niri 输出配置：$output_name / $output_mode / scale $output_scale / $output_transform"
}

# ── 创建点文件符号链接 ────────────────────────────────────────────────────
# link_dotfile <点文件相对路径（相对于 dotfiles/）> <目标路径>
link_dotfile() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"
    run mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        run cp -a "$dst" "${dst}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "已备份现有文件：$dst"
    fi
    run ln -sfn "$src" "$dst"
    ok "已链接：$dst → $src"
}

# ── 安装脚本到 ~/.local/bin ───────────────────────────────────────────────
install_script() {
    local src="$SCRIPTS_DIR/$1"
    local name="${2:-$1}"
    run mkdir -p "$BIN_DIR"
    run cp "$src" "$BIN_DIR/$name"
    run chmod +x "$BIN_DIR/$name"
    ok "已安装脚本：$BIN_DIR/$name"
}

# ═══════════════════════════════════════════════════════════════════════════

echo ""
info "ThinkPad Engineering Edition — 点文件部署"
[[ $DRY_RUN -eq 1 ]] && warn "演习模式（DRY RUN）— 不会实际修改任何文件"
echo ""

# ── niri 合成器 ───────────────────────────────────────────────────────────
info "部署 niri 配置..."
link_dotfile "niri/config.kdl" "$HOME/.config/niri/config.kdl"
auto_configure_niri_output

# ── waybar 状态栏 ─────────────────────────────────────────────────────────
info "部署 waybar..."
link_dotfile "waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
link_dotfile "waybar/style.css"    "$HOME/.config/waybar/style.css"

# ── kitty 终端 ────────────────────────────────────────────────────────────
info "部署 kitty..."
link_dotfile "kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# ── mako 通知 ─────────────────────────────────────────────────────────────
info "部署 mako..."
link_dotfile "mako/config" "$HOME/.config/mako/config"

# ── fcitx5 输入法框架 ─────────────────────────────────────────────────────
info "部署 fcitx5..."
link_dotfile "fcitx5/profile"             "$HOME/.config/fcitx5/profile"
link_dotfile "fcitx5/config"              "$HOME/.config/fcitx5/config"
link_dotfile "fcitx5/conf/classicui.conf" "$HOME/.config/fcitx5/conf/classicui.conf"
link_dotfile "fcitx5/themes/ThinkPad/theme.conf" \
    "$HOME/.local/share/fcitx5/themes/ThinkPad/theme.conf"

# ── Rime 输入法 ───────────────────────────────────────────────────────────
info "部署 Rime..."
link_dotfile "rime/default.custom.yaml"  "$HOME/.local/share/fcitx5/rime/default.custom.yaml"
link_dotfile "rime/rime_ice.custom.yaml" "$HOME/.local/share/fcitx5/rime/rime_ice.custom.yaml"

# ── swaylock 锁屏 ─────────────────────────────────────────────────────────
info "部署 swaylock..."
link_dotfile "swaylock/config" "$HOME/.config/swaylock/config"

# ── 电源与空闲策略 ────────────────────────────────────────────────────────
info "部署电源与空闲策略..."
link_dotfile "kscii-power/policy.conf" "$HOME/.config/kscii-power/policy.conf"

# ── fish shell ────────────────────────────────────────────────────────────
info "部署 fish..."
link_dotfile "fish/config.fish" "$HOME/.config/fish/config.fish"

# ── starship 提示符 ───────────────────────────────────────────────────────
info "部署 starship..."
link_dotfile "starship.toml" "$HOME/.config/starship.toml"

# ── fuzzel 启动器 ─────────────────────────────────────────────────────────
info "部署 fuzzel..."
link_dotfile "fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"

# ── XDG 桌面门户 ──────────────────────────────────────────────────────────
info "部署 xdg-desktop-portal..."
link_dotfile "xdg-desktop-portal/portals.conf" \
    "$HOME/.config/xdg-desktop-portal/portals.conf"

# ── fontconfig 字体优先级 ─────────────────────────────────────────────────
info "部署 fontconfig..."
link_dotfile "fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# ── GTK 主题与 GTK4 覆盖 ──────────────────────────────────────────────────
info "部署 GTK 主题与覆盖..."
link_dotfile "gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
link_dotfile "gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
link_dotfile "gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"

# ── btop 系统监控 ─────────────────────────────────────────────────────────
info "部署 btop..."
link_dotfile "btop/btop.conf"             "$HOME/.config/btop/btop.conf"
link_dotfile "btop/themes/thinkpad.theme" "$HOME/.config/btop/themes/thinkpad.theme"

# ── yazi 文件管理器 ───────────────────────────────────────────────────────
info "部署 yazi..."
link_dotfile "yazi/theme.toml" "$HOME/.config/yazi/theme.toml"

# ── fastfetch 系统信息 ────────────────────────────────────────────────────
info "部署 fastfetch..."
link_dotfile "fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# ── 默认应用关联 ──────────────────────────────────────────────────────────
info "部署 mimeapps.list..."
link_dotfile "mimeapps.list" "$HOME/.config/mimeapps.list"

# ── 自定义桌面入口 ────────────────────────────────────────────────────────
info "部署桌面入口文件..."
link_dotfile "applications/nvim-kitty.desktop"    "$HOME/.local/share/applications/nvim-kitty.desktop"
link_dotfile "applications/archive-kitty.desktop" "$HOME/.local/share/applications/archive-kitty.desktop"

# ── XDG 终端偏好 ──────────────────────────────────────────────────────────
info "部署 xdg-terminals.list..."
link_dotfile "xdg-terminals.list" "$HOME/.config/xdg-terminals.list"

# ── 桌面脚本 → ~/.local/bin ───────────────────────────────────────────────
info "安装桌面脚本到 $BIN_DIR..."
install_script "niri-focus-daemon.sh"  "niri-focus-daemon.sh"
install_script "niri-alt-tab.sh"       "niri-alt-tab.sh"
install_script "niri-window-picker.sh" "niri-window-picker.sh"
install_script "niri-lock.sh"          "niri-lock.sh"
install_script "niri-record.sh"        "niri-record.sh"
install_script "lock-session.sh"       "lock-session"
install_script "suspend-session.sh"    "suspend-session"
install_script "swayidle-start.sh"     "swayidle-start.sh"
install_script "waybar-ime.sh"         "waybar-ime.sh"
install_script "volume.sh"             "volume.sh"
install_script "gen-logo.py"           "gen-logo"

# ── 生成 fastfetch 球形 Logo ──────────────────────────────────────────────
if command -v python3 &>/dev/null; then
    info "生成 fastfetch Logo（TrackPoint 球形）..."
    run python3 "$BIN_DIR/gen-logo" 2>/dev/null || warn "Logo 生成失败，请手动运行：gen-logo"
fi

# ── 设置 fish 为默认 shell ────────────────────────────────────────────────
if [[ "$(current_login_shell)" != "$(command -v fish)" ]]; then
    info "将 fish 设为默认 shell..."
    if command -v fish &>/dev/null; then
        if run chsh -s "$(command -v fish)"; then
            ok "默认 shell 已设置为 fish"
        else
            warn "fish 默认 shell 设置失败，请手动重试：chsh -s $(command -v fish)"
        fi
    else
        warn "找不到 fish — 跳过 shell 切换"
    fi
else
    ok "默认 shell 已经是 fish"
fi

# ── 用户音频服务 ──────────────────────────────────────────────────────────
if command -v systemctl &>/dev/null && systemctl --user show &>/dev/null 2>&1; then
    info "启用用户音频服务..."
    for _svc in pipewire pipewire-pulse wireplumber; do
        if run systemctl --user enable --now "$_svc" 2>/dev/null; then
            ok "音频服务：$_svc"
        else
            warn "无法启用 $_svc（首次登录后常见，可在重新登录后重试：systemctl --user enable --now $_svc）"
        fi
    done
fi

# ── 重建 Rime 数据库 ──────────────────────────────────────────────────────
if command -v rime_deployer &>/dev/null; then
    info "重建 Rime 数据库..."
    if run rime_deployer --build "$HOME/.local/share/fcitx5/rime/"; then
        ok "Rime 数据库已重建"
    else
        warn "Rime 数据库重建失败，可稍后手动重试：rime_deployer --build $HOME/.local/share/fcitx5/rime/"
    fi
elif [[ $DRY_RUN -eq 0 ]]; then
    warn "找不到 rime_deployer — 请重启 fcitx5 以应用 Rime 配置"
fi

# ── 应用 GTK 深色主题 ─────────────────────────────────────────────────────
if command -v gsettings &>/dev/null; then
    info "应用 GTK 深色主题..."
    run gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    run gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    run gsettings set org.gnome.desktop.interface font-name "IBM Plex Sans 11"
    run gsettings set org.gnome.desktop.interface monospace-font-name "IBM Plex Mono 11"
    run gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
    run gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    ok "GTK 设置已应用"
fi

# ── 完成 ──────────────────────────────────────────────────────────────────
echo ""
ok "配置完成。"
echo ""
echo "  后续步骤："
echo "  1. 确认 ~/.config/niri/config.kdl 中的输出配置是否已按当前机器自动写入"
echo "     （检测记录位于 ~/.config/niri/detected-output.txt）"
echo "  2. 退出并重新登录到 niri 会话。"
echo "  3. 快捷键参考：docs/keybindings.md"
echo ""
