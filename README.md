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

第一次 Phase 1 实机验证建议配合阅读：`docs/phase1-first-test.md`

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
- `scripts/dotctl` 用于同步当前系统配置、恢复 dotfiles，以及管理本地工具脚本。
- `scripts/tty/apply-login-power.sh` 用于部署系统级 `greetd` 登录和 logind 合盖策略。
- `scripts/tty/apply-quiet-boot.sh` 用于为 UKI/systemd-boot 配置安静启动参数。

## dotctl 同步工作流

这个仓库以当前本机系统为准：当系统配置和仓库发生分叉时，使用 `capture` 将系统版本覆盖回仓库。

```bash
# 查看受管理文件是否一致
scripts/dotctl status

# 预览：当前系统会覆盖哪些仓库文件
scripts/dotctl capture --dry-run

# 采集：用当前系统状态覆盖仓库，并把 link 类型恢复成 symlink
scripts/dotctl capture --yes

# 恢复：从仓库恢复到当前系统
scripts/dotctl restore --yes
```

新增自己的 `~/.local/bin` 工具脚本时：

```bash
scripts/dotctl track-tool --yes my-tool
```

它会复制 `~/.local/bin/my-tool` 到 `tools/bin/my-tool`，并登记到 `dotfiles.manifest`。之后 `scripts/dotctl restore --yes` 会自动恢复它。

## 后续方向

后续正式版本会将脚本内嵌到 ISO，并演进成类似 archinstall 的交互式工具。
