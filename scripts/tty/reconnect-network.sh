#!/usr/bin/env bash

set -euo pipefail

_RECONNECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_RECONNECT_DIR}/../../lib/common.sh"
# shellcheck source=lib/network.sh
source "${REPO_ROOT}/lib/network.sh"

require_root

interactive_reconnect_network
