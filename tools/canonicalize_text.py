#!/usr/bin/env python3
"""规范化文本文件（去首尾空白），便于跨平台对比 CSV 等。"""
import sys
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print("用法: canonicalize_text.py <文件>", file=sys.stderr)
        sys.exit(2)
    text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
    sys.stdout.write(text.strip())


if __name__ == "__main__":
    main()
