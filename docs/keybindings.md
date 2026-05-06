# ThinkPad Engineering Edition — 快捷键参考

> **Mod** = Super（Win 键）  
> 设计原则：`Mod+字母` 用于常用应用，`Mod+Ctrl/Shift+...` 用于窗口管理，`Alt+...` 用于窗口切换。

---

## 应用启动

| 快捷键 | 功能 |
|--------|------|
| `Mod+T` | 打开终端（kitty） |
| `Mod+B` | 打开浏览器（Firefox） |
| `Mod+E` | 打开文件管理器 TUI（yazi in kitty） |
| `Mod+Shift+E` | 打开文件管理器 GUI（Thunar） |
| `Alt+Space` | 应用启动器（fuzzel，类 Spotlight 风格） |
| `Mod+O` / `Mod+Tab` | 工作区概览（相当于 GNOME Activities） |

---

## 窗口切换（Alt+Tab）

| 快捷键 | 功能 |
|--------|------|
| `Alt+Tab` | 立即切换到上一个聚焦的窗口 |
| `Alt+Tab` 连按两次（间隔 < 0.75 秒） | 打开窗口选择器列表 |
| `Alt+Shift+Tab` | 直接打开窗口选择器列表 |

---

## 窗口管理

| 快捷键 | 功能 |
|--------|------|
| `Mod+Q` | 关闭聚焦窗口 |
| `Mod+F` | 最大化列（填满宽度，保留状态栏） |
| `Mod+Shift+F` | 真正全屏（隐藏状态栏） |
| `Mod+M` | 将窗口扩展至屏幕边缘 |
| `Mod+V` | 切换浮动模式 |
| `Mod+Shift+V` | 在浮动窗口与平铺窗口间切换焦点 |
| `Mod+W` | 切换列标签页显示 |
| `Mod+C` | 居中聚焦列 |
| `Mod+Ctrl+C` | 居中所有可见列 |
| `Mod+R` | 循环切换预设列宽（1/3 → 1/2 → 2/3 → 全宽） |
| `Mod+Shift+R` | 反向循环预设列宽 |
| `Mod+Ctrl+F` | 将列扩展至可用空间 |
| `Mod+Ctrl+R` | 重置窗口高度 |
| `Mod+Ctrl+Shift+R` | 循环预设窗口高度 |
| `Mod+-` | 列宽减少 10% |
| `Mod+=` | 列宽增加 10% |
| `Mod+Shift+-` | 窗口高度减少 10% |
| `Mod+Shift+=` | 窗口高度增加 10% |

### 列堆叠（vim 风格 consume/expel）

| 快捷键 | 功能 |
|--------|------|
| `Mod+,` | 将右侧窗口收入当前列（向下堆叠） |
| `Mod+.` | 将列底部窗口弹出 |
| `Mod+[` | 向左合并或弹出窗口 |
| `Mod+]` | 向右合并或弹出窗口 |

---

## 焦点导航（vim hjkl + 方向键）

| 快捷键 | 功能 |
|--------|------|
| `Mod+H` / `Mod+←` | 聚焦左侧列 |
| `Mod+L` / `Mod+→` | 聚焦右侧列 |
| `Mod+J` / `Mod+↓` | 聚焦下方窗口（堆叠列内） |
| `Mod+K` / `Mod+↑` | 聚焦上方窗口（堆叠列内） |
| `Mod+Home` | 聚焦第一列 |
| `Mod+End` | 聚焦最后一列 |

---

## 移动窗口

| 快捷键 | 功能 |
|--------|------|
| `Mod+Ctrl+H` / `Mod+Ctrl+←` | 将列向左移动 |
| `Mod+Ctrl+L` / `Mod+Ctrl+→` | 将列向右移动 |
| `Mod+Ctrl+J` / `Mod+Ctrl+↓` | 在列内向下移动窗口 |
| `Mod+Ctrl+K` / `Mod+Ctrl+↑` | 在列内向上移动窗口 |
| `Mod+Ctrl+Home` | 将列移到最左侧 |
| `Mod+Ctrl+End` | 将列移到最右侧 |

---

## 多显示器

| 快捷键 | 功能 |
|--------|------|
| `Mod+Shift+H/L/J/K` | 聚焦显示器（左/右/下/上） |
| `Mod+Shift+方向键` | 聚焦显示器（方向） |
| `Mod+Shift+Ctrl+H/L/J/K` | 将列移到指定显示器 |
| `Mod+Shift+Ctrl+方向键` | 将列移到指定显示器（方向） |

---

## 工作区

| 快捷键 | 功能 |
|--------|------|
| `Mod+1` … `Mod+6` | 切换到工作区 1–6 |
| `Mod+Page_Up` | 切换到上方工作区 |
| `Mod+Page_Down` | 切换到下方工作区 |
| `Mod+Ctrl+1` … `Mod+Ctrl+6` | 将列移到工作区 1–6 |
| `Mod+Ctrl+Page_Up` | 将列移到上方工作区 |
| `Mod+Ctrl+Page_Down` | 将列移到下方工作区 |
| `Mod+Shift+Page_Up` | 向上重排当前工作区 |
| `Mod+Shift+Page_Down` | 向下重排当前工作区 |

### 鼠标 / 触控板

| 手势/操作 | 功能 |
|-----------|------|
| `Mod+滚轮上/下` | 切换工作区 |
| `Mod+滚轮左/右` | 左/右聚焦列 |
| `Mod+Ctrl+滚轮上/下` | 将列移到上/下工作区 |
| `Mod+Ctrl+滚轮左/右` | 将列向左/右移动 |
| 四指上滑 | 打开概览 |

---

## 截图与录屏

| 快捷键 | 功能 |
|--------|------|
| `Print` | **交互式截图** — 拖选区域，Enter 保存，Ctrl+C 复制 |
| `Shift+Print` | 截取聚焦窗口 → 保存到 `~/Pictures/Screenshots/` |
| `Ctrl+Print` | 截取全屏 → 保存 |
| `Mod+Print` | **切换** 区域录屏（首次按下时拖选区域） |
| `Mod+Shift+Print` | **切换** 全屏录制 |

录屏输出目录：`~/Videos/Recordings/`

---

## 系统

| 快捷键 | 功能 |
|--------|------|
| `Mod+Alt+L` | 锁屏 |
| `Mod+Shift+S` | 锁屏后进入睡眠 |
| `Mod+Shift+P` | 关闭所有显示器（OLED 休眠） |
| `Mod+Shift+Q` | 退出 niri |
| `Ctrl+Alt+Delete` | 强制退出 niri |
| `Mod+Escape` | 切换键盘快捷键抑制（用于远程桌面、KVM） |
| `Mod+Shift+/` | niri 内置快捷键叠加层 |

---

## 输入法

| 快捷键 | 功能 |
|--------|------|
| `Super+Space` | 切换输入法（English ↔ 中文拼音） |
| `Shift`（拼音输入时） | 将当前拼音上屏为 ASCII，切换为英文 |
| `Page_Up` / `Page_Down` | 翻页候选词 |
| `1`–`6` | 直接选择候选词 |

---

## 媒体与硬件键

| 快捷键 | 功能 |
|--------|------|
| `XF86AudioRaiseVolume` | 音量 +5%，刷新 waybar 并显示通知 |
| `XF86AudioLowerVolume` | 音量 -5%，刷新 waybar 并显示通知 |
| `XF86AudioMute` | 切换静音，刷新 waybar 并显示通知 |
| `XF86AudioMicMute` | 切换麦克风静音并显示通知 |
| `XF86AudioPlay` | 播放/暂停 |
| `XF86AudioStop` | 停止播放 |
| `XF86AudioPrev` | 上一曲 |
| `XF86AudioNext` | 下一曲 |
| `XF86MonBrightnessUp` | 背光亮度 +5% |
| `XF86MonBrightnessDown` | 背光亮度 -5% |

---

## 终端（kitty）

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+C` | 复制 |
| `Ctrl+Shift+V` | 粘贴 |
| `Ctrl+Shift+A` | 复制当前终端窗口文本到剪贴板 |
| `Ctrl+Shift+F` | 搜索当前终端窗口 scrollback |
| `Ctrl+Shift+T` | 新建标签页 |
| `Ctrl+Shift+W` | 关闭标签页 |
| `Ctrl+Shift+L` | 下一个标签页 |
| `Ctrl+Shift+H` | 上一个标签页 |
| `Ctrl+Shift+Enter` | 新建分屏窗口 |
| `Ctrl+Shift+]` / `[` | 下一个/上一个窗口 |
| `Ctrl+Shift+K` / `J` | 按行向上/向下滚动 |
| `Ctrl+Shift+U` / `D` | 按页向上/向下滚动 |
| `Ctrl+=` / `Ctrl+-` | 增大/减小字号 |
| `Ctrl+0` | 重置字号 |

---

## 设计说明

- 所有**合成器层**操作使用 `Mod`（Super 键）。
- **启动应用**：日常使用 `Mod+字母`，GUI 替代方案使用 `Mod+Shift+字母`。
- **hjkl** 导航与 Neovim 对齐——无需在不同上下文间切换心智模型。
- **Alt+Tab** 是唯一单独使用 `Alt` 的绑定，保留了从 GNOME 迁移的肌肉记忆。
- 媒体键设计上无需修饰键即可使用，无论是否锁屏均有效。
