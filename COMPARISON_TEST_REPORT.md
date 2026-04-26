# WSL / Windows 对比测试报告

**依据文档**：[COMPATIBILITY.md](COMPATIBILITY.md)（同一套 `schemas/`、`input/`，相同 `parse` / `unparse`，经 `tools/canonicalize_*.py` 后再对比，避免 CRLF/LF 与 XML 格式噪声。）

**报告生成日期**：2026-04-24  
**Windows 对比执行**：本机 PowerShell + 仓库内 `apache-daffodil-3.7.0-bin`  
**WSL 基线**：仓库中已提交的 `output/compare_wsl/*.canon.txt`（由 WSL 侧按 COMPATIBILITY §1 生成后保留；本次未在本机重新跑 WSL。）

---

## 1. 结论

| 测试项 | 结果 |
|--------|------|
| Parse 输出跨平台（规范化 XML） | **通过** — WSL 与 Windows 的 `result.canon.txt`、`nested.canon.txt` 字节级一致（MD5 相同） |
| Windows Round trip（可选 §4） | **通过** — `valid.canon.txt` 与 `back.canon.txt` MD5 相同 |
| Invalid-schema / 负向校验（`invalid.csv`） | **通过** — 使用 `csv_schema.xsd` 解析 `input/invalid.csv` 正确失败，退出码 `20`，并有分隔符缺失报错证据日志 |
| WSL 侧 Round trip 与 Windows `back.canon.txt` 交叉对比 | **未执行** — `output/compare_wsl/` 中无 `back.canon.txt`；若需完整跨平台往返对比，请在 WSL 按 COMPATIBILITY §4 生成后再与 `output/compare_win/back.canon.txt` 比对 |

---

## 2. 环境（Windows 执行侧）

| 项目 | 值 |
|------|-----|
| 操作系统 | Windows 10（本机） |
| Daffodil | Apache Daffodil 3.7.0（`apache-daffodil-3.7.0-bin/bin/daffodil.bat`） |
| Java（本机） | Oracle JDK 21.0.1（与 COMPATIBILITY 建议的 Java 11 不一致，但本次规范化输出仍与 WSL 基线一致） |
| Python | 用于运行 `tools/canonicalize_xml.py`、`tools/canonicalize_text.py` |

---

## 3. 测试范围与输入

| 用例 | Schema | 输入 | 原始输出路径（Windows） |
|------|--------|------|-------------------------|
| CSV 解析 | `schemas/csv_schema.xsd` | `input/valid.csv` | `output/compare_win/result.xml` |
| 嵌套解析 | `schemas/complex_schema.xsd` | `input/nested.txt` | `output/compare_win/nested.xml` |

规范化命令（与文档一致，使用 `cmd` 重定向，避免 PowerShell 重定向编码差异）：

```text
python tools\canonicalize_xml.py output\compare_win\result.xml > output\compare_win\result.canon.txt
python tools\canonicalize_xml.py output\compare_win\nested.xml > output\compare_win\nested.canon.txt
```

---

## 4. Parse 跨平台对比结果

对比方式：`certutil -hashfile` 计算 MD5（等价于文档 §3 的 `fc /b` 二进制对比）。

**注意**：在 PowerShell 中请勿单独使用 `fc`，其为 `Format-Custom` 别名；应使用 `cmd /c "fc /b 路径1 路径2"` 或 `fc.exe`。

| 规范化文件 | WSL MD5 | Windows MD5 | 文件大小（双方） |
|------------|---------|---------------|------------------|
| `result.canon.txt` | `864fbebda8dbfab94c719a9262367da4` | `864fbebda8dbfab94c719a9262367da4` | 107 字节 |
| `nested.canon.txt` | `9d080204dcf39d30d9fdd20bff3082fe` | `9d080204dcf39d30d9fdd20bff3082fe` | 150 字节 |

**判定**：两对 MD5 完全一致，**Parse 跨平台对比通过**。

---

## 5. Round trip（Windows，COMPATIBILITY §4）

| 步骤 | 命令摘要 |
|------|----------|
| Unparse | `daffodil.bat unparse -s schemas\csv_schema.xsd output\compare_win\result.xml -o output\compare_win\back.csv` |
| 规范化 | `canonicalize_text.py` → `output/compare_win/back.canon.txt`、`valid.canon.txt`（源：`input/valid.csv`） |

| 文件 | MD5 |
|------|-----|
| `output/compare_win/valid.canon.txt` | `3ffb0ff7569423e5e918eefba1c26c8c` |
| `output/compare_win/back.canon.txt` | `3ffb0ff7569423e5e918eefba1c26c8c` |

**判定**：**Windows 侧 Round trip 通过**（规范化后与原始输入一致）。

---

## 5.1 Invalid-schema / 负向校验证据（Windows）

执行命令（stderr/stdout 分流保存）：

```powershell
.\apache-daffodil-3.7.0-bin\bin\daffodil.bat parse -s schemas\csv_schema.xsd input\invalid.csv 1> output\compare_win\invalid_parse.stdout.log 2> output\compare_win\invalid_parse.stderr.log
```

执行结果：

- 退出码：`20`（非 0，符合“负向用例应失败”预期）
- 关键报错（节选）：
  - `Parse Error: Failed to find infix separator`
  - `The expected delimiter(s) were: separator ','`
  - `Data location was preceding byte 5`

判定：`input/invalid.csv` 未满足 `schemas/csv_schema.xsd` 定义的逗号分隔记录结构，Daffodil 正确拒绝解析，**负向校验通过**。

---

## 6. 相关产出路径

| 路径 | 说明 |
|------|------|
| `output/compare_wsl/*.xml`、`*.canon.txt` | WSL 基线（parse + 规范化） |
| `output/compare_win/*.xml`、`*.canon.txt` | Windows parse + 规范化 |
| `output/compare_win/back.csv`、`back.canon.txt`、`valid.canon.txt` | Windows Round trip 产物 |
| `output/compare_win/invalid_parse.stderr.log`、`invalid_parse.stdout.log` | Invalid-schema 负向校验日志 |

---

## 7. 复现清单（Windows）

在仓库根目录执行（`daffodil` 已指向本包 `bin\daffodil.bat` 时可省略长路径）：

```powershell
cd d:\daffodil_full_test_package
mkdir output\compare_win -Force
.\apache-daffodil-3.7.0-bin\bin\daffodil.bat parse -s schemas\csv_schema.xsd input\valid.csv -o output\compare_win\result.xml
.\apache-daffodil-3.7.0-bin\bin\daffodil.bat parse -s schemas\complex_schema.xsd input\nested.txt -o output\compare_win\nested.xml
cmd /c "python tools\canonicalize_xml.py output\compare_win\result.xml > output\compare_win\result.canon.txt"
cmd /c "python tools\canonicalize_xml.py output\compare_win\nested.xml > output\compare_win\nested.canon.txt"
cmd /c "fc /b output\compare_wsl\result.canon.txt output\compare_win\result.canon.txt"
cmd /c "fc /b output\compare_wsl\nested.canon.txt output\compare_win\nested.canon.txt"
```

可选 Round trip：

```powershell
.\apache-daffodil-3.7.0-bin\bin\daffodil.bat unparse -s schemas\csv_schema.xsd output\compare_win\result.xml -o output\compare_win\back.csv
cmd /c "python tools\canonicalize_text.py output\compare_win\back.csv > output\compare_win\back.canon.txt"
cmd /c "python tools\canonicalize_text.py input\valid.csv > output\compare_win\valid.canon.txt"
cmd /c "fc /b output\compare_win\valid.canon.txt output\compare_win\back.canon.txt"
```

---

## 8. 建议后续

1. **版本对齐**：Windows 侧可将 JDK 调整为 11，与 COMPATIBILITY 及 WSL 侧一致，便于长期复现。  
2. **补全 WSL Round trip**：在 WSL 执行 COMPATIBILITY §4，生成 `output/compare_wsl/back.canon.txt` 后，与 Windows 的 `back.canon.txt` 做 `fc /b` 或哈希对比，完成「往返跨平台」闭环。  
3. **基线溯源**：若需审计，建议在 WSL 重跑 §1 并记录 `daffodil --version`、`java -version` 与生成时间，与本报告一并归档。
