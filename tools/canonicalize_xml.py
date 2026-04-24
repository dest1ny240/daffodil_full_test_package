#!/usr/bin/env python3
"""将 Daffodil 输出的 XML 规范为单行可比较形式，便于 WSL 与 Windows 对比。"""
import sys
import xml.etree.ElementTree as ET


def strip_ws(elem):
    if elem.text is not None and elem.text.strip() == "":
        elem.text = None
    if elem.tail is not None and elem.tail.strip() == "":
        elem.tail = None
    for child in elem:
        strip_ws(child)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else None
    if not path:
        print("用法: canonicalize_xml.py <文件.xml>", file=sys.stderr)
        sys.exit(2)
    root = ET.parse(path).getroot()
    strip_ws(root)
    sys.stdout.write(ET.tostring(root, encoding="unicode"))


if __name__ == "__main__":
    main()
