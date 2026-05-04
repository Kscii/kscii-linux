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
    if confirm_yes_no "NetworkManager is not running. Enable and start it now?" yes; then
      systemctl enable --now NetworkManager
      print_info "NetworkManager is now running."
    else
      print_warn "NetworkManager is still not running."
      return 1
    fi
  fi
  return 0
}

interactive_reconnect_network() {
  print_step "Network reconnect helper"

  if is_online; then
    print_info "Network is already online."
    if ! confirm_yes_no "Do you still want to open reconnect tools?" no; then
      return 0
    fi
  fi

  ensure_networkmanager_running || true

  if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
    if has_cmd nm-connection-editor; then
      print_info "Opening network panel (nm-connection-editor)."
      nm-connection-editor >/dev/null 2>&1 &
      print_info "After reconnecting in panel, return to this terminal and press Enter."
      read -r
    fi
  fi

  if ! is_online && has_cmd nmtui; then
    print_info "Starting nmtui (TTY UI)."
    nmtui
  fi

  if ! is_online && has_cmd nmcli; then
    print_warn "Still offline. You can use these commands manually:"
    printf "  nmcli device status\n"
    printf "  nmcli device wifi list\n"
    printf "  nmcli device wifi connect <SSID> password <PASSWORD>\n"
  fi

  if is_online; then
    print_info "Network is online."
    return 0
  fi

  print_warn "Network is still offline."
  return 1
}
