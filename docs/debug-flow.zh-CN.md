# 最小化 Arch（Btrfs）调试流程

本文用于当前“早期脚本调试阶段”。

目标：在最小化安装的 Arch 上，先跑通网络、包安装、SSH 远程调试，再进入 Niri 后做图形侧检查。

## 0. 约定

- 当前系统：最小化安装 Arch Linux
- 文件系统：Btrfs
- 当前阶段：开发调试阶段（需要从 git 克隆脚本）
- 非当前阶段：正式 ISO 内置安装器（后续再做）

**网络栈选型：NetworkManager + 默认 backend（wpa_supplicant）**

不使用 systemd-networkd，原因如下：

- 本发行版面向桌面场景，NetworkManager 提供 nmtui、nmcli、nm-connection-editor 等完整工具链，与 Niri 桌面集成更好。
- systemd-networkd 面向服务器/容器，手工管理配置文件，缺少桌面友好的交互工具。
- NetworkManager 默认 Wi-Fi backend 是 wpa_supplicant，无需额外配置；如需换成 iwd backend，后续可单独调整，初期不做。

**两阶段联网方式：**

| 阶段 | 工具 | 原因 |
|------|------|------|
| 系统首次联网（装好之前） | iwd（`iwctl`） | 最小化 Arch 默认可用，无需额外安装 |
| bootstrap 完成后 | NetworkManager（`nmtui` / `nmcli`） | 已安装，功能完整，后续 GUI 面板也依赖它 |

## 1. clone 之前要做什么

1. 第一次联网（bootstrap 执行之前）。

最小化 Arch 默认有 iwd，使用 `iwctl` 进行交互式连接：

```bash
iwctl
```

进入 iwctl 后依次执行（把 `wlan0` 换成你的无线网卡名，用 `device list` 查看）：

```
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "WiFi名字"
exit
```

有线网络不需要额外操作，插线后直接检查是否已获取 IP：

```bash
ip -4 addr
```

联通性验证：

```bash
ping -c 2 archlinux.org
```

> **注意**：这里只是临时联网。bootstrap 完成后，后续所有联网操作统一通过 NetworkManager（`nmtui` 或 `nmcli`）管理，不再使用 iwd。

2. 调整 TTY 字体大小（如果默认字体太小）。

最小化 Arch 默认 TTY 字体可能偏小，高分屏尤为明显。先临时切换查看效果：

```bash
sudo pacman -S --needed terminus-font
setfont ter-132b
```

`ter-132b` 是 Terminus 字体 32px 粗体版本，适合高分屏。常用候选：

| 字体名 | 尺寸 | 适合场景 |
|--------|------|----------|
| `ter-116b` | 16px 粗体 | 普通 1080p |
| `ter-120b` | 20px 粗体 | 1080p 高分 / 小屏 HiDPI |
| `ter-128b` | 28px 粗体 | 2K / 小屏 HiDPI |
| `ter-132b` | 32px 粗体 | 4K / 大屏 HiDPI |

`setfont` 只在当前会话生效。确认尺寸满意后，写入永久配置：

```bash
sudo mkdir -p /etc/vconsole.conf.d  # 一般不需要，直接编辑主文件即可
sudo tee /etc/vconsole.conf <<'EOF'
FONT=ter-132b
EOF
```

验证写入是否正确：

```bash
cat /etc/vconsole.conf
```

> 如果 `setfont ter-132b` 报错"找不到字体"，说明 `terminus-font` 包还未安装，先执行：
> ```bash
> sudo pacman -Sy --needed terminus-font
> ```
> 然后再重试 `setfont`。

3. 建议确保系统时间正常：`timedatectl status`。

4. 安装 git：

```bash
sudo pacman -Sy --needed git
```

## 2. clone 并执行脚本

先创建一个“脚本执行前”快照（用于重复测试回滚）：

```bash
sudo btrfs subvolume snapshot -r / /.snap-pre-bootstrap
```

执行脚本：

```bash
git clone Kscii/kscii-linux
cd kscii-linux
sudo bash scripts/tty/bootstrap.sh
```

TTY 阶段脚本是英文提示，流程包括：

1. 检查网络并可引导重连
2. 一键安装包列表

交互行为说明：

- 正常情况下只会在开头确认一次（输入一次 `y`）。
- 脚本默认自动继续执行，不会逐组反复询问。
- 只有在出现问题时才会停止，并打印清晰的错误行号与重试命令。

## 3. 常用单独脚本

- 仅重连网络：`sudo bash scripts/tty/reconnect-network.sh`
- 仅安装包：`sudo bash scripts/tty/install-all.sh`

## 4. 手动启动 SSH 并连接

bootstrap 完成后，手动启动 SSH 服务：

```bash
sudo systemctl enable --now sshd
```

查看本机 IP：

```bash
ip -4 addr
```

在开发机上连接（替换 `<username>` 和 `<ip>`）：

```bash
ssh <username>@<ip>
```

## 5. 远程调试建议

连接后即可在目标机上远程执行脚本。建议：

1. 每次大改前先做一次 Btrfs 快照。
2. 小步提交，方便回滚。
3. 修改包列表后，优先用 `install-all.sh` 单独验证。

如果要回到“脚本执行前”的状态，使用下面回滚流程（在 Live ISO 环境执行）：

```bash
sudo mount /dev/<root-partition> /mnt
sudo btrfs subvolume delete /mnt/@
sudo btrfs subvolume snapshot /mnt/.snap-pre-bootstrap /mnt/@
sudo umount /mnt
```

> 说明：`@` 是常见 Btrfs 根子卷名；如果你的根子卷名称不同，请替换为实际名称。

## 6. 进入 Niri 后的中文脚本

进入图形环境后执行：

```bash
bash scripts/gui/post-niri.sh
```

该脚本会：

1. 可选打开网络面板（`nm-connection-editor`）
2. 检查输入法、截图链路和常用桌面命令是否可用
3. 给出中文下一步建议

## 7. 故障排查

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
