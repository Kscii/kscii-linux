#!/usr/bin/env bash
# Emergency fallback: disable greetd and restore a plain TTY login on tty1.
#
# Usage:
#   sudo bash scripts/tty/disable-greetd-use-getty.sh

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    printf 'Please run as root.\n' >&2
    exit 1
fi

systemctl disable --now greetd.service
systemctl enable --now getty@tty1.service

printf 'greetd disabled. tty1 now uses getty. Log in on a TTY and run: dbus-run-session niri\n'
