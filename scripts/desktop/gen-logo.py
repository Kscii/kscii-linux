#!/usr/bin/env python3
"""ThinkPad Engineering Edition — 发行版球形 Logo 生成器

使用朗伯漫反射光照模型渲染 3D ASCII 球体（TrackPoint 红点风格）。
输出颜色为 ThinkPad 红 (#E2000F)，可作为 fastfetch 侧边 Logo 使用。

用法:
    gen-logo                → 渲染并保存到 ~/.config/fastfetch/logos/trackpoint_rounder.txt
    gen-logo --stdout       → 输出到标准输出（带 ANSI 颜色）
    gen-logo --plain        → 输出到标准输出（不带颜色，供 imagemagick 等使用）

可调参数（直接修改脚本开头的常量，或通过函数参数传入）:
    width       球体宽度（字符数），默认 35
    height      球体高度（行数），默认 19
    y_ratio     纵横比校正（终端字符高宽比约 0.5），默认 0.86
    chars       亮度映射字符集（从暗到亮），默认 " .:-=+*#%@"
    light       光源方向向量 (x, y, z)
    base        环境光强度，默认 0.14
    diffuse     漫反射强度，默认 0.78
    center_fill 中心高光补偿，默认 0.08
"""

import argparse
import math
from pathlib import Path

# fastfetch logo 输出路径
OUT = Path.home() / ".config/fastfetch/logos/trackpoint_rounder.txt"

# ThinkPad 红 #E2000F
HEX = "#E2000F"
R, G, B = 0xE2, 0x00, 0x0F

RESET = "\033[0m"
RED   = f"\033[38;2;{R};{G};{B}m"


def normalize(x, y, z):
    """归一化三维向量。"""
    length = math.sqrt(x * x + y * y + z * z)
    return x / length, y / length, z / length


def render_sphere(
    *,
    width=31,
    height=17,
    y_ratio=0.86,
    chars=" .:-=+*#%@",
    light=(-0.42, -0.62, 0.74),
    base=0.14,
    diffuse=0.78,
    center_fill=0.08,
):
    """渲染 ASCII 球体，返回纯文本字符串（不含颜色）。

    光照模型：环境光 + 朗伯漫反射 + 中心高光补偿。
    y_ratio 用于补偿终端等宽字符的宽高比（字符通常高于宽）。
    """
    rows = []
    cx = (width - 1) / 2
    cy = (height - 1) / 2

    lx, ly, lz = normalize(*light)

    for y in range(height):
        row = []
        for x in range(width):
            # 将像素坐标归一化到球体单位圆 [-1, 1]
            nx = (x - cx) / (width * 0.5)
            ny = (y - cy) / (height * 0.5 * y_ratio)

            d2 = nx * nx + ny * ny
            if d2 > 1.0:
                row.append(" ")
                continue

            # 球面法向量的 z 分量
            z = math.sqrt(1.0 - d2)
            # 漫反射点积（与光源方向的夹角余弦）
            dot = max(0.0, nx * lx + ny * ly + z * lz)
            radius = math.sqrt(d2)

            # 合并各光照分量，钳制到 [0, 1]
            value = base + diffuse * dot + center_fill * (1.0 - radius)
            value = max(0.0, min(1.0, value))

            row.append(chars[int(value * (len(chars) - 1))])

        rows.append("".join(row).rstrip())

    while rows and not rows[0].strip():
        rows.pop(0)
    while rows and not rows[-1].strip():
        rows.pop()

    return "\n".join(rows)


def colorize(art):
    """为每行添加 ThinkPad 红 ANSI 颜色，行尾重置颜色。"""
    return "\n".join(RED + line + RESET for line in art.splitlines())


def main():
    parser = argparse.ArgumentParser(
        description="ThinkPad Engineering Edition — 球形 Logo 生成器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="输出到标准输出（带 ANSI 颜色），不保存文件",
    )
    parser.add_argument(
        "--plain",
        action="store_true",
        help="输出到标准输出（纯 ASCII，无 ANSI 颜色），供 imagemagick 等工具使用",
    )
    parser.add_argument(
        "--width",
        type=int,
        default=31,
        help="球体宽度（字符数），默认 31",
    )
    parser.add_argument(
        "--height",
        type=int,
        default=17,
        help="球体高度（行数），默认 17",
    )
    parser.add_argument(
        "--y-ratio",
        type=float,
        default=0.86,
        help="纵横比校正，数值越大越高，默认 0.86",
    )
    args = parser.parse_args()

    art = render_sphere(width=args.width, height=args.height, y_ratio=args.y_ratio)
    colored = colorize(art)

    if args.plain:
        # 纯文本输出，不含颜色
        print(art)
    elif args.stdout:
        # 带颜色输出到终端
        print(colored)
    else:
        # 保存到 fastfetch logo 文件并预览
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(colored + "\n", encoding="utf-8")
        print(f"已生成：{OUT}")
        print(f"颜色：{HEX}")
        print()
        print(colored)


if __name__ == "__main__":
    main()
