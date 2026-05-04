# ThinkPad Engineering Edition — Fish shell 配置
# 极简风格：环境变量设置 + 工具集成，不设别名。

# ── 环境变量 ──────────────────────────────────────────────────────────────
# （与 niri 环境变量保持一致，供 TTY 会话和 SSH 使用）
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx MANPAGER "less -R --use-color -Dd+r -Du+b"
set -gx LESS "-R --use-color"

# XDG 基础目录
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME   "$HOME/.local/share"
set -gx XDG_CACHE_HOME  "$HOME/.cache"
set -gx XDG_STATE_HOME  "$HOME/.local/state"

# 输入法（用于非 niri 会话，如 TTY → SSH）
set -gx XMODIFIERS     "@im=fcitx"
set -gx QT_IM_MODULE   "fcitx"
set -gx GTK_IM_MODULE  "fcitx"
set -gx SDL_IM_MODULE  "fcitx"

# 本地二进制路径
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.go/bin"

# ── 工具集成 ──────────────────────────────────────────────────────────────

# Starship 提示符
if command -q starship
    starship init fish | source
end

# zoxide（智能 cd）
if command -q zoxide
    zoxide init fish | source
end

# fzf 键绑定与补全
if command -q fzf
    fzf --fish | source
    # 使用 fd 替代 find 作为 fzf 的文件搜索后端
    if command -q fd
        set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
        set -gx FZF_CTRL_T_COMMAND  "$FZF_DEFAULT_COMMAND"
        set -gx FZF_ALT_C_COMMAND   "fd --type d --hidden --follow --exclude .git"
    end
    # fzf 界面使用 ThinkPad 红配色
    set -gx FZF_DEFAULT_OPTS "\
        --color=bg:#000000,bg+:#111111,fg:#cccccc,fg+:#ffffff \
        --color=hl:#E2000F,hl+:#E2000F,info:#666666,prompt:#E2000F \
        --color=pointer:#E2000F,marker:#E2000F,spinner:#E2000F,header:#888888 \
        --color=border:#333333 \
        --border=sharp \
        --prompt='❯ ' --pointer='▶' --marker='✓'"
end

# ── 欢迎语 ────────────────────────────────────────────────────────────────
# 禁用默认的 fish 欢迎信息
set fish_greeting ""
