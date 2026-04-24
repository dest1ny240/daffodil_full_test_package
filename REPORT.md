# Daffodil Full Test Package 测试报告

## 1. 测试环境

- 操作系统：WSL2 (Linux)
- Java：OpenJDK 11
- Daffodil：Apache Daffodil 3.7.0
- 测试脚本：`run_tests.sh`
- 测试目录：`/home/destiny/daffodil_full_test_package`

## 2. 测试范围

- Smoke Testing（冒烟）
  - 校验 `daffodil` 可执行、`--version` 正常、对 `valid.csv` 最小解析产出非空 XML
  - 快速单独执行：`./run_smoke.sh` 或 `./run_tests.sh --smoke-only`
- Functional Test（基础解析）
  - 命令：`daffodil parse -s schemas/csv_schema.xsd input/valid.csv -o output/result.xml`
- Complex Test（复杂结构解析）
  - 命令：`daffodil parse -s schemas/complex_schema.xsd input/nested.txt -o output/nested.xml`
- Negative Test（异常输入）
  - 命令：`daffodil parse -s schemas/csv_schema.xsd input/invalid.csv`
  - 预期：解析失败
- Round Trip Test（往返一致性）
  - 流程：`valid.csv -> result.xml -> back.csv`
  - 命令：`daffodil unparse -s schemas/csv_schema.xsd output/result.xml -o output/back.csv`
- Performance Test（性能）
  - 命令：`daffodil parse -s schemas/csv_schema.xsd input/large.csv -o output/large.xml`
  - 计时工具：`/usr/bin/time`
- Cross-Platform Baseline（WSL 侧，便于与 Windows 对比）
  - 完整跑完后会生成 `output/compare_wsl/*.canon.txt`（规范化 XML，便于 `diff` / `fc`）
  - 与 Windows 对照步骤见：`COMPATIBILITY.md`

## 3. 执行方式

在测试目录执行：

```bash
./run_tests.sh 2>&1 | tee test_report.log
```

仅冒烟（秒级）：

```bash
./run_smoke.sh
```

## 4. 测试结果

- Smoke Testing：通过
- Functional Test：通过
- Complex Test：通过
- Negative Test：通过（`invalid.csv` 按预期报错）
- Round Trip Test：通过（`back.csv` 与 `valid.csv` 一致）
- Performance Test：完成并记录指标

来自 `output/performance.log` 的性能数据：

- real：`0:03.75`
- user：`8.99`
- sys：`0.92`
- maxrss_kb：`538568`

总体结论：**全部测试通过**。

## 5. 产出文件

- 测试日志：`test_report.log`
- 性能日志：`output/performance.log`
- 解析输出：`output/result.xml`、`output/nested.xml`
- 往返输出：`output/back.csv`
- 大文件解析输出：`output/large.xml`
- 冒烟产物：`output/smoke_result.xml`
- 跨平台对比基线：`output/compare_wsl/result.canon.txt`、`output/compare_wsl/nested.canon.txt`

## 6. 截图建议（提交材料）

建议至少提供以下截图：

1. `test_report.log` 中 `✅ Smoke Testing 通过` 与 `✅ 全部测试通过` 的终端输出
2. `test_report.log` 中 `✅ round trip 通过` 的终端输出
3. `output/performance.log` 中性能指标（real/user/sys/maxrss_kb）
4. （若做 Windows 对比）`COMPATIBILITY.md` 中对应步骤与 `fc`/`diff` 无差异截图
