#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
# shellcheck source=lib/ssh.sh
source "${SCRIPT_DIR}/../../lib/ssh.sh"

require_root

setup_ssh_interactive
