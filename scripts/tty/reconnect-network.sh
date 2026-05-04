#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${SCRIPT_DIR}/../../lib/network.sh"

require_root

interactive_reconnect_network
