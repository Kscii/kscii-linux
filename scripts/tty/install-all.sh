#!/usr/bin/env bash

set -euo pipefail

_INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_INSTALL_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${REPO_ROOT}/lib/network.sh"
# shellcheck source=lib/packages.sh
source "${REPO_ROOT}/lib/packages.sh"

require_root

trap 'print_error "脚本在第 ${LINENO} 行停止。"; print_info "修复上述问题后重新运行：sudo bash scripts/tty/install-all.sh"' ERR

if ! confirm_yes_no "现在开始安装软件包？（这是整个流程中唯一的确认提示）" yes; then
  print_warn "用户取消软件包安装。"
  exit 0
fi

if ! is_online; then
  print_warn "安装前检测到网络离线。"
  print_info "正在打开网络重连向导..."
  interactive_reconnect_network
fi

if ! is_online; then
  print_error "网络仍然离线，请先连接网络。"
  exit 1
fi

install_all_groups_interactive
