#!/usr/bin/env bash

set -u

SSH_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SSH_LIB_DIR}/common.sh"

ensure_openssh_installed() {
  if pacman -Q openssh >/dev/null 2>&1; then
    return 0
  fi
  print_warn "openssh is not installed. Installing now..."
  pacman -S --needed openssh
}

enable_and_start_sshd() {
  systemctl enable --now sshd
}

get_primary_ipv4() {
  local ip
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  printf "%s" "${ip}"
}

print_ssh_hints() {
  local user_name ip
  user_name="${SUDO_USER:-$(logname 2>/dev/null || echo user)}"
  ip="$(get_primary_ipv4)"

  print_step "SSH quick command"
  if [[ -n "${ip}" ]]; then
    printf "From another device:\n"
    printf "  ssh %s@%s\n" "${user_name}" "${ip}"
  else
    print_warn "Could not detect local IP automatically."
    print_info "Check IP with: ip -4 addr"
    printf "Then use: ssh <username>@<ip>\n"
  fi
}

setup_ssh_interactive() {
  print_step "SSH setup"

  if ! confirm_yes_no "Enable and start SSH service (sshd)?" yes; then
    print_warn "SSH setup skipped."
    return 1
  fi

  ensure_openssh_installed
  enable_and_start_sshd
  print_info "sshd is enabled and running."
  print_ssh_hints
  return 0
}
