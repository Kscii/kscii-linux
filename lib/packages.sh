#!/usr/bin/env bash

set -u

PACKAGES_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PACKAGES_LIB_DIR}/common.sh"

PACKAGES_DIR="${REPO_ROOT}/packages"
PACKAGE_ORDER=(network base tui desktop input screenshot editors)

read_package_file_to_array() {
  local file_path="$1"
  local -n out_arr=$2
  out_arr=()

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line//[$'\t\r\n ']/}"
    [[ -z "${line}" ]] && continue
    out_arr+=("${line}")
  done <"${file_path}"
}

install_group_by_name() {
  local group="$1"
  local file_path="${PACKAGES_DIR}/${group}.txt"
  local pkgs=()

  if [[ ! -f "${file_path}" ]]; then
    print_warn "Group file not found: ${file_path}"
    return 1
  fi

  read_package_file_to_array "${file_path}" pkgs
  if [[ "${#pkgs[@]}" -eq 0 ]]; then
    print_warn "No packages in group ${group}."
    return 0
  fi

  print_step "Install group: ${group}"
  print_info "Packages: ${pkgs[*]}"
  pacman -S --needed "${pkgs[@]}"
}

install_all_groups_interactive() {
  print_step "Package installation"
  print_info "This will install package groups in this order: ${PACKAGE_ORDER[*]}"

  for group in "${PACKAGE_ORDER[@]}"; do
    if ! install_group_by_name "${group}"; then
      print_error "Failed while installing group '${group}'."
      print_info "Check pacman logs: /var/log/pacman.log"
      print_info "You can retry this group with: sudo bash scripts/tty/install-all.sh"
      return 1
    fi
  done

  print_info "Package installation flow finished."
  return 0
}
