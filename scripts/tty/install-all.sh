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

trap 'print_error "Script stopped at line ${LINENO}."; print_info "Fix the issue above and rerun: sudo bash scripts/tty/install-all.sh"' ERR

if ! confirm_yes_no "Run package installation now? (This is the only confirmation in normal flow)" yes; then
  print_warn "Package installation cancelled by user."
  exit 0
fi

if ! is_online; then
  print_warn "Network seems offline before install."
  print_info "Opening reconnect helper now."
  interactive_reconnect_network
fi

if ! is_online; then
  print_error "Still offline. Please connect network first."
  exit 1
fi

install_all_groups_interactive
