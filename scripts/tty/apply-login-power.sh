#!/usr/bin/env bash
# Deploy system-level login and lid/sleep policy.
#
# Usage:
#   sudo bash scripts/tty/apply-login-power.sh --dry-run
#   sudo bash scripts/tty/apply-login-power.sh --yes
#   sudo bash scripts/tty/apply-login-power.sh --yes --restart-logind

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRY_RUN=0
ASSUME_YES=0
RESTART_LOGIND=0

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --restart-logind) RESTART_LOGIND=1 ;;
        --help|-h)
            sed -n '1,9p' "$0"
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '  (dry)'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

require_root() {
    if [[ "$DRY_RUN" -eq 0 && "${EUID}" -ne 0 ]]; then
        printf 'Please run as root.\n' >&2
        exit 1
    fi
}

confirm() {
    if [[ "$DRY_RUN" -eq 1 || "$ASSUME_YES" -eq 1 ]]; then
        return 0
    fi
    printf 'This will write /etc/greetd/config.toml and /etc/systemd/logind.conf.d/10-kscii-power.conf.\n' >&2
    printf 'Re-run with --yes to apply, or --dry-run to preview.\n' >&2
    exit 1
}

backup_if_exists() {
    local path="$1"
    local stamp
    [[ -e "$path" ]] || return 0
    stamp="$(date +%Y%m%d_%H%M%S)"
    run cp -a "$path" "${path}.bak.${stamp}"
}

require_root
confirm

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v greetd >/dev/null 2>&1; then
    printf 'Missing greetd. Install packages: greetd greetd-tuigreet\n' >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v tuigreet >/dev/null 2>&1; then
    printf 'Missing tuigreet. Install package: greetd-tuigreet\n' >&2
    exit 1
fi

run mkdir -p /etc/greetd /etc/systemd/logind.conf.d

backup_if_exists /etc/greetd/config.toml
backup_if_exists /etc/systemd/logind.conf.d/10-kscii-power.conf

run install -m 0644 "$REPO_ROOT/system/greetd/config.toml" /etc/greetd/config.toml
run install -m 0644 "$REPO_ROOT/system/logind/10-kscii-power.conf" /etc/systemd/logind.conf.d/10-kscii-power.conf

run systemctl enable greetd.service

if [[ "$RESTART_LOGIND" -eq 1 ]]; then
    if [[ "$DRY_RUN" -eq 0 && -n "${WAYLAND_DISPLAY:-}" ]]; then
        printf 'Refusing to restart systemd-logind from an active Wayland session.\n' >&2
        printf 'Run this from a TTY, or reboot after deployment.\n' >&2
        exit 1
    fi
    run systemctl restart systemd-logind.service
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'Dry run complete. Re-run as root with --yes to deploy.\n'
else
    printf 'Login and lid policy deployed. Reboot to apply logind and test greetd on tty1.\n'
fi
