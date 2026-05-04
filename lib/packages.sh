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
    print_warn "软件包组文件不存在：${file_path}"
    return 1
  fi

  read_package_file_to_array "${file_path}" pkgs
  if [[ "${#pkgs[@]}" -eq 0 ]]; then
    print_warn "软件包组 ${group} 中没有软件包。"
    return 0
  fi

  print_step "安装软件包组：${group}"
  print_info "软件包：${pkgs[*]}"
  pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_all_groups_interactive() {
  print_step "软件包安装"
  print_info "将按以下顺序安装各软件包组：${PACKAGE_ORDER[*]}"

  for group in "${PACKAGE_ORDER[@]}"; do
    if ! install_group_by_name "${group}"; then
      print_error "安装软件包组 '${group}' 时失败。"
      print_info "查看 pacman 日志：/var/log/pacman.log"
      print_info "可通过以下命令重试该组：sudo bash scripts/tty/install-all.sh"
      return 1
    fi
  done

  print_info "软件包安装流程完成。"
  return 0
}
