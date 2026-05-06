#!/usr/bin/env bash
# Apply quiet boot kernel parameters for UKI/systemd-boot setups.
#
# Usage:
#   sudo bash scripts/tty/apply-quiet-boot.sh --dry-run
#   sudo bash scripts/tty/apply-quiet-boot.sh --yes

set -euo pipefail

CMDLINE_FILE="/etc/kernel/cmdline"
DRY_RUN=0
ASSUME_YES=0
QUIET_ARGS=(quiet loglevel=3 rd.udev.log_level=3 systemd.show_status=auto)

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --help|-h)
            sed -n '1,8p' "$0"
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

if [[ "$DRY_RUN" -eq 0 && "${EUID}" -ne 0 ]]; then
    printf 'Please run as root.\n' >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -ne 1 ]]; then
    printf 'This will update %s and rebuild UKIs with mkinitcpio -P.\n' "$CMDLINE_FILE" >&2
    printf 'Re-run with --yes to apply, or --dry-run to preview.\n' >&2
    exit 1
fi

if [[ ! -r "$CMDLINE_FILE" ]]; then
    printf 'Missing %s; this script expects a UKI-style Arch setup.\n' "$CMDLINE_FILE" >&2
    exit 1
fi

current="$(<"$CMDLINE_FILE")"
updated="$current"

for arg in "${QUIET_ARGS[@]}"; do
    if [[ " $updated " != *" $arg "* ]]; then
        updated="$updated $arg"
    fi
done

printf 'Current cmdline:\n  %s\n\n' "$current"
printf 'Updated cmdline:\n  %s\n\n' "$updated"

if [[ "$updated" == "$current" ]]; then
    printf 'Quiet boot arguments are already present.\n'
else
    stamp="$(date +%Y%m%d_%H%M%S)"
    run cp -a "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.${stamp}"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '  (dry) write updated cmdline to %s\n' "$CMDLINE_FILE"
    else
        printf '%s\n' "$updated" > "$CMDLINE_FILE"
    fi
fi

run mkinitcpio -P

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'Dry run complete. Re-run as root with --yes to apply.\n'
else
    printf 'Quiet boot applied. Reboot to verify.\n'
fi
