# 最小化 Arch（Btrfs）调试流程

本文用于当前“早期脚本调试阶段”。

目标：在最小化安装的 Arch 上，先跑通网络、包安装、SSH 远程调试，再进入 Niri 后做图形侧检查。

## 0. 约定
- 当前系统：最小化安装 Arch Linux
- 文件系统：Btrfs
- 当前阶段：开发调试阶段（需要从 git 克隆脚本）
- 非当前阶段：正式 ISO 内置安装器（后续再做）
- 网络栈选型：NetworkManager + 默认 backend（wpa_supplicant）
- 默认音频栈：PipeWire + WirePlumber + pipewire-jack（Wayland/Niri 优先）
- 默认字体：noto-fonts / noto-fonts-cjk / noto-fonts-emoji

**两阶段联网方式：**
| 阶段 | 工具 | 原因 |
|------|------|------|
| 系统首次联网（装好之前） | iwd（`iwctl`） | 最小化 Arch 默认可用，无需额外安装 |
| bootstrap 完成后 | NetworkManager（`nmtui` / `nmcli`） | 已安装，功能完整，后续 GUI 面板也依赖它 |

## 1. archinstall之前

先使用iwd连接到互联网：
```bash
iwctl
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

然后执行archinstall
> 记得在archinstall的时候就为快照单独留一个子卷 @snapshots

> **注意**：这里只是临时联网。bootstrap 完成后，后续所有联网操作统一通过 NetworkManager（`nmtui` 或 `nmcli`）管理，不再使用 iwd。

## 2. archinstall之后, gitclone之前

先使用nmtui重新连接网络
```bash
nmtui
```

先安装字体包, 然后调整 TTY 字体大小:
```bash
sudo pacman -S --needed terminus-font
setfont ter-132b
```

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

建议确保系统时间正常：`timedatectl status`

安装openssh, 并启动ssh服务
```bash
sudo pacman -S openssh
sudo systemctl enable --now sshd
```

显示ip用于连接
```bash
ip -4 addr
```

安装 git：
```bash
sudo pacman -S git
```

## 创建和挂载快照使用的子卷(如果在archinstall创建了就不需要)
btrfs的结构是在根卷(subvolid=5)下面有一系列子卷, 子卷之间也有嵌套关系
如果挂载了一个子卷, 底下有嵌套子卷, 可以在linux文件系统访问到被嵌套的子卷, 但是在保存快照的时候不会保存这个被嵌套的子卷
这个被嵌套的子卷也可以被单独挂载, 就和一个正常的子卷一样
arch默认创建的所有子卷都不是嵌套的, 包括@ @home, 都是在subvolid=5下面独立存在的, 只是被挂载到linux文件系统的不同位置

而所有创建一个新字卷的流程可以总结为:
- 先挂载subvolid=5到mnt下的某一个挂载点, 因为默认subvolid=5是没有被挂载到linux文件系统的, 所以无法操作
- 当subvolid=5被挂载到linux文件系统后, 就可以在subvolid=5下面创建一个子卷
- 创建完后就可以取消挂载subvolid=5, 并手动先把新的子卷挂载到你希望挂载的linux文件系统位置
- 最后为了不需要每次开机手动挂载, 需要修改/etc/fstab配置文件, 在其中填写每次开机的时候自动把什么子卷挂载到什么位置
- 这里的配置只需要把同一个分区的其他子卷的配置复制下来, 修改其中的子卷名字, 和挂载路径的名字就可以了
- 比如: UUID=16d49b6b-e308-4550-b116-ccf13ea44086  /.snapshots  btrfs  rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@snapshots  0 0
- 其中只需要改 /.snapshots 和 @snapshots

```bash
lsblk -f #先使用lsblk来查看btrfs的卷的名字和uuid
sudo mkdir -p /mnt/btrfs-top #创建空的挂载点
sudo mount -o subvolid=5,compress=zstd:3 /dev/nvme0n1p2 /mnt/btrfs-top #挂载根卷(subvolid=5)到挂载点
ls /mnt/btrfs-top #列出当前根卷中存在的子卷

sudo btrfs subvolume create /mnt/btrfs-top/@snapshots #在挂载点的根卷下面创建一个子卷
sudo btrfs subvolume list /mnt/btrfs-top #检查字卷是否存在

sudo mkdir -p /.snapshots #创建用于挂载字卷的挂载点

sudo nano /etc/fstab #在配置文件中添加新的子卷的自动挂载配置
UUID=16d49b6b-e308-4550-b116-ccf13ea44086  /.snapshots  btrfs  rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@snapshots  0 0 #替换其中的子卷名字, 和挂载路径

sudo systemctl daemon-reload #挂载和验证是否挂载成功
sudo mount -a
findmnt /.snapshots

sudo umount /mnt/btrfs-top #现在可以卸载根卷(其实在创字卷之后就可以卸载)


## 创建和使用快照
sudo mkdir -p /.snapshots/root /.snapshots/home #创建两个保存快照的路径, 其中root保存@的快照, home保存@home的快照

SNAP="$(date +%Y%m%d-%H%M%S)" #创建临时环境变量用于命名文件名

sudo btrfs subvolume snapshot -r / /.snapshots/root/name_$SNAP #创建当前root的快照, 可以修改其中的文件名
sudo btrfs subvolume snapshot -r /home /.snapshots/home/name_$SNAP #创建当前home的快照, 可以修改其中的文件名

diff -qr 快照1 快照2 #对比两个快照有什么区别

sudo btrfs subvolume delete /.snapshots/root/pre-bootstrap-20260504-204146 #删除一个快照, 因为也是一个子卷, 所以不能直接入门
```



## 2. clone 并执行脚本
执行脚本：
```bash
git clone https://github.com/Kscii/kscii-linux.git
cd kscii-linux
sudo bash scripts/tty/bootstrap.sh
```

TTY 阶段脚本是英文提示，流程包括：

1. 检查网络并可引导重连
2. 一键安装包列表
3. 自动 ensure 并启动服务：NetworkManager / sshd / bluetooth

常用单独脚本
- 仅重连网络：`sudo bash scripts/tty/reconnect-network.sh`
- 仅安装包：`sudo bash scripts/tty/install-all.sh`


如果要回到“脚本执行前”的状态，使用下面回滚流程（在 Live ISO 环境执行）：

```bash
sudo mount /dev/<root-partition> /mnt
sudo btrfs subvolume delete /mnt/@
sudo btrfs subvolume snapshot /mnt/.snap-pre-bootstrap /mnt/@
sudo umount /mnt
```


需要把快捷键清单放到super+shift+/ 里面, 替换niri默认的快捷键清单, 并使用中文

我需要配置在终端还有tty中的自动补全功能都可以忽略大小写, 也就是如果一个路径首字母是大写, 我输入小写, 点击tab之后也可以识别并补全出来.

如果有时间的话可以把我原本在ubuntu上的一个允许安装拼音补全的包也在发行版里面配置好

