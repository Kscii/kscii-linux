# ThinkPad Engineering Edition — 设计文档

## 项目定位

**ThinkPad Engineering Edition** 是一个以键盘为核心的 Wayland 桌面，专为 ThinkPad 用户设计，追求极简、无干扰的工作环境，灵感来源于 IBM 工程美学。

- 目标平台：Arch Linux + niri 合成器
- 目标用户：常驻终端的开发者，重视肌肉记忆胜过视觉效果

---

## 设计哲学

**键盘优先，鼠标可选。** 所有常用操作均有快捷键。鼠标可用，但从不必须。

**IBM/ThinkPad 工程美学。** 纯黑（`#000000`）背景，兼顾 OLED 省电与视觉清晰。ThinkPad 红（`#E2000F`）作为唯一点缀色——功能性，非装饰性。

**TUI 优先工作流。** 优先使用终端工具：neovim、yazi、btop、lazygit、fish。GUI 应用可用，但不是主要流程。

**对 GNOME 用户友好。** Alt+Tab、Super+按键、熟悉的启动器模式——从 GNOME 或 i3 迁移的用户几分钟内即可上手。

**极简依赖。** 不用 Electron，不用 Java UI，不引入重型桌面环境。所有组件均以 Rust 或 C 实现的性能工具为优先。

---

## 配色方案

| 角色     | 颜色      | 用途                                          |
|----------|-----------|-----------------------------------------------|
| 背景     | `#000000` | 所有窗口、终端、waybar、mako、swaylock        |
| 强调色   | `#E2000F` | 焦点环、边框、光标、选中区域、命令提示符      |
| 主文本   | `#e0e0e0` | 主要前景                                      |
| 非活动   | `#2a2a2a` | 未聚焦窗口的焦点环                            |
| 装饰线   | `#333333` | 分隔线、低优先级通知边框                      |

---

## 组件栈

| 层级       | 组件                         | 选用理由                                          |
|------------|------------------------------|---------------------------------------------------|
| 合成器     | niri                         | 滚动式布局，现代 Wayland，Rust 实现               |
| 终端       | kitty                        | GPU 加速、连字、Nerd Font 支持                    |
| Shell      | fish + starship              | 开箱即用、快速提示符、良好默认配置                |
| 编辑器     | neovim                       | 模态编辑、可扩展、键盘优先                        |
| 文件管理 TUI | yazi                       | Rust 实现、快速、vim 风格快捷键                   |
| 文件管理 GUI | thunar                     | 拖放操作、文件操作对话框                          |
| 启动器     | fuzzel                       | 快速、极简、兼容 dmenu                            |
| 状态栏     | waybar                       | 灵活、支持 niri 工作区                            |
| 通知       | mako                         | 轻量、支持点击聚焦                                |
| 锁屏       | swaylock                     | Wayland 原生，可靠                                |
| 空闲守护   | swayidle                     | 标准 Wayland 空闲协议                             |
| 输入法     | fcitx5 + Rime + rime-ice-git | Wayland 上最佳中文输入方案                        |
| 字体       | IBM Plex（Mono/Sans/Serif）  | IBM 血统，代码显示优秀                            |
| 图标       | Papirus-Dark                 | 简洁、兼容性广                                    |
| 壁纸       | swaybg 纯黑 `#000000`        | OLED 省电最优，零干扰                             |
| 音频       | PipeWire + WirePlumber       | 现代 Wayland 音频，低延迟                         |
| AUR 助手   | paru                         | Rust 实现，兼容 pacman 工作流                     |
| Logo       | gen-logo（Python 球形渲染）  | 统一的 TrackPoint 风格发行版 Logo                 |

---

## 键盘布局

**规则：** `Mod` = Super（Win 键）。导航键采用 vim 风格（hjkl），方向键同步镜像。

详细参考见 [docs/keybindings.md](keybindings.md)。

| 快捷键            | 功能                          |
|-------------------|-------------------------------|
| `Mod+T`           | 终端（kitty）                 |
| `Mod+B`           | 浏览器（Firefox）             |
| `Mod+E`           | 文件管理器（yazi in kitty）   |
| `Alt+Space`       | 应用启动器（fuzzel）          |
| `Alt+Tab`         | 窗口切换器（焦点历史）        |
| `Alt+Shift+Tab`   | 窗口选择器（fuzzel 列表）     |
| `Mod+Q`           | 关闭窗口                      |
| `Mod+Alt+L`       | 锁屏                          |
| `Mod+H/L/J/K`    | 焦点导航                      |
| `Mod+1–6`         | 切换工作区                    |
| `Print`           | 截图（交互式）                |
| `Mod+Print`       | 屏幕录制切换                  |

---

## 安装流程

### 第一步 — TTY 引导（以 root 执行）

```bash
sudo bash scripts/tty/bootstrap.sh
```

1. 检查网络连通性，断网时提供重连引导
2. 从 `packages/*.txt` 安装所有软件包组（pacman）
3. 启用系统服务：NetworkManager、sshd、bluetooth
4. 安装 paru AUR 助手（临时 NOPASSWD sudoers 以普通用户身份编译）
5. 安装 AUR 包：`rime-ice-git`

### 第二步 — 桌面配置（首次进入 niri 后执行）

```bash
bash scripts/gui/post-niri.sh
```

1. 将所有点文件以符号链接部署到 `~/.config`
2. 安装桌面脚本到 `~/.local/bin`
3. 通过 gsettings 应用 GTK 深色主题 + IBM Plex 字体
4. 启用用户音频服务（PipeWire、PipeWire-Pulse、WirePlumber）
5. 重建 Rime 输入法数据库
6. 将 fish 设为默认 Shell
7. 生成 fastfetch TrackPoint 球形 Logo

---

## 软件包分组

| 文件                     | 内容                                          |
|--------------------------|-----------------------------------------------|
| `packages/base.txt`      | base、linux、基础命令行工具                   |
| `packages/desktop.txt`   | niri、waybar、kitty、Wayland 组件栈           |
| `packages/editors.txt`   | neovim 及相关插件                             |
| `packages/tui.txt`       | fish、starship、yazi、btop、atool、figlet…    |
| `packages/input.txt`     | fcitx5、Rime、IBM Plex 字体、Noto CJK        |
| `packages/network.txt`   | NetworkManager、SSH、VPN                      |
| `packages/screenshot.txt`| grim、slurp、wl-clipboard、wl-screenrec       |
| `packages/aur.txt`       | rime-ice-git（通过 paru 安装）                |

---

## 点文件布局

```
dotfiles/
├── niri/config.kdl                     → ~/.config/niri/config.kdl
├── waybar/{config.jsonc,style.css}     → ~/.config/waybar/
├── kitty/kitty.conf                    → ~/.config/kitty/
├── mako/config                         → ~/.config/mako/
├── swaylock/config                     → ~/.config/swaylock/
├── fuzzel/fuzzel.ini                   → ~/.config/fuzzel/
├── starship.toml                       → ~/.config/starship.toml
├── fish/config.fish                    → ~/.config/fish/
├── fcitx5/{profile,conf/}              → ~/.config/fcitx5/
├── rime/{default,rime_ice}.custom.yaml → ~/.local/share/fcitx5/rime/
├── xdg-desktop-portal/portals.conf     → ~/.config/xdg-desktop-portal/
├── fontconfig/fonts.conf               → ~/.config/fontconfig/fonts.conf
├── gtk-4.0/gtk.css                     → ~/.config/gtk-4.0/gtk.css
├── btop/{btop.conf,themes/thinkpad.theme}
├── yazi/theme.toml                     → ~/.config/yazi/
├── fastfetch/config.jsonc              → ~/.config/fastfetch/
│   （Logo 由 gen-logo 生成，路径：~/.config/fastfetch/logos/）
├── mimeapps.list                       → ~/.config/mimeapps.list
├── applications/{nvim-kitty,archive-kitty}.desktop
│                                       → ~/.local/share/applications/
└── xdg-terminals.list                  → ~/.config/xdg-terminals.list
```

---

## 仅限运行时配置项

以下配置项依赖目标硬件信息，无法预先设置：

| 配置项                   | 如何配置                                                   |
|--------------------------|------------------------------------------------------------|
| 显示器输出名称           | 在 niri 会话内运行 `niri msg outputs`，然后编辑 `config.kdl` |
| 分辨率与缩放比例         | 同上；当前配置假设 `2880x1800 @ scale 1.5`                 |
| TrackPoint 滚动按键编号  | 假设为 `274`（中键）；用 `libinput debug-events` 验证      |
| waybar 温度传感器路径    | 在 `waybar/config.jsonc` 中设置 `hwmon-path-abs`           |
| 锁屏图片分辨率           | 编辑 `scripts/desktop/niri-lock.sh` 中的 `DISPLAY_SIZE`   |
| Rime 词库同步路径        | 如需云同步，在 `rime_ice.custom.yaml` 中配置               |

---

## Phase 1 定义（已完成）

Phase 1 为**个人可用的日常驱动状态**，以下所有条目需全部完成：

- [x] niri 合成器：快捷键、工作区、浮动规则、窗口管理
- [x] waybar：工作区、时钟、CPU、内存、电池、输入法指示器
- [x] kitty：IBM Plex Mono 主字体 + Nerd Font 符号回退
- [x] mako：通知支持点击聚焦
- [x] fcitx5 + Rime + rime-ice 中文输入（Shift_L 提交拼音为 ASCII）
- [x] swaylock：多风格 ASCII 艺术锁屏
- [x] swayidle：10 分钟锁屏 / 40 分钟关显 / 合盖锁屏
- [x] fish + starship Shell 提示符
- [x] fuzzel 应用启动器
- [x] Alt+Tab 窗口切换器（焦点历史守护 + 0.75 秒双击检测）
- [x] 截图（grim/slurp）+ 屏幕录制（wl-screenrec）
- [x] 默认应用关联（mimeapps.list）
- [x] 字体优先级（fontconfig：IBM Plex → Noto CJK 回退）
- [x] GTK4 深色背景覆盖（gtk.css，提供两个可切换方案）
- [x] btop ThinkPad 颜色主题
- [x] yazi ThinkPad 颜色主题
- [x] fastfetch + TrackPoint 球形 Logo（gen-logo 生成）
- [x] PipeWire 音频服务启用

---

## Phase 2 目标（待实现）

- 通过 archiso 生成 ISO 镜像
- Calamares 图形化安装程序（预置配置）
- 自动硬件检测（输出名称、HiDPI 缩放比例）
- 硬件专属配置：X1 Carbon、T14、T480 等
- 版本管理、变更日志、一键安装脚本
- 公开 GitHub 仓库发布
