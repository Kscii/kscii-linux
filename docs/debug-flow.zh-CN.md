# 最小化 Arch（Btrfs）调试流程

本文用于当前“早期脚本调试阶段”。

目标：在最小化安装的 Arch 上，先跑通网络、包安装、SSH 远程调试，再进入 Niri 后做图形侧检查。

## 0. 约定

- 当前系统：最小化安装 Arch Linux
- 文件系统：Btrfs
- 当前阶段：开发调试阶段（需要从 git 克隆脚本）
- 非当前阶段：正式 ISO 内置安装器（后续再做）

## 1. clone 之前要做什么

1. 第一次联网（最小化 Arch 常用命令）。

有线网络（DHCP 常见场景）：

```bash
sudo systemctl enable --now NetworkManager
nmcli device status
```

如果有线网卡状态是 disconnected，可手动启用设备（把 `<ifname>` 换成你的网卡名，例如 `enp1s0`）：

```bash
sudo nmcli device connect <ifname>
nmcli device status
```

Wi-Fi（交互方式，推荐）：

```bash
sudo systemctl enable --now NetworkManager
sudo nmtui
```

Wi-Fi（命令方式）：

```bash
nmcli device wifi list
sudo nmcli device wifi connect "<SSID>" password "<PASSWORD>"
```

连通性测试：

```bash
ping -c 2 archlinux.org
```

2. 建议确保系统时间正常：`timedatectl status`。

3. 安装 git：

```bash
sudo pacman -Sy --needed git
```

## 2. clone 并执行脚本

```bash
git clone Kscii/kscii-linux
cd kscii-linux
sudo bash scripts/tty/bootstrap.sh
```

TTY 阶段脚本是英文提示，流程包括：

1. 检查网络并可引导重连
2. 一键安装包列表
3. 启用并启动 sshd
4. 输出其他设备连接 SSH 的命令

## 3. 常用单独脚本

- 仅重连网络：`sudo bash scripts/tty/reconnect-network.sh`
- 仅安装包：`sudo bash scripts/tty/install-all.sh`
- 仅配置 SSH：`sudo bash scripts/tty/setup-ssh.sh`

## 4. 远程调试建议

在你的开发机上，通过脚本输出的命令连接，例如：

```bash
ssh <username>@<target-ip>
```

建议：

1. 每次大改前先做一次 Btrfs 快照。
2. 小步提交，方便回滚。
3. 修改包列表后，优先用 `install-all.sh` 单独验证。

## 5. 进入 Niri 后的中文脚本

进入图形环境后执行：

```bash
bash scripts/gui/post-niri.sh
```

该脚本会：

1. 可选打开网络面板（`nm-connection-editor`）
2. 检查输入法、截图链路和常用桌面命令是否可用
3. 给出中文下一步建议

## 6. 故障排查

1. 网络重连失败：先确认 NetworkManager 是否已启动

```bash
sudo systemctl status NetworkManager
```

2. SSH 无法连接：检查 sshd

```bash
sudo systemctl status sshd
ip -4 addr
```

3. 包安装失败：可能是镜像源问题，可先手工更新镜像或重试。
