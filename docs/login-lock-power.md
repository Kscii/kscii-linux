# 登录、锁屏与睡眠策略

目标：保持 TTY/kitty 风格，使用红黑配色，同时优先保证任何复杂环境下都能回到 TTY 或 niri。

## 登录

使用 `greetd + tuigreet`：

- TTY 风格登录界面
- 默认通过 `dbus-run-session niri` 启动 `niri`
- 其他 TTY 保留为兜底入口

系统级配置模板：

- `system/greetd/config.toml`
- `system/logind/10-kscii-power.conf`

部署：

```bash
sudo bash scripts/tty/apply-login-power.sh --dry-run
sudo bash scripts/tty/apply-login-power.sh --yes
```

部署脚本会备份已有系统配置，写入 `/etc/greetd/config.toml` 和 `/etc/systemd/logind.conf.d/10-kscii-power.conf`，并启用 `greetd.service`。

脚本不会默认重启 `systemd-logind`。不要在 niri 里热重启 logind，否则当前图形会话可能丢失 `/dev/dri/card*` 权限并退出。部署后重启系统最稳。

如果登录后黑屏、niri 无法接管显示，先从 `Ctrl+Alt+F2` 登录 TTY，然后回退到纯 TTY 登录：

```bash
sudo bash scripts/tty/disable-greetd-use-getty.sh
```

之后可手动验证：

```bash
dbus-run-session niri
```

tuigreet 菜单键：

- `F1`: command menu
- `F2`: session menu
- `F3`: power menu

## 启动噪声

登录界面运行在 TTY 上，kernel/systemd/驱动日志会和登录框共享屏幕。推荐隐藏启动噪声，而不是在登录界面划分日志区域。

UKI/systemd-boot 机器可运行：

```bash
sudo bash scripts/tty/apply-quiet-boot.sh --dry-run
sudo bash scripts/tty/apply-quiet-boot.sh --yes
```

这会给 `/etc/kernel/cmdline` 增加：

```text
quiet loglevel=3 rd.udev.log_level=3 systemd.show_status=auto
```

并运行 `mkinitcpio -P` 重建 UKI。

## 锁屏

统一入口：

```bash
lock-session
```

所有触发锁屏的路径都调用这个入口：

- `Mod+Alt+L`
- 空闲锁屏
- 睡眠前锁屏
- 旧的 `niri-lock.sh` 兼容壳

锁屏器使用 `swaylock`。视觉上由 `lock-session` 在锁屏前动态生成纯黑背景图。`minimal` 主题会在左上角显示：

```text
kscii-linux locked
```

`fastfetch` 主题不会显示这行标题，只展示当前设备的 fastfetch logo 和信息。可在这里切换：

```bash
~/.config/kscii-lock/config
```

常用配置：

```bash
LOCK_THEME=fastfetch        # minimal | fastfetch
FASTFETCH_MODE=runtime      # runtime | cached
FASTFETCH_TIMEOUT=2
```

`runtime` 会在锁屏时运行 `fastfetch` 并刷新缓存；如果运行失败或超时，会退回缓存，再退回 minimal。也可以手动刷新缓存：

```bash
update-lock-fastfetch
```

fastfetch 锁屏主题会把 ASCII logo 和信息分开渲染：logo 使用 ThinkPad 红，右侧设备信息使用灰白色。缓存生成时会清理 ANSI 控制符和 logo 首尾空行，避免终端布局控制符破坏图片排版。

`swaylock` 自身的圆环 indicator 已禁用。解锁时直接输入当前用户密码并按 `Enter`，输入内容不会显示。

## 睡眠

统一入口：

```bash
suspend-session
```

行为：

1. 先运行 `lock-session`
2. 等待 `swaylock` ready
3. 执行 `systemctl suspend`

这样避免唤醒时桌面裸露。

## 空闲策略

用户可改配置：

```bash
~/.config/kscii-power/policy.conf
```

默认：

```bash
LOCK_AFTER_SECONDS=600
BATTERY_SUSPEND_AFTER_SECONDS=1200
AC_SUSPEND_AFTER_SECONDS=0
```

含义：

- 接电：10 分钟锁屏，永不自动睡眠
- 电池：10 分钟锁屏，20 分钟睡眠
- 合盖：交给 `systemd-logind`，一律 suspend

改配置后，重启 `swayidle-start.sh` 或重新登录 niri 生效。
