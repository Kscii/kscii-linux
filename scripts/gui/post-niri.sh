#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

print_step "Niri 阶段后置检查"
print_info "该脚本用于进入图形环境后的快速检查与引导。"

if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
  print_warn "当前似乎不在图形会话中。建议进入 Niri 后再运行。"
fi

if has_cmd nm-connection-editor; then
  if confirm_yes_no "是否打开网络面板 nm-connection-editor？" yes; then
    nm-connection-editor >/dev/null 2>&1 &
    print_info "网络面板已启动。"
  fi
else
  print_warn "未找到 nm-connection-editor。"
fi

print_step "组件检查"
for cmd in fcitx5 fcitx5-configtool grim slurp wl-copy satty swappy firefox kitty; do
  if has_cmd "${cmd}"; then
    printf "[OK] %s\n" "${cmd}"
  else
    printf "[MISS] %s\n" "${cmd}"
  fi
done

print_step "下一步建议"
printf "1) 配置输入法：启动 fcitx5-configtool\n"
printf "2) 验证门户：在 Firefox 里测试文件选择器与截图\n"
printf "3) 截图链路自测：grim + slurp + satty/swappy\n"
