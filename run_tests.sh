#!/usr/bin/env bash
set -euo pipefail

SMOKE_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --smoke-only) SMOKE_ONLY=true ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAFFODIL_BIN="$ROOT_DIR/apache-daffodil-3.7.0-bin/bin/daffodil"
OUT_DIR="$ROOT_DIR/output"

mkdir -p "$OUT_DIR"

echo "[0/8] Smoke Testing..."
if [[ ! -x "$DAFFODIL_BIN" ]]; then
  echo "❌ Smoke 失败：找不到或未设置可执行权限: $DAFFODIL_BIN"
  exit 1
fi
if ! "$DAFFODIL_BIN" --version | head -n 1 | grep -q "Daffodil"; then
  echo "❌ Smoke 失败：daffodil --version 无预期输出。"
  exit 1
fi
"$DAFFODIL_BIN" parse -s "$ROOT_DIR/schemas/csv_schema.xsd" "$ROOT_DIR/input/valid.csv" -o "$OUT_DIR/smoke_result.xml"
if [[ ! -s "$OUT_DIR/smoke_result.xml" ]]; then
  echo "❌ Smoke 失败：smoke_result.xml 为空。"
  exit 1
fi
echo "✅ Smoke Testing 通过。"

if [[ "$SMOKE_ONLY" == true ]]; then
  echo "（--smoke-only）已跳过完整回归。"
  exit 0
fi

normalize_xml() {
  python3 - "$1" <<'PY'
import sys
import xml.etree.ElementTree as ET

def strip_ws(elem):
    if elem.text is not None and elem.text.strip() == "":
        elem.text = None
    if elem.tail is not None and elem.tail.strip() == "":
        elem.tail = None
    for child in elem:
        strip_ws(child)

path = sys.argv[1]
root = ET.parse(path).getroot()
strip_ws(root)
print(ET.tostring(root, encoding="unicode"))
PY
}

normalize_text() {
  python3 - "$1" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
print(text.strip())
PY
}

echo "[1/8] 运行 CSV 功能测试..."
"$DAFFODIL_BIN" parse -s "$ROOT_DIR/schemas/csv_schema.xsd" "$ROOT_DIR/input/valid.csv" -o "$OUT_DIR/result.xml"

echo "[2/8] 运行复杂结构测试..."
"$DAFFODIL_BIN" parse -s "$ROOT_DIR/schemas/complex_schema.xsd" "$ROOT_DIR/input/nested.txt" -o "$OUT_DIR/nested.xml"

echo "[3/8] 验证负向用例（应失败）..."
if "$DAFFODIL_BIN" parse -s "$ROOT_DIR/schemas/csv_schema.xsd" "$ROOT_DIR/input/invalid.csv" >/dev/null 2>&1; then
  echo "❌ 负向测试失败：invalid.csv 本应报错但解析成功。"
  exit 1
fi
echo "✅ 负向测试通过（正确报错）。"

echo "[4/8] 比对 valid.xml（规范化后）..."
if [[ "$(normalize_xml "$ROOT_DIR/expected/valid.xml")" != "$(normalize_xml "$OUT_DIR/result.xml")" ]]; then
  echo "❌ valid.xml 对比失败。"
  exit 1
fi

echo "[5/8] 比对 nested.xml（规范化后）..."
if [[ "$(normalize_xml "$ROOT_DIR/expected/nested.xml")" != "$(normalize_xml "$OUT_DIR/nested.xml")" ]]; then
  echo "❌ nested.xml 对比失败。"
  exit 1
fi

echo "[6/8] 运行 round trip（parse -> unparse）..."
"$DAFFODIL_BIN" unparse -s "$ROOT_DIR/schemas/csv_schema.xsd" "$OUT_DIR/result.xml" -o "$OUT_DIR/back.csv"
if [[ "$(normalize_text "$ROOT_DIR/input/valid.csv")" != "$(normalize_text "$OUT_DIR/back.csv")" ]]; then
  echo "❌ round trip 失败：back.csv 与 valid.csv 不一致。"
  exit 1
fi
echo "✅ round trip 通过。"

echo "[7/8] 运行 performance（large.csv）..."
/usr/bin/time -f "real=%E user=%U sys=%S maxrss_kb=%M" \
  "$DAFFODIL_BIN" parse -s "$ROOT_DIR/schemas/csv_schema.xsd" "$ROOT_DIR/input/large.csv" -o "$OUT_DIR/large.xml" \
  2> "$OUT_DIR/performance.log"
echo "✅ performance 完成，详情见 $OUT_DIR/performance.log"

echo "[8/8] 生成跨平台对比用规范化输出（WSL 侧基线）..."
mkdir -p "$OUT_DIR/compare_wsl"
cp -f "$OUT_DIR/result.xml" "$OUT_DIR/compare_wsl/result.xml"
cp -f "$OUT_DIR/nested.xml" "$OUT_DIR/compare_wsl/nested.xml"
python3 "$ROOT_DIR/tools/canonicalize_xml.py" "$OUT_DIR/compare_wsl/result.xml" > "$OUT_DIR/compare_wsl/result.canon.txt"
python3 "$ROOT_DIR/tools/canonicalize_xml.py" "$OUT_DIR/compare_wsl/nested.xml" > "$OUT_DIR/compare_wsl/nested.canon.txt"
echo "✅ 已写入 $OUT_DIR/compare_wsl/*.canon.txt（可与 Windows 侧对比，见 COMPATIBILITY.md）。"

echo "✅ 全部测试通过。"
