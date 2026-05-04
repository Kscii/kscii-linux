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

print_step "Bootstrap start"
print_info "This script helps on minimal Arch in TTY phase."

if ! is_online; then
  print_warn "Network is offline."
  if confirm_yes_no "Open reconnect helper now?" yes; then
    interactive_reconnect_network || true
  fi
fi

if ! is_online; then
  print_error "Network is still offline. Stop here."
  exit 1
fi

if ! install_all_groups_interactive; then
  print_error "Package installation flow did not finish cleanly."
  exit 1
fi

print_step "Bootstrap done"
print_info "SSH not started automatically. Start it manually when needed."
print_info "Next step after you enter Niri:"
printf "  bash %s/scripts/gui/post-niri.sh\n" "${REPO_ROOT}"
