#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${SCRIPT_DIR}/../../lib/network.sh"
# shellcheck source=lib/packages.sh
source "${SCRIPT_DIR}/../../lib/packages.sh"

require_root

if ! is_online; then
  print_warn "Network seems offline before install."
  if confirm_yes_no "Open reconnect helper now?" yes; then
    interactive_reconnect_network || true
  fi
fi

if ! is_online; then
  print_error "Still offline. Please connect network first."
  exit 1
fi

install_all_groups_interactive
