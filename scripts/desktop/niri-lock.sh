#!/usr/bin/env bash
# Compatibility wrapper. The lock implementation is now lock-session.

set -euo pipefail

case "${1:-}" in
    --generate|--generate-art)
        printf 'niri-lock.sh: generated lockscreen images are deprecated. Use lock-session instead.\n' >&2
        exit 0
        ;;
    --plain|--art|"")
        exec "${XDG_BIN_HOME:-$HOME/.local/bin}/lock-session"
        ;;
    *)
        printf 'Usage: niri-lock.sh [--plain|--art|--generate]\n' >&2
        exit 2
        ;;
esac

