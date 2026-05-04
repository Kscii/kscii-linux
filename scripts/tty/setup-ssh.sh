#!/usr/bin/env bash

set -euo pipefail

_SETUP_SSH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_SETUP_SSH_DIR}/../../lib/common.sh"
# shellcheck source=lib/ssh.sh
source "${REPO_ROOT}/lib/ssh.sh"

require_root

setup_ssh_interactive
