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
    print_error "请以 root 身份运行此脚本。"
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

ensure_service_enabled_running() {
  local service_name="$1"

  if systemctl is-enabled --quiet "${service_name}" && systemctl is-active --quiet "${service_name}"; then
    print_info "服务 '${service_name}' 已启用且正在运行，跳过。"
    return 0
  fi

  if ! systemctl is-enabled --quiet "${service_name}"; then
    print_info "正在启用服务 '${service_name}'。"
    systemctl enable "${service_name}"
  fi

  if ! systemctl is-active --quiet "${service_name}"; then
    print_info "正在启动服务 '${service_name}'。"
    systemctl start "${service_name}"
  fi

  if systemctl is-enabled --quiet "${service_name}" && systemctl is-active --quiet "${service_name}"; then
    print_info "服务 '${service_name}' 已启用且正在运行。"
    return 0
  fi

  print_error "无法确保服务 '${service_name}' 正常运行。"
  return 1
}
