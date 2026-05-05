# Phase 1 首次测试操作文档

本文用于当前仓库的第一次实机验证，目标不是一次性证明“日驱完成”，而是确认：

1. `bootstrap.sh` 能把系统带到可进入 `niri` 的状态
2. `post-niri.sh` 能部署 dotfiles 和桌面脚本
3. 关键工作流在实机上可逐项验证并记录问题

---

## 一、推荐的仓库结构理解

当前结构是合理的，建议继续保持：

- `dotfiles/`：保存“目标状态”
  这里放最终希望落到 `~/.config` 和 `~/.local/share` 的内容，例如 `niri`、`waybar`、`kitty`、`mako`、`mimeapps.list`。
- `scripts/`：保存“编排动作”
  这里放部署、生成、辅助和运行时脚本，例如 `bootstrap.sh`、`setup.sh`、`niri-alt-tab.sh`、`niri-lock.sh`。
- `lib/`：保存可复用 shell 函数
  这里放网络、包管理、通用输出等基础能力。
- `docs/`：保存设计、调试和测试文档

这比“把所有 shell 脚本都塞进 dotfiles”更清晰。

推荐判断标准：

- 会被直接链接到用户目录的，放 `dotfiles/`
- 需要执行、生成、探测、编排的，放 `scripts/`
- 被多个脚本复用的，放 `lib/`

---

## 二、Alt+Tab 方案选择

### 方案 A：保留当前自定义 Alt+Tab

当前行为：

- `Alt+Tab`：切回最近聚焦窗口
- `Alt+Tab` 在 0.75 秒内连按两次：打开窗口选择器
- `Alt+Shift+Tab`：直接打开窗口选择器

优点：

- 更接近 GNOME 迁移用户的预期
- 可以按最近使用历史切换，而不只是按布局顺序切换
- 可以直接挑窗口，而不只是沿布局方向滚动

代价：

- 依赖 `jq`
- 多了焦点历史守护脚本，复杂度更高

### 方案 B：改用 niri 原生行为

原生 niri 的思路更像“在当前工作区滚动焦点/列”，配合布局动画会非常顺。

优点：

- 不需要 `jq` 和焦点历史守护进程
- 更符合 niri 自身的交互模型
- 维护成本更低

代价：

- 不等于传统意义上的“任务切换器”
- 只是在当前工作区内按布局顺序切，不是按最近使用顺序切

### 推荐

我建议：

1. Phase 1 默认保留当前自定义方案
2. 在文档中明确它是“GNOME 迁移友好模式”
3. 后面再追加一个“原生 niri 模式”可选配置

原因很简单：你这个发行版当前的目标之一，就是降低从 GNOME 迁移到 `niri` 的心理门槛。

如果你要临时切回原生行为，可把 [dotfiles/niri/config.kdl](/home/kscii/Codes/kscii-linux/dotfiles/niri/config.kdl:221) 一段改成：

```kdl
Alt+Tab repeat=false { focus-column-right; }
Alt+Shift+Tab repeat=false { focus-column-left; }
```

更进一步，也可以换成 `focus-window-down/up`，取决于你更想在“列之间”还是“列内堆叠窗口”切。

---

## 三、锁屏是否一定要图片

不一定。

当前最稳、最省事、也最省电的方案其实就是纯黑锁屏加解锁环，也就是现在 [dotfiles/swaylock/config](/home/kscii/Codes/kscii-linux/dotfiles/swaylock/config:1) 的默认行为。

如果你想加入发行版标识，推荐方案是：

1. 用 `gen-logo.py --plain` 生成纯 ASCII
2. 再用 `imagemagick` 渲染成黑底 PNG
3. 交给 `swaylock --image` 使用

原因：

- `swaylock` 本身不会直接渲染任意 ASCII art 布局
- 它擅长显示纯色背景、截图背景或图片背景
- 所以“ASCII 风格锁屏”在实现上仍然通常要落成图片

关于省电：

- 纯黑锁屏最省电
- 黑底加少量红色 ASCII 图案也很省电
- 但它不会比纯黑更省电

所以推荐顺序是：

1. 默认用纯黑锁屏
2. 把 ASCII 图片锁屏作为可选品牌化增强

---

## 四、第一次测试前的准备

在最小 Arch 系统里：

```bash
git clone https://github.com/Kscii/kscii-linux.git
cd kscii-linux
sudo bash scripts/tty/bootstrap.sh
```

安装完成后：

1. 确认 `NetworkManager`、`sshd`、`bluetooth` 已启用
2. 登录到 `niri`
3. 进入图形会话后执行：

```bash
bash scripts/gui/post-niri.sh
```

---

## 五、进入 niri 后的必做校准

### 1. 校准显示输出名

如果 `post-niri.sh` 是在 `niri` 会话内执行的，脚本会自动运行 `niri msg outputs` 并把结果写入 `~/.config/niri/config.kdl` 的托管输出区块，同时记录到 `~/.config/niri/detected-output.txt`。

如需手动核对，再运行：

```bash
niri msg outputs
```

按结果检查 [dotfiles/niri/config.kdl](/home/kscii/Codes/kscii-linux/dotfiles/niri/config.kdl:70) 中的输出段是否正确。

### 2. 校准分辨率和缩放

通常会随自动探测一起写入；如果手感不对，再在同一个输出段里调整：

- `mode`
- `scale`

### 3. 校准 TrackPoint 中键编号

```bash
libinput debug-events
```

按一下中键，确认 `scroll-button` 是否仍然应为 `274`。

### 4. 校准 waybar 温度路径

先找可用 `hwmon`：

```bash
find /sys/class/hwmon -maxdepth 2 -type f -name temp1_input
```

再修改 [dotfiles/waybar/config.jsonc](/home/kscii/Codes/kscii-linux/dotfiles/waybar/config.jsonc:75) 的 `hwmon-path-abs`。

### 5. 生成可选锁屏图

先保持默认纯黑锁屏即可。

如果要启用 ASCII 锁屏图：

```bash
niri-lock.sh --generate
```

生成后可继续保持脚本自动选图，无需强制把 `image=` 写死进 `swaylock` 配置。

---

## 六、第一次测试的验证顺序

建议按下面顺序测，便于定位问题：

### 1. 基础会话

- `waybar` 是否自动启动
- `swaybg` 是否为纯黑背景
- `fcitx5` 是否自动启动
- `mako` 是否自动启动
- `swayidle` 是否已在后台

### 2. 基础应用

- `Mod+T` 打开 `kitty`
- `Mod+B` 打开 `firefox`
- `Mod+E` 打开 `yazi`
- `Mod+Shift+E` 打开 `thunar`
- `Alt+Space` 打开 `fuzzel`

### 3. 输入法

- `Super+Space` 切换中英文
- waybar 输入法指示器是否正确更新
- Rime 候选和 `Shift_L` 行为是否符合预期

### 4. 窗口管理

- `Mod+H/J/K/L` 焦点移动
- `Mod+1..6` 工作区切换
- `Mod+V` 浮动开关
- `Alt+Tab` 是否符合预期

### 5. 系统能力

- `Print` 截图
- `Mod+Print` 区域录屏
- `Mod+Shift+Print` 全屏录屏
- `Mod+Alt+L` 锁屏
- 音量键、亮度键

### 6. 视觉一致性

- `kitty` 字体是否正常
- Nerd Font 图标是否正常
- `mako` 是否为黑底红框
- `fuzzel` 是否为黑底红边
- GTK 应用是否应用了深色主题

---

## 七、推荐的第一次测试结论模板

建议你每次测试后按这个格式记录：

```text
设备：
分辨率 / 缩放：

通过：
- bootstrap 完成
- niri 可启动
- post-niri 可执行

失败：
- waybar 温度模块路径不对
- Alt+Tab 行为需要再调

待调整：
- TrackPoint 中键编号
- 锁屏图分辨率
```

---

## 八、当前建议的 Phase 1 收尾项

第一次测试前，建议至少确认下面这些包已在清单中：

- `python`
- `jq`
- `wf-recorder`
- `thunar`
- `thunar-archive-plugin`
- `bluetui`
- `libnotify`
- `imagemagick`
- `adw-gtk-theme`
- `ttf-jetbrains-mono-nerd`

这些已经是当前仓库里实际被脚本、配置或设计文档使用到的依赖。
