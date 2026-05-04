#!/usr/bin/env bash

set -u

_LIB_COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${_LIB_COMMON_DIR}/.." && pwd)"

print_step() {
  printf "\n==> %s\n" "$1"
}

print_info() {
  printf "[INFO] %s\n" "$1"
}

print_warn() {
  printf "[WARN] %s\n" "$1"
}

print_error() {
  printf "[ERROR] %s\n" "$1" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    print_error "Please run this script as root."
    exit 1
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

confirm_yes_no() {
  local prompt="$1"
  local default_yes="${2:-yes}"
  local answer

  if [[ "${default_yes}" == "yes" ]]; then
    read -r -p "${prompt} [Y/n]: " answer
    [[ -z "${answer}" || "${answer}" =~ ^[Yy]$ ]]
  else
    read -r -p "${prompt} [y/N]: " answer
    [[ "${answer}" =~ ^[Yy]$ ]]
  fi
}
