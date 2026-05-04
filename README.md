# kscii-linux (early bootstrap phase)

这个仓库当前目标是：先在最小化安装的 Arch Linux 上，用脚本跑通基础环境与调试流程。

当前不是完整安装器，也不是 ISO 构建流程。你现在的用途是：

- 先手工进入一个可启动的最小 Arch 系统
- 通过克隆仓库执行脚本
- 通过 SSH 远程调试迭代

## 目录说明

- `packages/`: 包列表（按功能分组）
- `lib/`: 可复用脚本函数
- `scripts/tty/`: TTY 阶段脚本（英文提示）
- `scripts/gui/`: 进入 Niri 后脚本（中文提示）

## 最小 Arch（Btrfs）调试流程

详细中文流程见：`docs/debug-flow.zh-CN.md`

快速流程：

1. 在目标设备上先保证网络可用。
2. 临时安装 git：`pacman -Sy --needed git`
3. 克隆仓库并进入目录。
4. 执行：`sudo bash scripts/tty/bootstrap.sh`
5. 安装完成后，用脚本输出的 `ssh user@ip` 从其他设备连接。
6. 进入 Niri 后执行：`bash scripts/gui/post-niri.sh`

## 说明

- `scripts/tty/bootstrap.sh` 会引导：联网检查、包安装、SSH 启用。
- 包安装按顺序执行：`network -> base -> tui -> desktop -> input -> screenshot -> editors`
- `scripts/gui/post-niri.sh` 用于图形环境阶段的中文提示与组件检查。

## 后续方向

后续正式版本会将脚本内嵌到 ISO，并演进成类似 archinstall 的交互式工具。
