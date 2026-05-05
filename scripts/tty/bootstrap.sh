#!/usr/bin/env bash
# ThinkPad Engineering Edition — TTY 引导脚本
# 在最小化 Arch Linux TTY 阶段以 root 身份运行。
# 用法：sudo bash scripts/tty/bootstrap.sh

set -euo pipefail

_BOOTSTRAP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_BOOTSTRAP_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${REPO_ROOT}/lib/network.sh"
# shellcheck source=lib/packages.sh
source "${REPO_ROOT}/lib/packages.sh"

require_root

trap 'print_error "脚本在第 ${LINENO} 行停止。"; print_info "修复上述问题后重新运行：sudo bash scripts/tty/bootstrap.sh"' ERR

print_step "引导开始"
print_info "本脚本在最小化 Arch Linux TTY 阶段运行。"

if ! confirm_yes_no "现在开始引导？（这是整个流程中唯一的确认提示）" yes; then
  print_warn "用户取消引导。"
  exit 0
fi

if ! is_online; then
  print_warn "网络离线。"
  print_info "正在打开网络重连向导..."
  interactive_reconnect_network
fi

if ! is_online; then
  print_error "网络仍然离线，停止执行。"
  exit 1
fi

if ! install_all_groups_interactive; then
  print_error "软件包安装流程失败。"
  exit 1
fi

print_step "确保系统服务已启用"
ensure_service_enabled_running NetworkManager
ensure_service_enabled_running sshd
ensure_service_enabled_running bluetooth

# ── 安装 paru AUR 助手 ────────────────────────────────────────────────────
print_step "安装 paru AUR 助手"
REGULAR_USER="${SUDO_USER:-}"

if [[ -z "$REGULAR_USER" ]]; then
  print_warn "SUDO_USER 未设置 — 跳过 paru 安装"
  print_info "配置完成后，以普通用户身份手动安装 paru："
  print_info "  sudo pacman -Syu && sudo pacman -S --needed base-devel git rust"
  print_info "  git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
elif command -v paru &>/dev/null && paru --version >/dev/null 2>&1; then
  print_info "paru 已安装且可用 — 跳过"
else
  print_info "准备以源码方式构建 paru（兼容最新 libalpm）..."
  pacman -S --needed --noconfirm rust

  # 已安装但损坏的 paru/paru-bin 往往会与新版包冲突，先清理。
  pacman -Rns --noconfirm paru paru-debug paru-bin paru-bin-debug 2>/dev/null || true

  # 临时 NOPASSWD 条目，使 makepkg 能以无密码方式运行 pacman -U
  echo "${REGULAR_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-paru-build
  runuser -l "${REGULAR_USER}" -c "
    set -euo pipefail
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git paru
    cd paru
    makepkg -si --noconfirm
  "
  rm -f /etc/sudoers.d/99-paru-build
  print_info "paru 已安装"
fi

# ── 安装 AUR 软件包 ───────────────────────────────────────────────────────
print_step "安装 AUR 软件包"
AUR_LIST="${REPO_ROOT}/packages/aur.txt"

if [[ -z "$REGULAR_USER" ]]; then
  print_warn "SUDO_USER 未设置 — 跳过 AUR 软件包"
  print_info "请手动安装：paru -S --skipreview rime-ice-git"
elif ! command -v paru &>/dev/null || ! paru --version >/dev/null 2>&1; then
  print_warn "找不到 paru — 跳过 AUR 软件包"
  print_info "请先安装 paru，然后运行：paru -S --skipreview rime-ice-git"
elif [[ -f "$AUR_LIST" ]]; then
  mapfile -t _aur_pkgs < <(grep -v '^#' "$AUR_LIST" | grep -v '^[[:space:]]*$')
  if [[ ${#_aur_pkgs[@]} -gt 0 ]]; then
    print_info "安装 AUR 软件包（跳过 PKGBUILD review，避免 OSC 转义序列泄漏）：${_aur_pkgs[*]}"
    runuser -l "${REGULAR_USER}" -c "paru -S --skipreview --noconfirm ${_aur_pkgs[*]}"
    print_info "AUR 软件包已安装"
  fi
fi

print_step "引导完成"
print_info "系统服务已启用：NetworkManager、sshd、bluetooth。"
print_info "进入 niri 会话后，执行下一步："
printf "  bash %s/scripts/gui/post-niri.sh\n" "${REPO_ROOT}"
