#!/usr/bin/env bash

set -euo pipefail

_BOOTSTRAP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_BOOTSTRAP_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${REPO_ROOT}/lib/network.sh"
# shellcheck source=lib/packages.sh
source "${REPO_ROOT}/lib/packages.sh"

require_root

trap 'print_error "Script stopped at line ${LINENO}."; print_info "Fix the issue above and rerun: sudo bash scripts/tty/bootstrap.sh"' ERR

print_step "Bootstrap start"
print_info "This script helps on minimal Arch in TTY phase."

if ! confirm_yes_no "Run bootstrap now? (This is the only confirmation in normal flow)" yes; then
  print_warn "Bootstrap cancelled by user."
  exit 0
fi

if ! is_online; then
  print_warn "Network is offline."
  print_info "Opening reconnect helper now."
  interactive_reconnect_network
fi

if ! is_online; then
  print_error "Network is still offline. Stop here."
  exit 1
fi

if ! install_all_groups_interactive; then
  print_error "Package installation flow failed."
  exit 1
fi

print_step "Ensure system services"
ensure_service_enabled_running NetworkManager
ensure_service_enabled_running sshd
ensure_service_enabled_running bluetooth

print_step "Bootstrap done"
print_info "Core services ensured: NetworkManager, sshd, bluetooth."
print_info "Next step after you enter Niri:"
printf "  bash %s/scripts/gui/post-niri.sh\n" "${REPO_ROOT}"
