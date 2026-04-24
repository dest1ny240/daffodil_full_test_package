# WSL 与 Windows 对比测试说明

两边使用**同一套** `schemas/`、`input/`，执行**相同**的 `daffodil parse` / `unparse` 命令，再用本仓库里的规范化脚本对比输出，可避免换行符（CRLF vs LF）和 XML 声明/缩进带来的假差异。

## 1. 在 WSL 上生成可对比基线

在仓库根目录执行：

```bash
cd ~/daffodil_full_test_package
mkdir -p output/compare_wsl
./apache-daffodil-3.7.0-bin/bin/daffodil parse -s schemas/csv_schema.xsd input/valid.csv -o output/compare_wsl/result.xml
./apache-daffodil-3.7.0-bin/bin/daffodil parse -s schemas/complex_schema.xsd input/nested.txt -o output/compare_wsl/nested.xml
python3 tools/canonicalize_xml.py output/compare_wsl/result.xml > output/compare_wsl/result.canon.txt
python3 tools/canonicalize_xml.py output/compare_wsl/nested.xml > output/compare_wsl/nested.canon.txt
```

把 `output/compare_wsl/*.canon.txt` 保留好，或复制到 U 盘/网盘，作为「WSL 侧」基线。

## 2. 在 Windows 上安装并运行

1. 安装 **Java 11**（与 WSL 侧尽量一致）。
2. 安装 Daffodil：使用与本包一致的 **3.7.0** 发行包（例如 MSI，或解压与 WSL 相同的 `apache-daffodil-3.7.0-bin`）。
3. 将整个 `daffodil_full_test_package` 复制到 Windows 磁盘（例如 `C:\work\daffodil_full_test_package`），保证 `schemas`、`input` 路径一致。

在 **PowerShell** 中（按你的实际安装路径调整 `daffodil`）：

```powershell
cd C:\work\daffodil_full_test_package
mkdir output\compare_win -Force
daffodil parse -s schemas\csv_schema.xsd input\valid.csv -o output\compare_win\result.xml
daffodil parse -s schemas\complex_schema.xsd input\nested.txt -o output\compare_win\nested.xml
python tools\canonicalize_xml.py output\compare_win\result.xml > output\compare_win\result.canon.txt
python tools\canonicalize_xml.py output\compare_win\nested.xml > output\compare_win\nested.canon.txt
```

若 `daffodil` 不在 PATH，请写完整路径，例如：

`C:\path\to\apache-daffodil-3.7.0-bin\bin\daffodil.bat`

## 3. 对比结果

### 方式 A：在 Windows 上对比

把 WSL 生成的 `result.canon.txt`、`nested.canon.txt` 拷到 `output\compare_wsl\`，然后：

```powershell
fc /b output\compare_wsl\result.canon.txt output\compare_win\result.canon.txt
fc /b output\compare_wsl\nested.canon.txt output\compare_win\nested.canon.txt
```

无差异则 `fc` 会提示文件相同。

### 方式 B：在 WSL 上对比

把 Windows 下 `output\compare_win\*.canon.txt` 拷回 WSL 的例如 `output/compare_win/`，然后：

```bash
diff output/compare_wsl/result.canon.txt output/compare_win/result.canon.txt
diff output/compare_wsl/nested.canon.txt output/compare_win/nested.canon.txt
```

## 4. Round trip 跨平台对比（可选）

WSL：

```bash
./apache-daffodil-3.7.0-bin/bin/daffodil unparse -s schemas/csv_schema.xsd output/compare_wsl/result.xml -o output/compare_wsl/back.csv
python3 tools/canonicalize_text.py output/compare_wsl/back.csv > output/compare_wsl/back.canon.txt
python3 tools/canonicalize_text.py input/valid.csv > output/compare_wsl/valid.canon.txt
diff output/compare_wsl/valid.canon.txt output/compare_wsl/back.canon.txt
```

Windows 上对 `result.xml` 做同样 `unparse` 后，用 `canonicalize_text.py` 生成 `back.canon.txt`，再与 WSL 的 `back.canon.txt` 或 `valid.canon.txt` 做二进制/`fc` 对比即可。

## 5. 注意事项

- **版本一致**：两边都应是 Daffodil **3.7.0**，否则 XML 细节可能不同。
- **编码**：输入/输出按 UTF-8 处理；若 Windows 终端乱码，可仍直接对比 `.canon.txt` 文件内容。
- **路径**：Windows 用反斜杠或正斜杠均可；`daffodil` 参数里的 schema 与 input 路径需指向同一逻辑文件。
