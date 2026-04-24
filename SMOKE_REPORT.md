# Smoke Test 报告

**执行时间**：2026-04-24（以本机 `smoke_report.log` 为准可复核）  
**执行命令**：`./run_smoke.sh`（等价于 `./run_tests.sh --smoke-only`）

## 1. 结论

**Smoke Testing：通过**

## 2. 环境

| 项目 | 值 |
|------|-----|
| Daffodil | Apache Daffodil 3.7.0 |
| Java | OpenJDK 11.0.30 |
| 可执行文件 | `apache-daffodil-3.7.0-bin/bin/daffodil` |

## 3. 执行项与结果

| 步骤 | 说明 | 结果 |
|------|------|------|
| CLI 存在且可执行 | 校验 `daffodil` 路径与权限 | 通过 |
| 版本检查 | `daffodil --version` 含预期输出 | 通过 |
| 最小解析 | `parse`：`schemas/csv_schema.xsd` + `input/valid.csv` → `output/smoke_result.xml` | 通过（文件非空，约 180 字节） |

## 4. 终端输出摘要

```
[0/8] Smoke Testing...
✅ Smoke Testing 通过。
（--smoke-only）已跳过完整回归。
```

## 5. 产出与日志

- 日志：`smoke_report.log`（与本次终端输出一致）
- 解析样例：`output/smoke_result.xml`

## 6. 说明

本次为**冒烟**范围，未执行功能/负向/往返/性能等完整回归。完整套件请运行：`./run_tests.sh`
