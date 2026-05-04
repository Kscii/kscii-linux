#!/usr/bin/env bash

set -u

NETWORK_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${NETWORK_LIB_DIR}/common.sh"

is_online() {
  ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 1 archlinux.org >/dev/null 2>&1
}

ensure_networkmanager_running() {
  if ! systemctl is-active --quiet NetworkManager; then
    if confirm_yes_no "NetworkManager 未运行。是否立即启用并启动？" yes; then
      systemctl enable --now NetworkManager
      print_info "NetworkManager 已启动。"
    else
      print_warn "NetworkManager 仍未运行。"
      return 1
    fi
  fi
  return 0
}

interactive_reconnect_network() {
  print_step "网络重连向导"

  if is_online; then
    print_info "网络已连接。"
    if ! confirm_yes_no "是否仍要打开网络重连工具？" no; then
      return 0
    fi
  fi

  ensure_networkmanager_running || true

  if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
    if has_cmd nm-connection-editor; then
      print_info "正在打开网络面板（nm-connection-editor）。"
      nm-connection-editor >/dev/null 2>&1 &
      print_info "在面板中重新连接后，返回此终端并按 Enter 继续。"
      read -r
    fi
  fi

  if ! is_online && has_cmd nmtui; then
    print_info "正在启动 nmtui（TTY 界面）。"
    nmtui
  fi

  if ! is_online && has_cmd nmcli; then
    print_warn "仍然离线。可手动执行以下命令："
    printf "  nmcli device status\n"
    printf "  nmcli device wifi list\n"
    printf "  nmcli device wifi connect <SSID> password <密码>\n"
  fi

  if is_online; then
    print_info "网络已连接。"
    return 0
  fi

  print_warn "网络仍然离线。"
  return 1
}
