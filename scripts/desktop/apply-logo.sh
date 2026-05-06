#!/usr/bin/env bash
# Generate the fastfetch logo and refresh every derived cache that uses it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GEN_LOGO="${REPO_ROOT}/scripts/desktop/gen-logo.py"
UPDATE_LOCK_FASTFETCH="${REPO_ROOT}/scripts/desktop/update-lock-fastfetch.sh"

if ! command -v python3 >/dev/null 2>&1; then
    printf 'apply-logo: python3 is required.\n' >&2
    exit 1
fi

if [[ ! -r "$GEN_LOGO" ]]; then
    printf 'apply-logo: missing generator: %s\n' "$GEN_LOGO" >&2
    exit 1
fi

python3 "$GEN_LOGO" "$@"

if [[ -x "$UPDATE_LOCK_FASTFETCH" ]]; then
    "$UPDATE_LOCK_FASTFETCH"
elif command -v update-lock-fastfetch >/dev/null 2>&1; then
    update-lock-fastfetch
else
    printf 'apply-logo: skipped lock cache refresh; update-lock-fastfetch not found.\n' >&2
fi

printf 'Logo applied to fastfetch and lock-screen cache.\n'
