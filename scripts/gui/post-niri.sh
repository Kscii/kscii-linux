#!/usr/bin/env bash
# ThinkPad Engineering Edition — 首次登录桌面配置脚本
# 在首次进入 niri 会话后运行一次。
# 由 scripts/tty/bootstrap.sh 末尾的提示引导执行。
#
# 完成的工作：
#   1. 部署所有点文件（符号链接到 ~/.config）
#   2. 安装桌面脚本到 ~/.local/bin
#   3. 应用 GTK 深色主题 + IBM Plex 字体
#   4. 启用用户音频服务（PipeWire）
#   5. 重建 Rime 输入法数据库
#   6. 生成 fastfetch TrackPoint 球形 Logo

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ThinkPad Engineering Edition — 桌面配置"
echo "═══════════════════════════════════════════════════════════"
echo ""

exec bash "$REPO_ROOT/scripts/desktop/setup.sh" "$@"
